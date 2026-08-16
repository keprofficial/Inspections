import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../constants/severity.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/submit_validation.dart';
import '../services/supabase_repository.dart';
import '../services/sync_status.dart';
import '../services/unsaved_work_guard.dart';
import '../widgets/app_card.dart';
import '../widgets/app_common.dart';
import '../widgets/app_sliver_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import '../widgets/severity_pill.dart';
import 'app_shell.dart';
import 'area_manager_sheet.dart';
import 'checklist_item_screen.dart';
import 'start_inspection_flow.dart';
import 'submit_result_screen.dart';

enum _AreaFilter { all, pending, critical, done }

/// Tab 2 — the active inspection.
///
/// Areas expand in place instead of pushing a separate screen, so the common
/// case (open an area, tick a few checks, move on) no longer costs two
/// navigations per area.
class InspectScreen extends StatefulWidget {
  const InspectScreen({Key? key}) : super(key: key);

  @override
  State<InspectScreen> createState() => _InspectScreenState();
}

class _InspectScreenState extends State<InspectScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<InspectionArea> _areas = <InspectionArea>[];
  List<InspectionAreaTemplate> _templates = const [];
  final Set<String> _expandedAreaIds = <String>{};

  _AreaFilter _filter = _AreaFilter.all;
  bool _isLoading = true;
  bool _didRestoreActiveArea = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadChecklistAndDraft();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- derived

  int get _completedItems => _areas.fold(
        0,
        (sum, area) => sum + area.items.where((item) => item.completed).length,
      );

  int get _totalItems => _areas.fold(0, (sum, area) => sum + area.items.length);

  int get _pendingItems => _totalItems - _completedItems;

  int get _overallProgress =>
      _totalItems == 0 ? 0 : ((_completedItems / _totalItems) * 100).round();

  Iterable<InspectionItem> get _criticalItems sync* {
    for (final area in _areas) {
      for (final item in area.items) {
        if (item.completed &&
            Severity.fromValue(item.severity) == Severity.critical) {
          yield item;
        }
      }
    }
  }

  double get _criticalEstimateTotal => _criticalItems.fold<double>(
        0,
        (sum, item) => sum + (item.estimatedCost ?? 0),
      );

  List<SubmitBlocker> get _blockers => SubmitValidator.validate(
        areas: _areas,
        isAdhoc: InspectionSession.isAdhocInspection,
      );

  /// Only a *recorded* critical finding counts. Checklist templates seed a
  /// default severity on every item, so matching on severity alone flagged
  /// areas as critical before the inspector had looked at them.
  bool _areaHasCritical(InspectionArea area) => area.items.any(
        (item) =>
            item.completed &&
            Severity.fromValue(item.severity) == Severity.critical,
      );

  int _areaCompleted(InspectionArea area) =>
      area.items.where((item) => item.completed).length;

  List<InspectionArea> get _visibleAreas {
    final query = _searchController.text.trim().toLowerCase();
    return _areas.where((area) {
      if (query.isNotEmpty) {
        final matches = area.name.toLowerCase().contains(query) ||
            area.items.any(
              (item) =>
                  item.name.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query),
            );
        if (!matches) return false;
      }
      switch (_filter) {
        case _AreaFilter.all:
          return true;
        case _AreaFilter.pending:
          return _areaCompleted(area) < area.items.length;
        case _AreaFilter.critical:
          return _areaHasCritical(area);
        case _AreaFilter.done:
          return area.items.isNotEmpty &&
              _areaCompleted(area) == area.items.length;
      }
    }).toList(growable: false);
  }

  // ------------------------------------------------------------- loading

  /// Unchanged in behaviour from the old dashboard: ad-hoc plans keep only
  /// `Adhoc Inspection` items, everything else loads DB templates and merges
  /// the saved draft snapshot.
  Future<void> _loadChecklistAndDraft() async {
    if (!InspectionSession.isActive) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final inspectionType = InspectionSession.inspectionMode ?? 'flat';
    final inspectionPlan = InspectionSession.inspectionPlan ?? 'paid';

    if (inspectionPlan == 'adhoc') {
      final serverAreas =
          await SupabaseRepository.instance.loadInspectionDraft();
      final localAreas = await InspectionDraftStorage.loadAreas();
      final loadedAreas = serverAreas ?? localAreas ?? <InspectionArea>[];
      final existingDraft = loadedAreas
          .map((area) {
            final adhocItems = area.items
                .where((item) => item.category == 'Adhoc Inspection')
                .toList(growable: false);
            final completed = adhocItems.where((item) => item.completed).length;
            return area.copyWith(
              items: adhocItems,
              issues: adhocItems.length,
              completed: completed,
              progress: adhocItems.isEmpty
                  ? 0
                  : ((completed / adhocItems.length) * 100).round(),
              status: adhocItems.isNotEmpty && completed == adhocItems.length
                  ? 'completed'
                  : 'pending',
            );
          })
          .where((area) => area.items.isNotEmpty)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _templates = const [];
        _areas = existingDraft;
        _isLoading = false;
      });
      final loadedCount =
          loadedAreas.fold<int>(0, (sum, area) => sum + area.items.length);
      final keptCount =
          existingDraft.fold<int>(0, (sum, area) => sum + area.items.length);
      if (existingDraft.length != loadedAreas.length ||
          keptCount != loadedCount) {
        await _persistAreas(existingDraft);
      }
      await _restoreActiveAreaIfNeeded();
      return;
    }

    late final String inspectionKind;
    try {
      inspectionKind = await SupabaseRepository.instance
          .fetchChecklistKindForInspectionType(inspectionType: inspectionType);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Checklist mapping missing: $error';
      });
      return;
    }

    final remoteTemplates =
        await SupabaseRepository.instance.fetchChecklistTemplates(
      inspectionKind: inspectionKind,
      inspectionPlan: inspectionPlan,
      defaultsOnly: true,
    );
    final serverAreas = await SupabaseRepository.instance.loadInspectionDraft();
    final localAreas = await InspectionDraftStorage.loadAreas();
    final existingDraft = serverAreas ?? localAreas;

    if (!mounted) return;

    if (remoteTemplates.isNotEmpty) {
      final initialAreas = buildInspectionAreasFromTemplates(remoteTemplates);
      setState(() {
        _templates = remoteTemplates;
        _areas = existingDraft == null || existingDraft.isEmpty
            ? initialAreas
            : existingDraft;
        _isLoading = false;
      });
      if (existingDraft == null || existingDraft.isEmpty) {
        await _persistAreas(initialAreas);
      }
    } else {
      setState(() {
        _isLoading = false;
        _loadError = 'Checklist not found in DB for $inspectionKind. '
            'Run the checklist SQL setup.';
      });
    }

    final cachedAreas = existingDraft;
    if (!mounted || cachedAreas == null || cachedAreas.isEmpty) return;
    final normalizedAreas = ensureRequiredAreaChecks(cachedAreas);
    setState(() => _areas = normalizedAreas);
    if (normalizedAreas.length == cachedAreas.length) {
      await _persistAreas(normalizedAreas);
    }
    await _restoreActiveAreaIfNeeded();
  }

  /// Saves to the device and the server, reporting which succeeded so the
  /// inspector is not left guessing whether their work left the browser.
  Future<void> _persistAreas(List<InspectionArea> areas) async {
    SyncStatus.instance.markSaving();
    UnsavedWorkGuard.set(true);
    await InspectionDraftStorage.saveSession();
    await InspectionDraftStorage.saveAreas(areas);
    try {
      await SupabaseRepository.instance.saveInspectionDraft(areas: areas);
      SyncStatus.instance.markSynced();
      UnsavedWorkGuard.set(false);
    } catch (_) {
      // Saved on the device but not the server — closing the tab now would
      // strand the work on this browser only, so keep the guard armed.
      SyncStatus.instance.markLocalOnly();
    }
  }

  Future<void> _saveDraft() => _persistAreas(_areas);

  /// Refresh recovery: if the browser was reloaded while an area screen was
  /// open, reopen that area rather than dropping the user at the top.
  Future<void> _restoreActiveAreaIfNeeded() async {
    if (_didRestoreActiveArea || _areas.isEmpty) return;
    _didRestoreActiveArea = true;

    final activePage = await InspectionDraftStorage.loadActivePage();
    final activeAreaId = await InspectionDraftStorage.loadActiveAreaId();
    if (activePage != 'area' || activeAreaId == null || activeAreaId.isEmpty) {
      await InspectionDraftStorage.setActiveInspectionPage();
      return;
    }
    if (!mounted) return;
    setState(() => _expandedAreaIds.add(activeAreaId));
    await InspectionDraftStorage.setActiveInspectionPage();
  }

  // ------------------------------------------------------------- actions

  Future<void> _openItem(InspectionArea area, InspectionItem item) async {
    await InspectionDraftStorage.setActiveAreaPage(area.id);
    if (!mounted) return;
    final result = await Navigator.push<ChecklistItemResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistItemScreen(
          item: item,
          areaName: area.name,
          areaItems: area.items,
        ),
      ),
    );
    await InspectionDraftStorage.setActiveInspectionPage();
    if (result == null || !mounted) return;
    _applyItemUpdate(area, result.item);
    await _saveDraft();

    // "Save & next" walks the area without bouncing off the checklist.
    final nextId = result.openNextItemId;
    if (nextId == null || !mounted) return;
    final refreshedArea = _areas.firstWhere(
      (candidate) => candidate.id == area.id,
      orElse: () => area,
    );
    final nextIndex =
        refreshedArea.items.indexWhere((candidate) => candidate.id == nextId);
    if (nextIndex == -1) return;
    await _openItem(refreshedArea, refreshedArea.items[nextIndex]);
  }

  /// Pushes one area's results to the server. For individual inspections this
  /// is also the finalize action, matching the previous area screen.
  Future<void> _submitSection(InspectionArea area) async {
    final completed = _areaCompleted(area);
    final current = area.copyWith(
      progress: area.items.isEmpty
          ? 0
          : ((completed / area.items.length) * 100).round(),
      completed: completed,
      issues: area.items.length - completed,
      status: completed == area.items.length ? 'completed' : 'in-progress',
    );

    try {
      await _saveDraft();
      final inspectionId = InspectionSession.inspectionId;
      if (inspectionId != null) {
        await SupabaseRepository.instance.submitArea(
          inspectionId: inspectionId,
          area: current,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${area.name} section submitted.')),
      );
      if (InspectionSession.isIndividualInspection) {
        await _submit();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit section: $error')),
      );
    }
  }

  void _applyItemUpdate(InspectionArea area, InspectionItem updated) {
    setState(() {
      final areaIndex = _areas.indexWhere((a) => a.id == area.id);
      if (areaIndex == -1) return;
      final current = _areas[areaIndex];
      final items = [...current.items];
      final itemIndex = items.indexWhere((i) => i.id == updated.id);
      if (itemIndex == -1) return;
      items[itemIndex] = updated;
      final completed = items.where((i) => i.completed).length;
      _areas = [..._areas];
      _areas[areaIndex] = current.copyWith(
        items: items,
        completed: completed,
        issues: items.length,
        progress:
            items.isEmpty ? 0 : ((completed / items.length) * 100).round(),
        status: items.isNotEmpty && completed == items.length
            ? 'completed'
            : 'pending',
      );
    });
  }

  Future<void> _manageAreas() async {
    final updated = InspectionSession.isAdhocInspection
        ? await AreaManagerSheet.showAdhoc(context, areas: _areas)
        : await AreaManagerSheet.show(
            context,
            areas: _areas,
            templates: _templates,
          );
    if (updated == null || !mounted) return;
    setState(() => _areas = updated);
    await _saveDraft();
  }

  Future<void> _submit() async {
    final blockers = _blockers;
    if (blockers.isNotEmpty) {
      _showBlockersSheet(blockers);
      return;
    }
    if (!InspectionSession.isAdhocInspection) {
      setState(() => _areas = ensureRequiredAreaChecks(_areas));
    }
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SubmitResultScreen(areas: _areas)),
    );
    if (submitted != true || !mounted) return;
    UnsavedWorkGuard.set(false);
    setState(() {
      _areas = <InspectionArea>[];
      _expandedAreaIds.clear();
      _didRestoreActiveArea = false;
    });
    AppShell.of(context)
      ?..refreshData()
      ..goToTab(AppTab.home);
  }

  /// The pre-submit checklist. Each blocker deep-links to the first item it
  /// applies to, instead of naming three items in a SnackBar that vanishes.
  void _showBlockersSheet(List<SubmitBlocker> blockers) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.rule, color: AppColors.coral),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Before you submit',
                    style: AppStyles.headlineMd.copyWith(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${blockers.length} ${blockers.length == 1 ? 'issue' : 'issues'} '
              'to fix.',
              style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final blocker in blockers) ...[
              AppCard(
                accentColor: AppColors.error,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blocker.title,
                      style: AppStyles.labelMd.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      blocker.detail,
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                    if (blocker.targets.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${blocker.targets.length} '
                        '${blocker.targets.length == 1 ? 'check' : 'checks'}: '
                        '${blocker.targets.take(3).map((t) => t.itemName).join(', ')}'
                        '${blocker.targets.length > 3 ? '…' : ''}',
                        style: AppStyles.labelSm.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _jumpToTarget(blocker.targets.first);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Fix'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  void _jumpToTarget(BlockerTarget target) {
    final areaIndex = _areas.indexWhere((area) => area.id == target.areaId);
    if (areaIndex == -1) return;
    final area = _areas[areaIndex];
    final item = area.items.firstWhere(
      (candidate) => candidate.id == target.itemId,
      orElse: () => area.items.first,
    );
    setState(() => _expandedAreaIds.add(area.id));
    _openItem(area, item);
  }

  void _startInspection() {
    final inspector = InspectorLogin(
      userId: InspectionSession.inspectorId,
      displayName: InspectionSession.inspectorName ?? 'Inspector',
      phone: InspectionSession.mobileNumber,
      authToken: InspectionSession.authToken,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartInspectionFlow(
          inspector: inspector,
          onStarted: () {
            setState(() {
              _isLoading = true;
              _didRestoreActiveArea = false;
            });
            _loadChecklistAndDraft();
          },
          onSessionExpired: () {},
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (!InspectionSession.isActive) {
      return CustomScrollView(
        slivers: [
          const AppSliverBar(
              title: 'Inspect', subtitle: 'No active inspection'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No inspection running',
              message: 'Start an inspection and its checklist will appear '
                  'here.',
              actionLabel: 'Start an inspection',
              onAction: _startInspection,
            ),
          ),
        ],
      );
    }

    final blockers = _blockers;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              AppSliverBar(
                title: InspectionSession.societyName ?? 'Inspection',
                subtitle: InspectionSession.flatNumber,
                floating: false,
                actions: [
                  IconButton(
                    tooltip: 'Manage areas',
                    icon: const Icon(Icons.tune),
                    onPressed: _manageAreas,
                  ),
                ],
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                SliverToBoxAdapter(child: _buildSummary()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(
                    extent: _filterBarExtent(context),
                    child: _buildFilterBar(),
                  ),
                ),
                if (_loadError != null)
                  SliverToBoxAdapter(child: _buildLoadError()),
                if (_visibleAreas.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyAreas())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _visibleAreas.length) {
                          return _buildAddAreaTile();
                        }
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSizes.contentMaxWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: _buildAreaCard(_visibleAreas[index]),
                            ),
                          ),
                        );
                      },
                      childCount: _visibleAreas.length + 1,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ],
          ),
        ),
        _buildSubmitBar(blockers),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppCard(
            accentColor: AppColors.error,
            child: Text(
              _loadError!,
              style: AppStyles.bodySm.copyWith(color: AppColors.neutral700),
            ),
          ),
        ),
      ),
    );
  }

  /// The summary. A 72px ring instead of 120px, and three chips instead of
  /// five equally-weighted badges that wrapped into a ragged block on a phone.
  Widget _buildSummary() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: AppCard(
            elevation: AppElevation.raised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: _overallProgress / 100,
                              strokeWidth: 7,
                              backgroundColor: AppColors.neutral200,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.coral,
                              ),
                            ),
                          ),
                          Text(
                            '$_overallProgress%',
                            style: AppStyles.labelMd.copyWith(
                              fontSize: 16,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            InspectionSession.societyName ?? 'Property',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.headlineMd.copyWith(
                              color: AppColors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_completedItems of $_totalItems checks · '
                            '${_areas.length} areas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodySm.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppProgressBar(
                  value: _totalItems == 0 ? 0 : _completedItems / _totalItems,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _SummaryChip(
                      icon: Icons.pending_outlined,
                      label: 'Pending $_pendingItems',
                      color: AppColors.neutral600,
                    ),
                    if (_criticalItems.isNotEmpty)
                      _SummaryChip(
                        icon: Severity.critical.icon,
                        label: 'Critical ${_criticalItems.length}',
                        color: Severity.critical.color,
                      ),
                    if (_criticalEstimateTotal > 0)
                      _SummaryChip(
                        icon: Icons.currency_rupee,
                        label: 'Est. '
                            '${_criticalEstimateTotal.toStringAsFixed(0)}',
                        color: AppColors.info,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The pinned header needs a fixed extent, so derive it from the current
  /// text scale rather than hard-coding a height that clips at 200%.
  double _filterBarExtent(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    // search field + gap + chip row + vertical padding
    return (56 * scale) + AppSpacing.sm + (42 * scale) + 20;
  }

  Widget _buildFilterBar() {
    int pendingAreas =
        _areas.where((area) => _areaCompleted(area) < area.items.length).length;
    int criticalAreas = _areas.where(_areaHasCritical).length;
    int doneAreas = _areas
        .where((area) =>
            area.items.isNotEmpty && _areaCompleted(area) == area.items.length)
        .length;

    return Container(
      color: AppColors.neutral50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: AppStyles.buildInputDecoration(
                    hint: 'Search areas or checks',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: _searchController.clear,
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      AppFilterChip(
                        label: 'All',
                        count: _areas.length,
                        selected: _filter == _AreaFilter.all,
                        onTap: () => setState(() => _filter = _AreaFilter.all),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppFilterChip(
                        label: 'Pending',
                        count: pendingAreas,
                        selected: _filter == _AreaFilter.pending,
                        onTap: () =>
                            setState(() => _filter = _AreaFilter.pending),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppFilterChip(
                        label: 'Critical',
                        count: criticalAreas,
                        selected: _filter == _AreaFilter.critical,
                        onTap: () =>
                            setState(() => _filter = _AreaFilter.critical),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppFilterChip(
                        label: 'Done',
                        count: doneAreas,
                        selected: _filter == _AreaFilter.done,
                        onTap: () => setState(() => _filter = _AreaFilter.done),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAreas() {
    final isFiltered =
        _filter != _AreaFilter.all || _searchController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: AppEmptyState(
        icon: isFiltered ? Icons.filter_alt_off_outlined : Icons.add_home_work,
        title: isFiltered ? 'No areas match' : 'No areas yet',
        message: isFiltered
            ? 'Try a different filter or search term.'
            : InspectionSession.isAdhocInspection
                ? 'Ad-hoc inspections need at least one custom check before '
                    'you can submit.'
                : 'Add an inspection area to get started.',
        actionLabel: isFiltered ? null : 'Add area',
        onAction: isFiltered ? null : _manageAreas,
      ),
    );
  }

  Widget _buildAddAreaTile() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _manageAreas,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.neutral300,
                    style: BorderStyle.solid,
                  ),
                  color: Colors.white.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: AppColors.coral, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      InspectionSession.isAdhocInspection
                          ? 'Add custom check'
                          : 'Add area',
                      style: AppStyles.labelMd.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// An area expands in place to reveal its checks.
  Widget _buildAreaCard(InspectionArea area) {
    final completed = _areaCompleted(area);
    final total = area.items.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final isCritical = _areaHasCritical(area);
    final isDone = total > 0 && completed == total;
    final expanded = _expandedAreaIds.contains(area.id);

    return AppCard(
      elevation: AppElevation.flat,
      padding: EdgeInsets.zero,
      accentColor: isCritical
          ? Severity.critical.color
          : (isDone ? AppColors.success : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: '${area.name}, $completed of $total checks done',
            child: InkWell(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedAreaIds.remove(area.id);
                } else {
                  _expandedAreaIds.add(area.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      _iconFor(area.icon),
                      color: isCritical
                          ? Severity.critical.color
                          : AppColors.coral,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            area.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.labelMd.copyWith(
                              fontSize: 15,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: AppProgressBar(
                                  value: progress,
                                  height: 4,
                                  color: isDone
                                      ? AppColors.success
                                      : AppColors.coral,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$completed/$total',
                                style: AppStyles.labelSm.copyWith(
                                  color: AppColors.neutral600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (isCritical) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const SeverityPill(
                              severity: Severity.critical,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (isDone)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.expand_more,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.neutral200),
            for (final item in area.items) _buildItemRow(area, item),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: KeprButton(
                      label: 'Save draft',
                      height: AppSizes.minTapTarget,
                      variant: ButtonVariant.secondary,
                      onPressed: () async {
                        await _saveDraft();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: KeprButton(
                      label: 'Submit section',
                      height: AppSizes.minTapTarget,
                      onPressed: () => _submitSection(area),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(InspectionArea area, InspectionItem item) {
    final severity = Severity.fromValue(item.severity);
    return InkWell(
      onTap: () => _openItem(area, item),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.neutral100),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 19,
              color: item.completed ? AppColors.success : AppColors.neutral300,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySm.copyWith(
                      fontSize: 14,
                      color: item.completed
                          ? AppColors.neutral600
                          : AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.completed && severity != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    SeverityPill(severity: severity, compact: true),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  /// Submit is never a mystery: the bar states what still blocks it and when
  /// the draft last reached the server.
  Widget _buildSubmitBar(List<SubmitBlocker> blockers) {
    final blocked = blockers.isNotEmpty;
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.neutral200)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<DateTime?>(
                        valueListenable: SyncStatus.instance.lastSavedAt,
                        builder: (context, _, __) => Text(
                          SyncStatus.instance.describeLastSaved(),
                          style: AppStyles.labelSm.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                      if (blocked)
                        Text(
                          '${blockers.length} to fix before submitting',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.labelSm.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                KeprButton(
                  label: blocked ? 'Review' : 'Submit',
                  height: AppSizes.minTapTarget,
                  width: 132,
                  icon: Icon(
                    blocked ? Icons.rule : Icons.cloud_done,
                    color: Colors.white,
                    size: 19,
                  ),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'kitchen':
        return Icons.kitchen;
      case 'bed':
        return Icons.bed;
      case 'bathroom':
        return Icons.bathroom;
      case 'weekend':
        return Icons.weekend;
      case 'balcony':
        return Icons.balcony;
      case 'door_front_door':
        return Icons.door_front_door;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'water_drop':
        return Icons.water_drop;
      case 'build':
        return Icons.build;
      default:
        return Icons.home_work;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the search and filter row pinned under the app bar while the area
/// list scrolls.
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  _FilterBarDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: extent, child: child);
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) => true;
}
