import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../constants/inspection_icons.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/report_pdf_service.dart';
import '../services/supabase_repository.dart';
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
  bool _isLoadingChecklist = true;
  String? _checklistLoadError;

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

  Color get _modeAccentColor {
    switch (InspectionSession.inspectionMode ?? 'flat') {
      case 'society':
        return const Color(0xFF1565C0);
      case 'individual':
        return const Color(0xFF00897B);
      default:
        return AppColors.coral;
    }
  }

  String get _heroBannerAsset {
    final mode = InspectionSession.inspectionMode ?? 'flat';
    final hour = DateTime.now().hour;
    switch (mode) {
      case 'society':
        return hour < 17
            ? 'assets/images/SocietyBannerMorning.png'
            : 'assets/images/SocietyBannerEvening.png';
      case 'individual':
        return 'assets/images/intro_individual.png';
      default:
        return 'assets/images/intro_flat.png';
    }
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
        onLogoTap: _goInspectorDashboard,
        onNotificationTap: _showNotifications,
        onMenuTap: _showQuickSelector,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                Padding(
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
                      if (_isLoadingChecklist)
                        _buildChecklistLoading()
                      else if (_checklistLoadError != null)
                        _buildChecklistError(_checklistLoadError!)
                      else
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: KeprButton(
                          label: 'Submit & Generate Report',
                          icon:
                              const Icon(Icons.cloud_done, color: Colors.white),
                          isLoading: _isFinalSubmitting,
                          onPressed: _isFinalSubmitting ? null : _finalSubmit,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
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

  void _goInspectorDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  Future<void> _loadChecklistAndDraft() async {
    if (mounted) {
      setState(() {
        _isLoadingChecklist = true;
        _checklistLoadError = null;
      });
    }
    try {
      await _doLoadChecklistAndDraft();
    } catch (e) {
      if (mounted) {
        setState(() => _checklistLoadError =
            e.toString().replaceFirst('Exception: ', '').trim());
      }
    } finally {
      if (mounted) setState(() => _isLoadingChecklist = false);
    }
  }

  Future<void> _doLoadChecklistAndDraft() async {
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
        availableTemplates = const [];
        areas = existingDraft;
      });
      if (existingDraft.length != loadedAreas.length ||
          existingDraft.fold<int>(0, (sum, area) => sum + area.items.length) !=
              loadedAreas.fold<int>(
                  0, (sum, area) => sum + area.items.length)) {
        await InspectionDraftStorage.saveAreas(existingDraft);
        await SupabaseRepository.instance.saveInspectionDraft(
          areas: existingDraft,
        );
      }
      await _restoreActiveAreaIfNeeded();
      return;
    }
    late final String inspectionKind;
    try {
      inspectionKind = await SupabaseRepository.instance
          .fetchChecklistKindForInspectionType(inspectionType: inspectionType);
    } catch (error) {
      throw Exception('Checklist mapping missing: $error');
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

    if (remoteTemplates.isEmpty) {
      throw Exception(
        'Checklist not found for "$inspectionKind". Run the checklist SQL setup.',
      );
    }
    if (mounted) {
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
      final result = await Navigator.push<InspectionAreaScreenResult>(
        context,
        MaterialPageRoute(
          builder: (context) => InspectionAreaScreen(area: area),
        ),
      );
      await InspectionDraftStorage.setActiveInspectionPage();
      if (result == null || !mounted) return;
      final updatedArea = result.area;
      setState(() {
        final index =
            areas.indexWhere((candidate) => candidate.id == updatedArea.id);
        if (index != -1) areas[index] = updatedArea;
      });
      await _saveDraft();
      if (result.finalizeIndividualReport && mounted) {
        await _finalSubmit();
      }
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
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Current inspection'),
              onTap: () {
                Navigator.pop(context);
                _goHome();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Inspector dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
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
    if (!InspectionSession.isAdhocInspection && completedItems < 5) {
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
    final configuredHost = Uri.tryParse(SupabaseConfig.url)?.host ?? '';
    return uri != null &&
        uri.scheme == 'https' &&
        uri.path.isNotEmpty &&
        (configuredHost.isEmpty || uri.host == configuredHost) &&
        uri.path.contains('/storage/v1/object/public/');
  }

  Future<void> _finalSubmit() async {
    if (!InspectionSession.isAdhocInspection && completedItems < 5) {
      await _showSubmitMessage(
        'Minimum 5 checks required',
        'Complete at least 5 inspection checks before submitting. '
            'You have completed $completedItems of 5 required checks.',
      );
      return;
    }
    if (InspectionSession.isAdhocInspection && totalItems == 0) {
      await _showSubmitMessage(
        'Add an inspection check',
        'Add and complete at least one custom inspection check before submitting.',
      );
      return;
    }

    setState(() => _isFinalSubmitting = true);
    try {
      if (InspectionSession.isAdhocInspection) {
        if (totalItems == 0) {
          throw Exception('Add at least one custom inspection check first.');
        }
      } else {
        areas = ensureRequiredAreaChecks(areas);
      }
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
      await _showSubmitMessage(
        'Report not submitted',
        _friendlySubmitError(error),
      );
    } finally {
      if (mounted) setState(() => _isFinalSubmitting = false);
    }
  }

  String _friendlySubmitError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = text.toLowerCase();
    final isDatabaseError = lower.contains('postgres') ||
        lower.contains('postgrest') ||
        lower.contains('pgrst') ||
        lower.contains('sqlstate') ||
        lower.contains('relation ') ||
        lower.contains('column ');
    if (isDatabaseError) {
      return 'The server could not save this report. Your inspection remains available. Please try again or contact support.';
    }
    return text.isEmpty
        ? 'The report could not be submitted. Please try again.'
        : text;
  }

  Future<void> _showSubmitMessage(String title, String message) {
    if (!mounted) return Future.value();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Widget _buildHeroBanner() {
    final mode = InspectionSession.inspectionMode ?? 'flat';
    final modeLabel = mode == 'society'
        ? 'SOCIETY'
        : mode == 'individual'
            ? 'INDIVIDUAL HOME'
            : 'FLAT';
    final accent = _modeAccentColor;
    final propertyName = InspectionSession.societyName ?? 'Inspection';
    final detail = InspectionSession.flatNumber;

    return SizedBox(
      height: 196,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _heroBannerAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent.withOpacity(0.8), accent],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.25, 1.0],
                colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                modeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  propertyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null && detail.isNotEmpty)
                  Text(
                    detail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 6),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final accent = _modeAccentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowMd,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: overallProgress / 100,
                    strokeWidth: 9,
                    backgroundColor: AppColors.neutral100,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$overallProgress%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
                  InspectionSession.societyName ?? 'Property Inspection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(InspectionSession.inspectionMode ?? 'flat').toUpperCase()} · ${(InspectionSession.inspectionPlan ?? 'paid').toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral400,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniChip('$completedItems Done', AppColors.success),
                    _miniChip('$pendingItems Pending', AppColors.warning),
                    _miniChip('${areas.length} Areas', accent),
                    if (criticalUploadItems.isNotEmpty)
                      _miniChip(
                        'Rs ${criticalEstimateTotal.toStringAsFixed(0)}',
                        AppColors.error,
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

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    final accent = _modeAccentColor;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: AppStyles.buildInputDecoration(
              hint: 'Search areas or checks...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.neutral400,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.32),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showAddAreaSheet,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistLoading() {
    final accent = _modeAccentColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Loading inspection checklist…',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistError(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Could not load checklist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadChecklistAndDraft,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
    final accent = _modeAccentColor;
    final leftBarColor = isUrgent ? AppColors.error : accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _saveDraft();
            await InspectionDraftStorage.setActiveAreaPage(area.id);
            final result = await Navigator.push<InspectionAreaScreenResult>(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionAreaScreen(area: area),
              ),
            );
            await InspectionDraftStorage.setActiveInspectionPage();
            if (result == null || !mounted) return;
            final updatedArea = result.area;
            setState(() {
              final index =
                  areas.indexWhere((candidate) => candidate.id == area.id);
              if (index != -1) areas[index] = updatedArea;
            });
            await _saveDraft();
            if (result.finalizeIndividualReport && mounted) {
              await _finalSubmit();
            }
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  color: leftBarColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        areaIconBox(
                          area.icon,
                          colorOverride: isUrgent ? AppColors.error : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                area.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isUrgent
                                    ? 'Critical checks included'
                                    : '$pendingCount pending · ${area.items.length} checks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUrgent
                                      ? AppColors.error
                                      : AppColors.neutral500,
                                ),
                              ),
                              if (!isUrgent && area.items.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    minHeight: 4,
                                    backgroundColor: AppColors.neutral100,
                                    valueColor: AlwaysStoppedAnimation(
                                      progress == 100
                                          ? AppColors.success
                                          : accent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (progress == 100)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 22,
                              )
                            else
                              Text(
                                '$progress%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isUrgent ? AppColors.error : accent,
                                ),
                              ),
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.neutral300,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAreaSheet() {
    if (InspectionSession.isAdhocInspection) {
      _showAddAdhocInspectionSheet();
      return;
    }
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

  void _showAddAdhocInspectionSheet() {
    final areaController = TextEditingController();
    final checkController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Add custom inspection',
                  style: AppStyles.headlineMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Area name',
                style: AppStyles.labelMd.copyWith(color: AppColors.navy)),
            const SizedBox(height: 8),
            TextField(
              controller: areaController,
              decoration: AppStyles.buildInputDecoration(
                hint: 'e.g. Utility Room, Terrace, Store Room',
              ),
            ),
            const SizedBox(height: 16),
            Text('Inspection check',
                style: AppStyles.labelMd.copyWith(color: AppColors.navy)),
            const SizedBox(height: 8),
            TextField(
              controller: checkController,
              minLines: 2,
              maxLines: 4,
              decoration: AppStyles.buildInputDecoration(
                hint: 'Describe the custom check',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: KeprButton(
                label: 'Add Custom Inspection',
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final areaName = areaController.text.trim();
                  final checkName = checkController.text.trim();
                  if (areaName.isEmpty || checkName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Enter both area name and inspection check.'),
                      ),
                    );
                    return;
                  }
                  final key = 'adhoc-${DateTime.now().millisecondsSinceEpoch}';
                  final item = InspectionItem(
                    id: '$key-1',
                    name: checkName,
                    category: 'Adhoc Inspection',
                    inspectionType: 'Custom Check',
                    description: 'Inspector-defined check for $areaName.',
                    howTo: 'Source: Adhoc inspector checklist',
                    equipmentNeeded: 'Manual check, device camera',
                    severity: 'medium',
                    completed: false,
                  );
                  final newArea = InspectionArea(
                    id: 'area-$key',
                    name: areaName,
                    icon: 'build',
                    templateKey: key,
                    progress: 0,
                    status: 'pending',
                    issues: 1,
                    completed: 0,
                    items: [item],
                  );
                  setState(() => areas = [...areas, newArea]);
                  _saveDraft();
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
