import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/report_pdf_service.dart';
import '../services/supabase_repository.dart';
import '../widgets/badge.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_header.dart';
import 'inspection_area_screen.dart';
import 'profile_screen.dart';
import 'signin_screen.dart';

class InspectionsDashboardScreen extends StatefulWidget {
  const InspectionsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InspectionsDashboardScreen> createState() =>
      _InspectionsDashboardScreenState();
}

class _InspectionsDashboardScreenState
    extends State<InspectionsDashboardScreen> {
  BottomNavTab activeTab = BottomNavTab.home;
  late final TextEditingController searchController;
  late List<InspectionArea> areas;
  List<InspectionAreaTemplate> availableTemplates = const [];
  bool _isFinalSubmitting = false;
  bool _didRestoreActiveArea = false;

  int get completedItems => areas.fold(
        0,
        (sum, area) => sum + area.items.where((item) => item.completed).length,
      );

  int get totalItems => areas.fold(0, (sum, area) => sum + area.items.length);

  int get overallProgress =>
      totalItems == 0 ? 0 : ((completedItems / totalItems) * 100).round();

  int get pendingItems => totalItems - completedItems;

  Iterable<InspectionItem> get criticalUploadItems sync* {
    for (final area in areas) {
      for (final item in area.items) {
        final severity = (item.severity ?? '').toLowerCase();
        if (item.completed && severity == 'critical') {
          yield item;
        }
      }
    }
  }

  double get criticalEstimateTotal => criticalUploadItems.fold<double>(
        0,
        (sum, item) => sum + (item.estimatedCost ?? 0),
      );

  List<InspectionArea> get filteredAreas {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return areas;
    return areas
        .where(
          (area) =>
              area.name.toLowerCase().contains(query) ||
              area.items.any(
                (item) =>
                    item.name.toLowerCase().contains(query) ||
                    item.category.toLowerCase().contains(query),
              ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()
      ..addListener(() => setState(() {}));
    areas = <InspectionArea>[];
    _loadChecklistAndDraft();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (activeTab == BottomNavTab.profile) {
      return ProfileScreen(
        onTabChange: (tab) => setState(() => activeTab = tab),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: KeprHeader(
        title: 'Kepr',
        subtitle: InspectionSession.flatNumber ?? 'Inspection',
        onLogoTap: _goHome,
        onNotificationTap: _showNotifications,
        onMenuTap: _showQuickSelector,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(),
                  const SizedBox(height: 20),
                  _buildSearchRow(),
                  const SizedBox(height: 20),
                  _buildAreasHeader(),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, index) {
                      return _buildAreaCard(filteredAreas[index]);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Add Area',
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _showAddAreaSheet,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Submit & Generate Report',
                      icon: const Icon(Icons.cloud_done, color: Colors.white),
                      isLoading: _isFinalSubmitting,
                      onPressed: _isFinalSubmitting ? null : _finalSubmit,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeTab: activeTab,
              onTabChange: (tab) => setState(() => activeTab = tab),
            ),
          ),
        ],
      ),
    );
  }

  void _goHome() {
    setState(() => activeTab = BottomNavTab.home);
  }

  Future<void> _loadChecklistAndDraft() async {
    final inspectionType = InspectionSession.inspectionMode ?? 'flat';
    final inspectionPlan = InspectionSession.inspectionPlan ?? 'paid';
    late final String inspectionKind;
    try {
      inspectionKind = await SupabaseRepository.instance
          .fetchChecklistKindForInspectionType(inspectionType: inspectionType);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checklist mapping missing: $error')),
      );
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

    if (mounted && remoteTemplates.isNotEmpty) {
      final initialAreas = buildInspectionAreasFromTemplates(remoteTemplates);
      setState(() {
        availableTemplates = remoteTemplates;
        areas = existingDraft == null || existingDraft.isEmpty
            ? initialAreas
            : existingDraft;
      });
      if (existingDraft == null || existingDraft.isEmpty) {
        await InspectionDraftStorage.saveAreas(initialAreas);
        await SupabaseRepository.instance.saveInspectionDraft(
          areas: initialAreas,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checklist not found in DB for $inspectionKind. Run the checklist SQL setup.',
          ),
        ),
      );
    }

    final cachedAreas = existingDraft;
    if (!mounted || cachedAreas == null || cachedAreas.isEmpty) return;
    final normalizedAreas = ensureRequiredAreaChecks(cachedAreas);
    setState(() => areas = normalizedAreas);
    if (normalizedAreas.length == cachedAreas.length) {
      await InspectionDraftStorage.saveAreas(normalizedAreas);
      await SupabaseRepository.instance.saveInspectionDraft(
        areas: normalizedAreas,
      );
    }
    await _restoreActiveAreaIfNeeded();
  }

  Future<void> _saveDraft() async {
    await InspectionDraftStorage.saveSession();
    await InspectionDraftStorage.saveAreas(areas);
    await SupabaseRepository.instance.saveInspectionDraft(areas: areas);
  }

  Future<void> _restoreActiveAreaIfNeeded() async {
    if (_didRestoreActiveArea || areas.isEmpty) return;
    _didRestoreActiveArea = true;

    final activePage = await InspectionDraftStorage.loadActivePage();
    final activeAreaId = await InspectionDraftStorage.loadActiveAreaId();
    if (activePage != 'area' || activeAreaId == null || activeAreaId.isEmpty) {
      await InspectionDraftStorage.setActiveInspectionPage();
      return;
    }

    final area = areas.firstWhere(
      (candidate) => candidate.id == activeAreaId,
      orElse: () => areas.first,
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final updatedArea = await Navigator.push<InspectionArea>(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionAreaScreen(area: area),
        ),
      );
      await InspectionDraftStorage.setActiveInspectionPage();
      if (updatedArea == null || !mounted) return;
      setState(() {
        final index =
            areas.indexWhere((candidate) => candidate.id == updatedArea.id);
        if (index != -1) areas[index] = updatedArea;
      });
      await _saveDraft();
    });
  }

  void _showNotifications() {
    final lastLogin = InspectionSession.lastLoginAt;
    final lastLoginText = lastLogin == null
        ? 'No login recorded in this session.'
        : '${lastLogin.day.toString().padLeft(2, '0')}/'
            '${lastLogin.month.toString().padLeft(2, '0')}/'
            '${lastLogin.year} '
            '${lastLogin.hour.toString().padLeft(2, '0')}:'
            '${lastLogin.minute.toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Text(
          'Last login: $lastLoginText\n'
          'Inspector: ${InspectionSession.inspectorName ?? '-'}\n'
          'Mobile: ${InspectionSession.mobileNumber ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuickSelector() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inspection Home'),
              onTap: () {
                Navigator.pop(context);
                _goHome();
              },
            ),
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: const Text('Flat Selection'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login Page'),
              onTap: () async {
                InspectionSession.clear();
                await InspectionDraftStorage.clearAll();
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<SubmitReportResult?> _trySyncCriticalIssues({
    String? reportPdfUrl,
  }) async {
    final propertyId = InspectionSession.propertyId;
    final inspectionId = InspectionSession.inspectionId;
    final authToken = InspectionSession.authToken;
    if (propertyId == null || inspectionId == null || authToken == null) {
      throw Exception(
        'Missing inspection session. Please select society, block, and flat '
        'again before final submit.',
      );
    }

    _validateCriticalIssuesForSubmit();

    return SupabaseRepository.instance.submitReport(
      propertyId: propertyId,
      inspectionId: inspectionId,
      areas: areas,
      authToken: authToken,
      reportPdfUrl: reportPdfUrl,
    );
  }

  void _validateCriticalIssuesForSubmit() {
    if (completedItems < 5) {
      throw Exception(
        'Complete at least 5 inspection checks before submitting. '
        'Current completed checks: $completedItems.',
      );
    }

    final invalidPhotoItems = <String>[];
    for (final item in areas.expand((area) => area.items)) {
      for (final url in item.photoPaths) {
        if (!_isValidPublicUrl(url)) {
          invalidPhotoItems.add(item.name);
          break;
        }
      }
    }
    if (invalidPhotoItems.isNotEmpty) {
      throw Exception(
        'Invalid photo URL found. Please recapture/upload before submit: '
        '${invalidPhotoItems.take(3).join(', ')}',
      );
    }

    final missingNotesItems = areas.expand((area) => area.items).where((item) {
      final severity = (item.severity ?? '').toLowerCase();
      return item.completed &&
          (severity == 'high' || severity == 'critical') &&
          (item.notes ?? '').trim().isEmpty;
    }).toList();
    if (missingNotesItems.isNotEmpty) {
      final names =
          missingNotesItems.map((item) => item.name).take(3).join(', ');
      throw Exception(
        'Technician notes are required for high and critical issues: $names',
      );
    }

    final missingUploadItems = criticalUploadItems.where((item) {
      return item.photoEvidenceBase64.isNotEmpty && item.photoPaths.isEmpty;
    }).toList();
    if (missingUploadItems.isNotEmpty) {
      final names =
          missingUploadItems.map((item) => item.name).take(3).join(', ');
      throw Exception(
        'Some critical issue photos are saved locally but not uploaded. '
        'Please recapture/upload before final submit: $names',
      );
    }
    final missingServiceItems = criticalUploadItems
        .where((item) => item.selectedServices.isEmpty)
        .toList();
    if (missingServiceItems.isNotEmpty) {
      final names =
          missingServiceItems.map((item) => item.name).take(3).join(', ');
      throw Exception(
        'Services not added. Select a service for each critical issue or add '
        'Consultation for Rs 150: $names',
      );
    }
  }

  bool _isValidPublicUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.path.isNotEmpty &&
        uri.host == 'egalrsutygdvdmjkvduh.supabase.co' &&
        uri.path.contains('/storage/v1/object/public/');
  }

  Future<void> _finalSubmit() async {
    setState(() => _isFinalSubmitting = true);
    try {
      areas = ensureRequiredAreaChecks(areas);
      if (InspectionSession.isIndividualInspection) {
        await _finalSubmitIndividualInspection();
        return;
      }

      final propertyId = InspectionSession.propertyId;
      final inspectionId = InspectionSession.inspectionId;
      if (propertyId == null || inspectionId == null) {
        throw Exception('Missing selected flat. Please select flat again.');
      }
      _validateCriticalIssuesForSubmit();

      final societyName = InspectionSession.societyName ?? 'Property';
      final flatNumber = InspectionSession.flatNumber ?? '-';
      final propertyCode = InspectionSession.keprId;
      final pdfBytes = await ReportPdfService.buildCompleteReport(areas);
      final reportUrl =
          await SupabaseRepository.instance.uploadInspectionReportPdf(
        bytes: pdfBytes,
        propertyId: propertyId,
        inspectionId: inspectionId,
        inspectionType: InspectionSession.inspectionMode ?? 'flat',
        societyName: societyName,
      );
      if (reportUrl.isEmpty) {
        throw Exception('Could not upload full inspection PDF.');
      }
      if (!_isValidPublicUrl(reportUrl)) {
        throw Exception('Generated report URL is invalid.');
      }

      final submitResult = await _trySyncCriticalIssues(
        reportPdfUrl: reportUrl,
      );
      await InspectionDraftStorage.saveSubmittedReport(
        SubmittedInspectionReport(
          inspectionId: inspectionId,
          inspectionType: InspectionSession.inspectionMode ?? 'flat',
          propertyId: propertyId,
          societyName: societyName,
          flatNumber: flatNumber,
          propertyCode: InspectionSession.inspectionCode ?? propertyCode,
          reportUrl: reportUrl,
          submittedAt: DateTime.now(),
        ),
      );
      await InspectionDraftStorage.clearInspectionDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted. '
            'Health score ${submitResult?.healthScore ?? '-'} uploaded. '
            '${submitResult?.criticalIssueRows ?? 0} critical service rows uploaded.',
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Final submit failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isFinalSubmitting = false);
    }
  }

  Future<void> _finalSubmitIndividualInspection() async {
    final inspectionId = InspectionSession.inspectionId;
    final propertyId = InspectionSession.propertyId;
    if (inspectionId == null || propertyId == null) {
      throw Exception('Missing individual inspection session.');
    }

    _validateCriticalIssuesForSubmit();

    final propertyName = InspectionSession.societyName ?? 'Individual Property';
    final ownerName = InspectionSession.propertyOwnerName ?? '-';
    final ownerMobile = InspectionSession.propertyOwnerMobile ?? '-';
    final pdfBytes = await ReportPdfService.buildCompleteReport(areas);
    final reportUrl =
        await SupabaseRepository.instance.uploadInspectionReportPdf(
      bytes: pdfBytes,
      propertyId: propertyId,
      inspectionId: inspectionId,
      inspectionType: 'individual',
      societyName: propertyName,
    );
    if (reportUrl.isEmpty) {
      throw Exception('Could not upload full inspection PDF.');
    }
    if (!_isValidPublicUrl(reportUrl)) {
      throw Exception('Generated report URL is invalid.');
    }

    final savedId =
        await SupabaseRepository.instance.submitIndividualInspection(
      inspectionRef: inspectionId,
      inspectionCode: InspectionSession.inspectionCode ?? inspectionId,
      inspectionType: 'individual',
      areas: areas,
      inspectorName: InspectionSession.inspectorName ?? 'Inspector',
      inspectorId: InspectionSession.inspectorId,
      inspectorMobile: InspectionSession.mobileNumber,
      propertyName: propertyName,
      ownerName: ownerName,
      ownerMobile: ownerMobile,
      reportPdfUrl: reportUrl,
    );

    await InspectionDraftStorage.saveSubmittedReport(
      SubmittedInspectionReport(
        inspectionId: inspectionId,
        inspectionType: 'individual',
        propertyId: propertyId,
        societyName: propertyName,
        flatNumber: 'Owner: $ownerName',
        propertyCode: InspectionSession.inspectionCode ?? savedId,
        reportUrl: reportUrl,
        submittedAt: DateTime.now(),
      ),
    );
    await InspectionDraftStorage.clearInspectionDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Individual inspection report submitted.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: overallProgress / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$overallProgress%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'DONE',
                      style: AppStyles.labelSm.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${InspectionSession.societyName ?? 'Property'} - Annual Audit',
                  style: AppStyles.headlineMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dynamic checklist from KEPR Excel',
                  style: AppStyles.bodySm.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(
                      label: '$completedItems Completed',
                      variant: BadgeVariant.success,
                    ),
                    AppBadge(
                      label: '${areas.length} Areas',
                      variant: BadgeVariant.warning,
                    ),
                    AppBadge(
                      label: '$pendingItems Pending',
                      variant: BadgeVariant.error,
                    ),
                    AppBadge(
                      label: '$totalItems Checks',
                      variant: BadgeVariant.default_,
                    ),
                    AppBadge(
                      label:
                          'Rs ${criticalEstimateTotal.toStringAsFixed(0)} Critical Est.',
                      variant: BadgeVariant.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: AppStyles.buildInputDecoration(
              hint: 'Search areas or parameters...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAddAreaSheet,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.add, color: AppColors.navy),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreasHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'INSPECTION AREAS (${filteredAreas.length})',
            style: AppStyles.labelSm.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddAreaSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add area'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.coral,
            textStyle: AppStyles.labelMd,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard(InspectionArea area) {
    final completedCount = area.items.where((item) => item.completed).length;
    final pendingCount = area.items.length - completedCount;
    final progress = area.items.isEmpty
        ? 0
        : ((completedCount / area.items.length) * 100).round();
    final isUrgent = area.items
        .any((item) => (item.severity ?? '').toLowerCase() == 'critical');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? const Color(0xFFdc2626) : AppColors.neutral200,
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: AppColors.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await _saveDraft();
            await InspectionDraftStorage.setActiveAreaPage(area.id);
            final updatedArea = await Navigator.push<InspectionArea>(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionAreaScreen(area: area),
              ),
            );
            await InspectionDraftStorage.setActiveInspectionPage();
            if (updatedArea == null) return;
            setState(() {
              final index =
                  areas.indexWhere((candidate) => candidate.id == area.id);
              if (index != -1) areas[index] = updatedArea;
            });
            await _saveDraft();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _iconFor(area.icon),
                  color: AppColors.coral,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.name,
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrgent
                            ? 'Critical checks included'
                            : '$pendingCount Pending - ${area.items.length} checks',
                        style: AppStyles.bodySm.copyWith(
                          color:
                              isUrgent ? AppColors.error : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$progress%',
                      style: AppStyles.labelMd.copyWith(
                        color: progress == 100
                            ? const Color(0xFF10B981)
                            : AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (progress == 100)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 20,
                      )
                    else
                      SizedBox(
                        width: 50,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: AppColors.neutral200,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.coral),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.neutral400),
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

  void _showAddAreaSheet() {
    final nameController = TextEditingController();
    final customAreaController = TextEditingController();
    final customInspectionController = TextEditingController();
    final editNameController = TextEditingController();
    if (availableTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No DB checklist templates available. Run checklist SQL setup first.'),
        ),
      );
      return;
    }
    final templatesForSheet = availableTemplates;
    InspectionAreaTemplate selectedTemplate = templatesForSheet.first;
    InspectionAreaTemplate editTemplate = templatesForSheet.first;
    InspectionArea? selectedArea = areas.isEmpty ? null : areas.first;
    var mode = 'add';

    final initialArea = selectedArea;
    if (initialArea != null) {
      editNameController.text = initialArea.name;
      editTemplate = templatesForSheet.firstWhere(
        (template) => template.key == initialArea.templateKey,
        orElse: () => templatesForSheet.first,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add inspection area',
                        style: AppStyles.headlineMd.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'add',
                        icon: Icon(Icons.add_home_work_outlined),
                        label: Text('Add'),
                      ),
                      ButtonSegment(
                        value: 'custom',
                        icon: Icon(Icons.playlist_add_check),
                        label: Text('Custom'),
                      ),
                      ButtonSegment(
                        value: 'modify',
                        icon: Icon(Icons.tune),
                        label: Text('Modify'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setSheetState(() => mode = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (mode == 'add') ...[
                    Text(
                      'Area type mapping',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InspectionAreaTemplate>(
                      value: selectedTemplate,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final template in templatesForSheet)
                          DropdownMenuItem(
                            value: template,
                            child: Text(template.name),
                          ),
                      ],
                      onChanged: (template) {
                        if (template == null) return;
                        setSheetState(() {
                          selectedTemplate = template;
                          if (nameController.text.trim().isEmpty) {
                            nameController.text = template.name;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Display name',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Bedroom 3, Hall, Extra Balcony',
                      ),
                    ),
                  ] else if (mode == 'custom') ...[
                    Text(
                      'Custom area name',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customAreaController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Utility Room, Store Room, Office',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Custom inspection check',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customInspectionController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Check false ceiling access panel',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This creates a custom inspection area with your check and the standard wall dampness check.',
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Existing area',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InspectionArea>(
                      value: selectedArea,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final area in areas)
                          DropdownMenuItem(
                            value: area,
                            child: Text(area.name),
                          ),
                      ],
                      onChanged: (area) {
                        if (area == null) return;
                        setSheetState(() {
                          selectedArea = area;
                          editNameController.text = area.name;
                          editTemplate = templatesForSheet.firstWhere(
                            (template) => template.key == area.templateKey,
                            orElse: () => templatesForSheet.first,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New display name',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: editNameController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'Display name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Template mapping',
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<InspectionAreaTemplate>(
                      value: editTemplate,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final template in templatesForSheet)
                          DropdownMenuItem(
                            value: template,
                            child: Text(template.name),
                          ),
                      ],
                      onChanged: (template) {
                        if (template == null) return;
                        setSheetState(() => editTemplate = template);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Changing mapping replaces this area checklist with the selected template.',
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: mode == 'modify'
                          ? 'Update Mapping'
                          : mode == 'custom'
                              ? 'Add Custom Inspection'
                              : 'Add Area',
                      icon: Icon(
                        mode == 'modify' ? Icons.check : Icons.add,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (mode == 'modify') {
                          final area = selectedArea;
                          if (area == null) return;
                          final displayName =
                              editNameController.text.trim().isEmpty
                                  ? area.name
                                  : editNameController.text.trim();
                          final mappingChanged =
                              area.templateKey != editTemplate.key;
                          final mappedItems = mappingChanged
                              ? inspectionItemsForTemplate(editTemplate)
                              : area.items;
                          final updated = area.copyWith(
                            name: displayName,
                            icon: editTemplate.iconName,
                            templateKey: editTemplate.key,
                            issues: mappedItems.length,
                            completed: mappingChanged ? 0 : area.completed,
                            progress: mappingChanged ? 0 : area.progress,
                            status: mappingChanged ? 'pending' : area.status,
                            items: mappedItems,
                          );
                          setState(() {
                            areas = areas
                                .map((candidate) => candidate.id == area.id
                                    ? updated
                                    : candidate)
                                .toList(growable: false);
                          });
                          _saveDraft();
                          Navigator.pop(context);
                          return;
                        }

                        if (mode == 'custom') {
                          final displayName =
                              customAreaController.text.trim().isEmpty
                                  ? 'Custom Inspection'
                                  : customAreaController.text.trim();
                          final inspectionName =
                              customInspectionController.text.trim().isEmpty
                                  ? 'Custom inspection check'
                                  : customInspectionController.text.trim();
                          final key =
                              'custom-${DateTime.now().millisecondsSinceEpoch}';
                          final customTemplate = InspectionAreaTemplate(
                            key: key,
                            name: displayName,
                            iconName: 'build',
                            items: [
                              InspectionItem(
                                id: '$key-1',
                                name: inspectionName,
                                category: 'Custom Inspection',
                                inspectionType: 'Custom Check',
                                description:
                                    'Inspector-defined inspection check for $displayName.',
                                howTo: 'Source: Inspector custom inspection',
                                equipmentNeeded: 'Manual check, device camera',
                                severity: 'medium',
                                completed: false,
                              ),
                            ],
                          );
                          final templateItems =
                              inspectionItemsForTemplate(customTemplate);
                          final newArea = InspectionArea(
                            id: 'area-$key',
                            name: displayName,
                            icon: customTemplate.iconName,
                            templateKey: customTemplate.key,
                            progress: 0,
                            status: 'pending',
                            issues: templateItems.length,
                            completed: 0,
                            items: templateItems,
                          );
                          setState(() => areas = [...areas, newArea]);
                          _saveDraft();
                          Navigator.pop(context);
                          return;
                        }

                        final displayName = nameController.text.trim().isEmpty
                            ? selectedTemplate.name
                            : nameController.text.trim();
                        final templateItems =
                            inspectionItemsForTemplate(selectedTemplate);
                        final newArea = InspectionArea(
                          id: 'area-${selectedTemplate.key}-${DateTime.now().millisecondsSinceEpoch}',
                          name: displayName,
                          icon: selectedTemplate.iconName,
                          templateKey: selectedTemplate.key,
                          progress: 0,
                          status: 'pending',
                          issues: templateItems.length,
                          completed: 0,
                          items: templateItems,
                        );
                        setState(() {
                          areas = [...areas, newArea];
                        });
                        _saveDraft();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
