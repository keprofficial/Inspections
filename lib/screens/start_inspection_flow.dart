import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/inspection_start_service.dart';
import '../services/supabase_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/kepr_button.dart';
import 'property_details_screen.dart';
import 'property_picker_sheet.dart';

enum InspectionMode { flat, society, individual }

extension InspectionModeDisplay on InspectionMode {
  String get value {
    switch (this) {
      case InspectionMode.flat:
        return 'flat';
      case InspectionMode.society:
        return 'society';
      case InspectionMode.individual:
        return 'individual';
    }
  }

  String get title {
    switch (this) {
      case InspectionMode.flat:
        return 'Flat Property';
      case InspectionMode.society:
        return 'Society';
      case InspectionMode.individual:
        return 'Individual Home';
    }
  }

  String get subtitle {
    switch (this) {
      case InspectionMode.flat:
        return 'Society, block and flat';
      case InspectionMode.society:
        return 'Common areas and amenities';
      case InspectionMode.individual:
        return 'Independent owner property';
    }
  }

  IconData get icon {
    switch (this) {
      case InspectionMode.flat:
        return Icons.apartment_outlined;
      case InspectionMode.society:
        return Icons.business_outlined;
      case InspectionMode.individual:
        return Icons.person_pin_circle_outlined;
    }
  }

  String get shortLabel {
    switch (this) {
      case InspectionMode.flat:
        return 'Flat';
      case InspectionMode.society:
        return 'Society';
      case InspectionMode.individual:
        return 'Individual';
    }
  }
}

class _PlanOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlanOption(this.value, this.title, this.subtitle, this.icon);
}

const _planOptions = <_PlanOption>[
  _PlanOption(
    'free',
    'Free',
    '50 basic checks across the standard areas',
    Icons.fact_check_outlined,
  ),
  _PlanOption(
    'adhoc',
    'Ad-hoc',
    'You build the checklist yourself — at least one custom check required',
    Icons.playlist_add_check_outlined,
  ),
  _PlanOption(
    'paid',
    'Paid',
    'Complete checklist for the selected property type',
    Icons.workspace_premium_outlined,
  ),
];

/// A three-step wizard: what → which plan → which property.
///
/// Replaces the stacked `_showPropertyFields` / `_showSocietyOptions` booleans
/// that grew and shrank the page under the user's thumb.
class StartInspectionFlow extends StatefulWidget {
  final InspectorLogin inspector;

  /// Called once an inspection has been started and the session is populated.
  final VoidCallback onStarted;

  /// Called when the backend rejects the inspector session and login is needed.
  final VoidCallback onSessionExpired;

  const StartInspectionFlow({
    Key? key,
    required this.inspector,
    required this.onStarted,
    required this.onSessionExpired,
  }) : super(key: key);

  @override
  State<StartInspectionFlow> createState() => _StartInspectionFlowState();
}

class _StartInspectionFlowState extends State<StartInspectionFlow> {
  int _step = 0;

  InspectionMode? _mode;
  String? _plan;

  PropertyOption? _society;
  PropertyOption? _block;
  PropertyOption? _flat;

  final TextEditingController _propertyNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerMobileController = TextEditingController();

  bool _isStarting = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _propertyNameController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    super.dispose();
  }

  bool get _propertyStepComplete {
    switch (_mode) {
      case InspectionMode.individual:
        return _propertyNameController.text.trim().length >= 2 &&
            _ownerNameController.text.trim().length >= 2 &&
            _ownerMobileController.text.trim().length >= 8;
      case InspectionMode.society:
        return _society != null;
      case InspectionMode.flat:
        return _society != null && _block != null && _flat != null;
      case null:
        return false;
    }
  }

  String get _reviewLine {
    final parts = <String>[];
    if (_mode != null) parts.add(_mode!.shortLabel);
    if (_plan != null) {
      parts.add(_plan == 'adhoc'
          ? 'Ad-hoc'
          : '${_plan![0].toUpperCase()}${_plan!.substring(1)}');
    }
    switch (_mode) {
      case InspectionMode.flat:
        final where = [
          _society?.name,
          _block?.name,
          _flat?.name,
        ].whereType<String>().join(' / ');
        if (where.isNotEmpty) parts.add(where);
        break;
      case InspectionMode.society:
        if (_society != null) parts.add(_society!.name);
        break;
      case InspectionMode.individual:
        final name = _propertyNameController.text.trim();
        if (name.isNotEmpty) parts.add(name);
        break;
      case null:
        break;
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: _step == 0 ? 'Close' : 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text(
          _stepTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                Text(
                  'Step ${_step + 1} of 3',
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _stepHeadline,
                  style: AppStyles.headlineMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_step == 0) ..._buildModeStep(),
                if (_step == 1) ..._buildPlanStep(),
                if (_step == 2) ..._buildPropertyStep(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'New inspection';
      case 1:
        return 'Inspection plan';
      default:
        return 'Property details';
    }
  }

  String get _stepHeadline {
    switch (_step) {
      case 0:
        return 'What are you inspecting?';
      case 1:
        return 'Which plan applies?';
      default:
        switch (_mode) {
          case InspectionMode.individual:
            return 'Individual home details';
          case InspectionMode.society:
            return 'Which society?';
          default:
            return 'Which flat?';
        }
    }
  }

  // ---------------------------------------------------------------- step 1

  List<Widget> _buildModeStep() {
    return [
      for (final mode in InspectionMode.values) ...[
        _ChoiceRow(
          icon: mode.icon,
          title: mode.title,
          subtitle: mode.subtitle,
          selected: _mode == mode,
          onTap: () {
            setState(() {
              _mode = mode;
              // Changing the property kind invalidates everything downstream.
              _plan = null;
              _society = null;
              _block = null;
              _flat = null;
            });
            _next();
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  // ---------------------------------------------------------------- step 2

  List<Widget> _buildPlanStep() {
    return [
      for (final plan in _planOptions) ...[
        _ChoiceRow(
          icon: plan.icon,
          title: plan.title,
          subtitle: plan.subtitle,
          selected: _plan == plan.value,
          onTap: () {
            setState(() => _plan = plan.value);
            _next();
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  // ---------------------------------------------------------------- step 3

  List<Widget> _buildPropertyStep() {
    switch (_mode) {
      case InspectionMode.individual:
        return _buildIndividualFields();
      case InspectionMode.society:
        return _buildSocietyFields();
      default:
        return _buildFlatFields();
    }
  }

  List<Widget> _buildFlatFields() {
    return [
      PropertyPickerField(
        label: 'Society',
        placeholder: 'Choose a society',
        icon: Icons.apartment_outlined,
        value: _society,
        enabled: true,
        onTap: _pickSociety,
        onClear: () => setState(() {
          _society = null;
          _block = null;
          _flat = null;
        }),
      ),
      const SizedBox(height: AppSpacing.xl),
      PropertyPickerField(
        label: 'Block',
        placeholder: 'Choose a block',
        disabledHint: 'Select a society first',
        icon: Icons.domain_outlined,
        value: _block,
        enabled: _society != null,
        onTap: _pickBlock,
        onClear: () => setState(() {
          _block = null;
          _flat = null;
        }),
      ),
      const SizedBox(height: AppSpacing.xl),
      PropertyPickerField(
        label: 'Flat number',
        placeholder: 'Choose a flat',
        disabledHint: 'Select a block first',
        icon: Icons.home_outlined,
        value: _flat,
        enabled: _block != null,
        onTap: _pickFlat,
        onClear: () => setState(() => _flat = null),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Example: Sunrise Apartments, block A, flat 101',
        style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
      ),
    ];
  }

  List<Widget> _buildSocietyFields() {
    return [
      PropertyPickerField(
        label: 'Society',
        placeholder: 'Choose a society',
        icon: Icons.business_outlined,
        value: _society,
        enabled: true,
        onTap: _pickSociety,
        onClear: () => setState(() {
          _society = null;
          _block = null;
          _flat = null;
        }),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Society inspection uses the apartment common-area checklist.',
        style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
      ),
    ];
  }

  List<Widget> _buildIndividualFields() {
    return [
      _label('Property name'),
      TextField(
        controller: _propertyNameController,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        decoration: AppStyles.buildInputDecoration(
          hint: 'Example: Independent house, shop, office',
          prefixIcon: const Icon(Icons.home_work_outlined),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      _label('Property owner name'),
      TextField(
        controller: _ownerNameController,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        decoration: AppStyles.buildInputDecoration(
          hint: 'Owner full name',
          prefixIcon: const Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      _label('Property owner mobile'),
      TextField(
        controller: _ownerMobileController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        decoration: AppStyles.buildInputDecoration(
          hint: '9876543210',
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
      ),
    ];
  }

  Widget _label(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        value,
        style: AppStyles.labelMd.copyWith(color: AppColors.navy),
      ),
    );
  }

  // ------------------------------------------------------------- selection

  Future<void> _pickSociety() async {
    final picked = await PropertyPickerSheet.show(
      context,
      title: 'Select society',
      searchHint: 'Search society name or code',
      icon: Icons.apartment_outlined,
      loadOptions: (query) =>
          SupabaseRepository.instance.fetchSocieties(query: query),
    );
    if (picked == null || !mounted) return;
    final changed = _society?.id != picked.id;
    setState(() {
      _society = picked;
      if (changed) {
        _block = null;
        _flat = null;
      }
    });
    // Downstream selections are cleared off-screen; say so rather than let the
    // user discover it at submit time.
    if (changed && _mode == InspectionMode.flat) {
      _notify('Block and flat cleared for the new society.');
    }
  }

  Future<void> _pickBlock() async {
    final society = _society;
    if (society == null) return;
    final picked = await PropertyPickerSheet.show(
      context,
      title: 'Select block',
      searchHint: 'Search block',
      icon: Icons.domain_outlined,
      loadOptions: (query) => SupabaseRepository.instance.fetchBlocks(
        societyId: society.id,
        query: query,
      ),
    );
    if (picked == null || !mounted) return;
    final changed = _block?.id != picked.id;
    setState(() {
      _block = picked;
      if (changed) _flat = null;
    });
    if (changed) _notify('Flat cleared for the new block.');
  }

  Future<void> _pickFlat() async {
    final block = _block;
    if (block == null) return;
    final picked = await PropertyPickerSheet.show(
      context,
      title: 'Select flat',
      searchHint: 'Search flat number',
      icon: Icons.home_outlined,
      loadOptions: (query) => SupabaseRepository.instance.fetchFlats(
        blockId: block.id,
        query: query,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _flat = picked);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ------------------------------------------------------------ navigation

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _scrollToTop();
  }

  void _next() {
    if (_step >= 2) return;
    setState(() => _step++);
    _scrollToTop();
  }

  /// A new step starts at its own heading. Without this the list keeps the
  /// previous step's offset and drops the user into the middle of the page.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _mode != null;
      case 1:
        return _plan != null;
      default:
        return _propertyStepComplete;
    }
  }

  Widget _buildBottomBar() {
    final review = _reviewLine;
    return SafeArea(
      top: false,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (review.isNotEmpty) ...[
              Text(
                review,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.labelSm.copyWith(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            KeprButton(
              label: _step < 2 ? 'Continue' : 'Start inspection',
              height: AppSizes.minTapTarget,
              showArrow: _step < 2,
              isLoading: _isStarting,
              enabled: _canAdvance && !_isStarting,
              onPressed: _step < 2 ? _next : _start,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- start

  Future<void> _start() async {
    if (!_propertyStepComplete || _isStarting) return;
    setState(() => _isStarting = true);
    try {
      final plan = _plan ?? 'paid';
      late final StartDestination destination;
      switch (_mode!) {
        case InspectionMode.individual:
          destination =
              await InspectionStartService.instance.startIndividualInspection(
            authenticatedInspector: widget.inspector,
            propertyName: _propertyNameController.text,
            ownerName: _ownerNameController.text,
            ownerMobile: _ownerMobileController.text,
            inspectionPlan: plan,
          );
          break;
        case InspectionMode.society:
          destination =
              await InspectionStartService.instance.startSocietyInspection(
            authenticatedInspector: widget.inspector,
            society: _society!,
            inspectionPlan: plan,
          );
          break;
        case InspectionMode.flat:
          destination =
              await InspectionStartService.instance.startFlatInspection(
            authenticatedInspector: widget.inspector,
            society: _society!,
            block: _block!,
            flat: _flat!,
            inspectionPlan: plan,
          );
          break;
      }

      if (!mounted) return;
      if (destination == StartDestination.propertyDetails) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PropertyDetailsScreen()),
        );
        return;
      }
      Navigator.pop(context);
      widget.onStarted();
    } catch (error) {
      if (!mounted) return;
      if (InspectionStartService.isExpiredSessionError(error)) {
        InspectionSession.clearInspectorAuth();
        await InspectionDraftStorage.saveSession();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Login expired. Please enter mobile and password again.'),
          ),
        );
        Navigator.pop(context);
        widget.onSessionExpired();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start inspection: $error')),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

/// A full-width selectable row. Used for both the mode and plan steps, where
/// three side-by-side cards left only ~110px each on a 360px phone.
class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AppCard(
        onTap: onTap,
        elevation: selected ? AppElevation.raised : AppElevation.flat,
        borderColor: selected ? AppColors.coral : AppColors.neutral200,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.coral.withOpacity(0.12)
                    : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppColors.coral : AppColors.neutral600,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppStyles.labelMd.copyWith(
                      fontSize: 15,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppStyles.bodySm.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.coral : AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }
}
