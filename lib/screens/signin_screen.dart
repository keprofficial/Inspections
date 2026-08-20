import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_logo.dart';
import 'inspections_dashboard_screen.dart';
import 'profile_screen.dart';
import 'property_details_screen.dart';

enum _InspectionMode { flat, society, individual }

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final TextEditingController _mobileController;
  late final TextEditingController _passwordController;
  late final TextEditingController _societyController;
  late final TextEditingController _blockController;
  late final TextEditingController _flatController;
  late final TextEditingController _individualPropertyController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _ownerMobileController;

  List<PropertyOption> _societies = const [];
  List<PropertyOption> _blocks = const [];
  List<PropertyOption> _flats = const [];
  PropertyOption? _selectedSociety;
  PropertyOption? _selectedBlock;
  PropertyOption? _selectedFlat;
  InspectorLogin? _authenticatedInspector;
  bool _isAuthenticating = false;
  bool _isLoadingSocieties = false;
  bool _isLoadingBlocks = false;
  bool _isLoadingFlats = false;
  bool _isSigningIn = false;
  bool _showSocietyOptions = false;
  bool _showBlockOptions = false;
  bool _showFlatOptions = false;
  _InspectionMode? _inspectionMode;
  String? _inspectionPlan;
  int _dashboardStep = 0;
  List<SubmittedInspectionReport> _dashboardReports = const [];
  bool _isLoadingDashboardStats = false;
  Timer? _dashboardRefreshTimer;
  RealtimeChannel? _realtimeChannel;
  int _societyLoadToken = 0;
  int _blockLoadToken = 0;
  int _flatLoadToken = 0;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _passwordController = TextEditingController();
    _societyController = TextEditingController();
    _blockController = TextEditingController();
    _flatController = TextEditingController();
    _individualPropertyController = TextEditingController();
    _ownerNameController = TextEditingController();
    _ownerMobileController = TextEditingController();
    if (InspectionSession.hasFreshInspectorSession) {
      _authenticatedInspector = InspectorLogin(
        userId: InspectionSession.inspectorId,
        displayName: InspectionSession.inspectorName ?? 'Inspector',
        phone: InspectionSession.mobileNumber,
        authToken: InspectionSession.authToken,
      );
      final savedPlan = InspectionSession.inspectionPlan;
      _inspectionPlan =
          savedPlan == 'free' || savedPlan == 'paid' || savedPlan == 'adhoc'
              ? savedPlan
              : null;
    } else if ((InspectionSession.authToken ?? '').isNotEmpty) {
      InspectionSession.clearInspectorAuth();
      InspectionDraftStorage.saveSession();
    }
    _loadSocieties();
    if (_authenticatedInspector != null) {
      _restoreStartFlow();
      _loadDashboardStats();
      _startDashboardRefresh();
    }
  }

  Future<void> _restoreStartFlow() async {
    final data = await InspectionDraftStorage.loadStartFlow();
    if (data == null || !mounted || InspectionSession.isActive) return;
    final mode = data['mode']?.toString();
    final plan = data['plan']?.toString();
    setState(() {
      _dashboardStep =
          ((data['step'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt();
      _inspectionMode = mode == 'flat'
          ? _InspectionMode.flat
          : mode == 'society'
              ? _InspectionMode.society
              : mode == 'individual'
                  ? _InspectionMode.individual
                  : null;
      _inspectionPlan =
          plan == 'free' || plan == 'paid' || plan == 'adhoc' ? plan : null;
      _individualPropertyController.text =
          data['propertyName']?.toString() ?? '';
      _ownerNameController.text = data['ownerName']?.toString() ?? '';
      _ownerMobileController.text = data['ownerMobile']?.toString() ?? '';
      _selectedSociety = _optionFromDraft(data['society']);
      _selectedBlock = _optionFromDraft(data['block']);
      _selectedFlat = _optionFromDraft(data['flat']);
      _societyController.text = _selectedSociety?.name ?? '';
      _blockController.text = _selectedBlock?.name ?? '';
      _flatController.text = _selectedFlat?.name ?? '';
    });
  }

  PropertyOption? _optionFromDraft(Object? value) {
    if (value is! Map) return null;
    final data = value.map((key, value) => MapEntry(key.toString(), value));
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return PropertyOption(
      id: id,
      name: data['name']?.toString() ?? '',
      propertyCode: data['propertyCode']?.toString(),
      address: data['address']?.toString(),
    );
  }

  Map<String, dynamic>? _optionToDraft(PropertyOption? option) => option == null
      ? null
      : {
          'id': option.id,
          'name': option.name,
          'propertyCode': option.propertyCode,
          'address': option.address,
        };

  Future<void> _saveStartFlow() => InspectionDraftStorage.saveStartFlow({
        'step': _dashboardStep,
        'mode': _inspectionMode?.name,
        'plan': _inspectionPlan,
        'society': _optionToDraft(_selectedSociety),
        'block': _optionToDraft(_selectedBlock),
        'flat': _optionToDraft(_selectedFlat),
        'propertyName': _individualPropertyController.text,
        'ownerName': _ownerNameController.text,
        'ownerMobile': _ownerMobileController.text,
      });

  Future<void> _loadDashboardStats() async {
    if (_isLoadingDashboardStats) return;
    setState(() => _isLoadingDashboardStats = true);
    try {
      final remote =
          await SupabaseRepository.instance.fetchSubmittedInspectionReports(
        inspectorId: InspectionSession.inspectorId,
        inspectorName: InspectionSession.inspectorName,
        inspectorMobile: InspectionSession.mobileNumber,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _dashboardReports = remote
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      });
    } catch (_) {
      // Keep the last server result visible. Dashboard statistics intentionally
      // never use device-local submissions because they must match everywhere.
    } finally {
      if (mounted) setState(() => _isLoadingDashboardStats = false);
    }
  }

  void _startDashboardRefresh() {
    _dashboardRefreshTimer?.cancel();
    // Fallback poll every 60 s for deployments where realtime is not enabled.
    _dashboardRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_authenticatedInspector != null && _dashboardStep == 0) {
        _loadDashboardStats();
      }
    });

    // Supabase realtime — triggers an immediate stats reload on any
    // INSERT / UPDATE to the inspections or individual_inspections tables.
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = Supabase.instance.client
          .channel('kepr_inspector_stats')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'inspections',
            callback: (_) {
              if (mounted && _dashboardStep == 0) _loadDashboardStats();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'inspections',
            callback: (_) {
              if (mounted && _dashboardStep == 0) _loadDashboardStats();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'individual_inspections',
            callback: (_) {
              if (mounted && _dashboardStep == 0) _loadDashboardStats();
            },
          )
          .subscribe();
    } catch (_) {
      // Realtime not configured — the 60 s timer fallback is sufficient.
    }
  }

  @override
  void dispose() {
    _dashboardRefreshTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _mobileController.dispose();
    _passwordController.dispose();
    _societyController.dispose();
    _blockController.dispose();
    _flatController.dispose();
    _individualPropertyController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    super.dispose();
  }

  bool get _canSignIn {
    if (_authenticatedInspector == null) return false;
    if (_inspectionMode == _InspectionMode.individual) {
      return _individualPropertyController.text.trim().length >= 2 &&
          _ownerNameController.text.trim().length >= 2 &&
          _ownerMobileController.text.trim().length >= 8;
    }
    if (_inspectionMode == _InspectionMode.society) {
      return _selectedSociety != null;
    }
    return _selectedSociety != null &&
        _selectedBlock != null &&
        _selectedFlat != null;
  }

  bool get _canAuthenticate =>
      _mobileController.text.trim().length >= 8 &&
      _passwordController.text.isNotEmpty;

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onTabChange: (_) => Navigator.pop(context),
          showCurrentInspection: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticatedInspector != null) {
      return _buildAuthenticatedDashboard(context);
    }
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: KeprLogo(size: 84)),
                  const SizedBox(height: 28),
                  Text(
                    'Start inspection',
                    textAlign: TextAlign.center,
                    style: AppStyles.headlineMd.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _authenticatedInspector == null
                        ? 'Sign in with mobile number and password.'
                        : 'Choose flat, society, or individual inspection.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMd.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_authenticatedInspector == null) ...[
                          _buildLabel('Mobile number'),
                          TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: AppStyles.buildInputDecoration(
                              hint: '9876543210',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('Password'),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            decoration: AppStyles.buildInputDecoration(
                              hint: 'Enter password',
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: KeprButton(
                              label: 'Continue',
                              isLoading: _isAuthenticating,
                              enabled: !_isAuthenticating,
                              onPressed:
                                  _isAuthenticating ? null : _authenticate,
                            ),
                          ),
                        ],
                        if (_authenticatedInspector != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Signed in as ${_authenticatedInspector!.displayName}',
                                    style: AppStyles.bodySm.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openProfile,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.coral,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    textStyle: AppStyles.labelSm.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text('Go to profile'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_authenticatedInspector != null) ...[
                          const SizedBox(height: 18),
                          _buildInspectionModeSelector(),
                          const SizedBox(height: 18),
                          _buildInspectionPlanSelector(),
                          const SizedBox(height: 18),
                          if (_inspectionMode == _InspectionMode.flat)
                            ..._buildFlatInspectionFields()
                          else if (_inspectionMode == _InspectionMode.society)
                            ..._buildSocietyInspectionFields()
                          else
                            ..._buildIndividualInspectionFields(),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: KeprButton(
                              label: _inspectionMode == _InspectionMode.flat
                                  ? 'Start Flat Inspection'
                                  : _inspectionMode == _InspectionMode.society
                                      ? 'Start Society Inspection'
                                      : 'Start Individual Inspection',
                              isLoading: _isSigningIn,
                              enabled: _canSignIn,
                              onPressed: _canSignIn ? _signIn : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '2026 Kepr Inc. All rights reserved.',
                    textAlign: TextAlign.center,
                    style:
                        AppStyles.labelSm.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedDashboard(BuildContext context) {
    final inspector = _authenticatedInspector!;
    final canContinue = _inspectionMode != null && _inspectionPlan != null;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.lightHero,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: _dashboardStep == 0
                ? null
                : IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _previousDashboardStep,
                  ),
            title: Row(
              children: [
                const KeprLogo(size: 38),
                const SizedBox(width: 10),
                const Text(
                  'Kepr',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _showDashboardNavigation,
                tooltip: 'Navigation',
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_dashboardStep == 0) ...[
                  Text(
                    'Good ${_dayPeriod()}, ${inspector.displayName}',
                    style: AppStyles.headlineMd.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Here's your inspection activity",
                    style: AppStyles.bodyMd.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDashboardStats(),
                  const SizedBox(height: 18),
                  _buildWeeklyChart(),
                  if (InspectionSession.isActive) ...[
                    const SizedBox(height: 20),
                    _buildResumeInspectionCard(),
                  ],
                  const SizedBox(height: 24),
                  KeprButton(
                    label: 'Start new inspection',
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _inspectionMode = null;
                        _inspectionPlan = null;

                        _dashboardStep = 1;
                      });
                      _saveStartFlow();
                    },
                  ),
                ] else if (_dashboardStep == 1) ...[
                  _buildDashboardSectionTitle('Choose property', 'Step 1 of 3'),
                  const SizedBox(height: 8),
                  Text(
                    'What are you inspecting?',
                    style:
                        AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 18),
                  _buildInspectionModeSelector(),
                ] else if (_dashboardStep == 2) ...[
                  _buildDashboardSectionTitle(
                      'Choose inspection', 'Step 2 of 3'),
                  const SizedBox(height: 8),
                  Text(
                    'Select the plan for this ${_selectedModeLabel().toLowerCase()}.',
                    style:
                        AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 18),
                  _buildInspectionPlanSelector(),
                ] else if (canContinue) ...[
                  _buildDashboardSectionTitle(
                      'Property details', 'Step 3 of 3'),
                  const SizedBox(height: 14),
                  _buildPropertyFieldsCard(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _dashboardStep == 0
          ? BottomNav(
              activeTab: BottomNavTab.home,
              onTabChange: (tab) {
                if (tab == BottomNavTab.profile) _openProfile();
              },
            )
          : null,
    );
  }

  void _previousDashboardStep() {
    setState(() {
      if (_dashboardStep <= 1) {
        _dashboardStep = 0;
        _inspectionMode = null;
        _inspectionPlan = null;
      } else {
        _dashboardStep--;
      }
    });
    if (_dashboardStep == 0) {
      InspectionDraftStorage.clearStartFlow();
    } else {
      _saveStartFlow();
    }
  }

  Future<void> _showDashboardNavigation() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _dashboardStep = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Start inspection'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _inspectionMode = null;
                    _inspectionPlan = null;

                    _dashboardStep = 1;
                  });
                  _saveStartFlow();
                },
              ),
              if (InspectionSession.isActive)
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Current inspection'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InspectionsDashboardScreen(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openProfile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSectionTitle(String title, String step) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppStyles.headlineMd.copyWith(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          step,
          style: AppStyles.labelSm.copyWith(color: AppColors.neutral500),
        ),
      ],
    );
  }

  Widget _buildResumeInspectionCard() {
    final type = InspectionSession.inspectionMode ?? 'flat';
    final plan = InspectionSession.inspectionPlan ?? 'paid';
    final property = InspectionSession.societyName ??
        InspectionSession.flatNumber ??
        'Active property';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restore, color: AppColors.coral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_displayMode(type)} · ${_displayPlan(plan)} inspection',
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const InspectionsDashboardScreen(),
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final todayReports = _reportsBetween(today, tomorrow);
    final weekReports = _reportsBetween(weekStart, weekEnd);
    final monthReports = _reportsBetween(monthStart, monthEnd);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: _dashboardReports.length,
                label: 'Total',
                sublabel: 'All time',
                icon: Icons.assignment_turned_in_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF18181B), Color(0xFF3F3F46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showReportDetails(
                  title: 'All inspections',
                  subtitle: 'All submitted reports',
                  reports: _dashboardReports,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                value: todayReports.length,
                label: 'Today',
                sublabel: _formatShortDate(today),
                icon: Icons.today_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE06655), Color(0xFFFF9645)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showReportDetails(
                  title: 'Today',
                  subtitle: _formatLongDate(today),
                  reports: todayReports,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: weekReports.length,
                label: 'This week',
                sublabel:
                    '${_formatShortDate(weekStart)} – ${_formatShortDate(weekEnd.subtract(const Duration(days: 1)))}',
                icon: Icons.date_range_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showReportDetails(
                  title: 'This week',
                  subtitle:
                      '${_formatLongDate(weekStart)} – ${_formatLongDate(weekEnd.subtract(const Duration(days: 1)))}',
                  reports: weekReports,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                value: monthReports.length,
                label: 'This month',
                sublabel: '${_monthName(now.month)} ${now.year}',
                icon: Icons.calendar_month_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showReportDetails(
                  title: 'This month',
                  subtitle: '${_monthName(now.month)} ${now.year}',
                  reports: monthReports,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int value,
    required String label,
    required String sublabel,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -6,
              child:
                  Icon(icon, size: 52, color: Colors.white.withOpacity(0.10)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.75),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: AppStyles.headlineMd.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelSm.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.labelSm.copyWith(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final nextDay = day.add(const Duration(days: 1));
      return _dashboardReports.where((report) {
        final submitted = report.submittedAt.toLocal();
        return !submitted.isBefore(day) && submitted.isBefore(nextDay);
      }).length;
    });
    final maxCount =
        counts.fold<int>(1, (max, count) => count > max ? count : max);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppColors.coral),
              const SizedBox(width: 8),
              Text(
                'Weekly inspections',
                style: AppStyles.labelMd.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatShortDate(weekStart)} – ${_formatShortDate(weekStart.add(const Duration(days: 6)))}',
                style: AppStyles.labelSm.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a day to view reports',
            style: AppStyles.labelSm.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isToday = index == today.weekday - 1;
                final day = weekStart.add(Duration(days: index));
                final dayReports = _reportsBetween(
                  day,
                  day.add(const Duration(days: 1)),
                );
                final height =
                    counts[index] == 0 ? 5.0 : 84.0 * counts[index] / maxCount;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showReportDetails(
                      title: '${labels[index]} · ${_formatShortDate(day)}',
                      subtitle: _formatLongDate(day),
                      reports: dayReports,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${counts[index]}',
                          style: AppStyles.labelSm.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 18,
                          height: height,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.coral
                                : AppColors.coral.withOpacity(0.48),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${labels[index]} ${day.day}',
                          style: AppStyles.labelSm.copyWith(
                            color: isToday
                                ? AppColors.coral
                                : AppColors.neutral600,
                            fontWeight:
                                isToday ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<SubmittedInspectionReport> _reportsBetween(
    DateTime start,
    DateTime end,
  ) {
    return _dashboardReports.where((report) {
      final submitted = report.submittedAt.toLocal();
      return !submitted.isBefore(start) && submitted.isBefore(end);
    }).toList(growable: false);
  }

  String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];

  String _formatShortDate(DateTime date) =>
      '${date.day} ${_monthName(date.month).substring(0, 3)}';

  String _formatLongDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';

  String _formatReportTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${_formatLongDate(local)} · $hour:$minute $period';
  }

  Future<void> _showReportDetails({
    required String title,
    required String subtitle,
    required List<SubmittedInspectionReport> reports,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppStyles.headlineMd.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$subtitle · ${reports.length} report${reports.length == 1 ? '' : 's'}',
                          style: AppStyles.bodySm.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: reports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 44,
                              color: AppColors.neutral400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No inspections in this period',
                              style: AppStyles.labelMd.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          _buildReportDetailCard(reports[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportDetailCard(SubmittedInspectionReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.coral,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.societyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.labelMd.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      report.flatNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _displayMode(report.inspectionType ?? 'flat'),
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatReportTime(report.submittedAt),
            style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
          ),
          if ((report.propertyCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Inspection code: ${report.propertyCode}',
              style: AppStyles.labelSm.copyWith(color: AppColors.neutral500),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _openReportPdf(report.reportUrl),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Open PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coral,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReportPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      await _showMessage(
        'PDF unavailable',
        'The report PDF could not be opened. Please try again.',
      );
    }
  }

  Widget _buildPropertyFieldsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined, color: AppColors.coral),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_selectedModeLabel()} details',
                  style: AppStyles.headlineMd.copyWith(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _dashboardStep = 1);
                  _saveStartFlow();
                },
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_inspectionMode == _InspectionMode.flat)
            ..._buildFlatInspectionFields()
          else if (_inspectionMode == _InspectionMode.society)
            ..._buildSocietyInspectionFields()
          else
            ..._buildIndividualInspectionFields(),
          const SizedBox(height: 24),
          KeprButton(
            label: _inspectionMode == _InspectionMode.flat
                ? 'Start Flat Inspection'
                : _inspectionMode == _InspectionMode.society
                    ? 'Start Society Inspection'
                    : 'Start Individual Inspection',
            isLoading: _isSigningIn,
            enabled: !_isSigningIn,
            onPressed: _isSigningIn ? null : _attemptStartInspection,
          ),
        ],
      ),
    );
  }

  String _selectedModeLabel() {
    switch (_inspectionMode) {
      case _InspectionMode.flat:
        return 'Flat property';
      case _InspectionMode.society:
        return 'Society';
      case _InspectionMode.individual:
        return 'Individual home';
      case null:
        return 'Property';
    }
  }

  String _displayMode(String value) {
    if (value == 'society') return 'Society';
    if (value == 'individual') return 'Individual';
    return 'Flat';
  }

  String _displayPlan(String value) {
    if (value == 'adhoc') return 'Ad-hoc';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _dayPeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildLabel(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value,
        style: AppStyles.labelMd.copyWith(color: AppColors.navy),
      ),
    );
  }

  Widget _buildInspectionModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.90),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModeCard(
            mode: _InspectionMode.flat,
            icon: Icons.apartment_rounded,
            title: 'Flat Property',
            subtitle: 'Society, block and flat',
          ),
          const SizedBox(height: 10),
          _buildModeCard(
            mode: _InspectionMode.society,
            icon: Icons.location_city_rounded,
            title: 'Society',
            subtitle: 'Common areas and amenities',
          ),
          const SizedBox(height: 10),
          _buildModeCard(
            mode: _InspectionMode.individual,
            icon: Icons.home_rounded,
            title: 'Individual Home',
            subtitle: 'Independent owner property',
          ),
        ],
      ),
    );
  }

  // Mode-specific accent colors (Kepr-Homecare inspired)
  static const _modeAccents = {
    _InspectionMode.society: Color(0xFF1565C0), // deep blue — urban high-rise
    _InspectionMode.flat: Color(0xFFE06655), // coral — KEPR brand
    _InspectionMode.individual: Color(0xFF00897B), // teal — personal home
  };

  static const _modeUnselectedBg = {
    _InspectionMode.society: Color(0xFFF0F4FF), // ice blue
    _InspectionMode.flat: Color(0xFFFFF4F0), // warm cream
    _InspectionMode.individual: Color(0xFFF0FBF5), // mint
  };

  // Large decorative icon used as a watermark in the card background
  static const _modeDecoIcon = {
    _InspectionMode.society: Icons.location_city,
    _InspectionMode.flat: Icons.apartment,
    _InspectionMode.individual: Icons.home,
  };

  Widget _buildModeCard({
    required _InspectionMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _inspectionMode == mode;
    final accent = _modeAccents[mode] ?? AppColors.coral;
    final bgColor = selected
        ? Colors.white
        : (_modeUnselectedBg[mode] ?? const Color(0xFFF9FBFE));
    final decoIcon = _modeDecoIcon[mode] ?? icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _inspectionMode = mode;
            _inspectionPlan = null;

            _dashboardStep = 2;
          });
          _saveStartFlow();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 92),
          padding:
              EdgeInsets.all(MediaQuery.of(context).size.width < 380 ? 10 : 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : bgColor,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Watermark building/home silhouette in the background
              Positioned(
                right: -4,
                bottom: -8,
                child: Icon(
                  decoIcon,
                  size: 76,
                  color: selected
                      ? accent.withOpacity(0.08)
                      : accent.withOpacity(0.06),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? accent : accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: accent.withOpacity(0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: selected ? Colors.white : accent,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: selected ? 1 : 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelMd.copyWith(
                      color: selected ? accent : AppColors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelSm.copyWith(
                      color: selected
                          ? accent.withOpacity(0.75)
                          : AppColors.foregroundMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionPlanSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          _buildPlanCard(
            plan: 'free',
            title: 'Free',
            subtitle: '50 basic checks',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 10),
          _buildPlanCard(
            plan: 'adhoc',
            title: 'Ad-hoc',
            subtitle: 'Create custom checks',
            icon: Icons.playlist_add_check_outlined,
          ),
          const SizedBox(height: 10),
          _buildPlanCard(
            plan: 'paid',
            title: 'Paid',
            subtitle: 'Complete checklist',
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _inspectionPlan == plan;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _inspectionPlan = plan;

          _dashboardStep = 3;
        });
        _saveStartFlow();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.neutral200,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? AppColors.shadowSm : const [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.coral : AppColors.neutral600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelMd.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.labelSm.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.coral, size: 19),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFlatInspectionFields() {
    return [
      _buildPropertyAutocomplete(
        key: const ValueKey('society-search'),
        label: 'Society',
        hint: _isLoadingSocieties ? 'Loading societies...' : 'Search society',
        icon: Icons.apartment_outlined,
        controller: _societyController,
        options: _societies,
        enabled: true,
        selectedOption: _selectedSociety,
        showOptions: _showSocietyOptions,
        onOpen: () => setState(() => _showSocietyOptions = true),
        onSearchChanged: _onSocietySearchChanged,
        onSelected: _selectSociety,
        onClear: _clearSociety,
      ),
      const SizedBox(height: 18),
      _buildPropertyAutocomplete(
        key: ValueKey('block-search-${_selectedSociety?.id ?? 'none'}'),
        label: 'Block',
        hint: _selectedSociety == null
            ? 'Select society first'
            : _isLoadingBlocks
                ? 'Loading blocks...'
                : 'Search block',
        icon: Icons.domain_outlined,
        controller: _blockController,
        options: _blocks,
        enabled: _selectedSociety != null,
        selectedOption: _selectedBlock,
        showOptions: _showBlockOptions,
        onOpen: () => setState(() => _showBlockOptions = true),
        onSearchChanged:
            _selectedSociety == null ? null : _onBlockSearchChanged,
        onSelected: _selectBlock,
        onClear: _clearBlock,
      ),
      const SizedBox(height: 18),
      _buildPropertyAutocomplete(
        key: ValueKey('flat-search-${_selectedBlock?.id ?? 'none'}'),
        label: 'Flat number',
        hint: _selectedBlock == null
            ? 'Select block first'
            : _isLoadingFlats
                ? 'Loading flats...'
                : 'Search flat',
        icon: Icons.home_outlined,
        controller: _flatController,
        options: _flats,
        enabled: _selectedBlock != null,
        selectedOption: _selectedFlat,
        showOptions: _showFlatOptions,
        onOpen: () => setState(() => _showFlatOptions = true),
        onSearchChanged: _selectedBlock == null ? null : _onFlatSearchChanged,
        onSelected: _selectFlat,
        onClear: _clearFlat,
      ),
      const SizedBox(height: 8),
      Text(
        'Example: Sunrise Apartments, block A, flat 101',
        style: AppStyles.bodySm.copyWith(color: AppColors.neutral500),
      ),
    ];
  }

  List<Widget> _buildSocietyInspectionFields() {
    return [
      _buildPropertyAutocomplete(
        key: const ValueKey('society-only-search'),
        label: 'Society',
        hint: _isLoadingSocieties ? 'Loading societies...' : 'Search society',
        icon: Icons.location_city_rounded,
        controller: _societyController,
        options: _societies,
        enabled: true,
        selectedOption: _selectedSociety,
        showOptions: _showSocietyOptions,
        onOpen: () => setState(() => _showSocietyOptions = true),
        onSearchChanged: _onSocietySearchChanged,
        onSelected: (society) {
          _selectSociety(society);
          _clearBlock();
        },
        onClear: _clearSociety,
      ),
      const SizedBox(height: 8),
      Text(
        'Society inspection uses the apartment common-area checklist.',
        style: AppStyles.bodySm.copyWith(color: AppColors.neutral500),
      ),
    ];
  }

  List<Widget> _buildIndividualInspectionFields() {
    return [
      _buildLabel('Property name'),
      TextField(
        controller: _individualPropertyController,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          setState(() {});
          _saveStartFlow();
        },
        decoration: AppStyles.buildInputDecoration(
          hint: 'Example: Independent house, shop, office',
          prefixIcon: const Icon(Icons.home_work_outlined),
        ),
      ),
      const SizedBox(height: 18),
      _buildLabel('Property owner name'),
      TextField(
        controller: _ownerNameController,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          setState(() {});
          _saveStartFlow();
        },
        decoration: AppStyles.buildInputDecoration(
          hint: 'Owner full name',
          prefixIcon: const Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 18),
      _buildLabel('Property owner mobile'),
      TextField(
        controller: _ownerMobileController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          setState(() {});
          _saveStartFlow();
        },
        decoration: AppStyles.buildInputDecoration(
          hint: '9876543210',
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
      ),
    ];
  }

  Widget _buildPropertyAutocomplete({
    required Key key,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required List<PropertyOption> options,
    required bool enabled,
    required PropertyOption? selectedOption,
    required bool showOptions,
    required VoidCallback onOpen,
    required ValueChanged<PropertyOption> onSelected,
    required VoidCallback onClear,
    ValueChanged<String>? onSearchChanged,
  }) {
    final query = selectedOption != null && showOptions
        ? ''
        : _searchText(controller.text);
    final visibleOptions = query.isEmpty
        ? options
        : options
            .where(
              (option) =>
                  _searchText(option.name).contains(query) ||
                  _searchText(option.propertyCode ?? '').contains(query),
            )
            .toList();
    final shouldShowOptions =
        enabled && showOptions && visibleOptions.isNotEmpty;

    return TextFieldTapRegion(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextField(
            controller: controller,
            enabled: enabled,
            onTap: onOpen,
            onTapOutside: (_) {
              Future<void>.delayed(const Duration(milliseconds: 180), () {
                if (mounted) _hidePropertyOptions();
              });
            },
            onChanged: (value) {
              onOpen();
              onSearchChanged?.call(value);
              setState(() {});
            },
            decoration: AppStyles.buildInputDecoration(
              hint: hint,
              prefixIcon: Icon(icon),
              suffixIcon: SizedBox(
                width: controller.text.isEmpty ? 48 : 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: onClear,
                      ),
                    IconButton(
                      tooltip: showOptions ? 'Close dropdown' : 'Open dropdown',
                      icon: Icon(
                        showOptions ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: enabled
                          ? () {
                              if (showOptions) {
                                _hidePropertyOptions();
                              } else {
                                onOpen();
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (shouldShowOptions) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.neutral200),
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppColors.shadowSm,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: visibleOptions.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.neutral100),
                  itemBuilder: (context, index) {
                    final option = visibleOptions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: option.propertyCode == null
                          ? null
                          : Text(
                              option.propertyCode!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _searchText(String value) {
    return value.trim().toLowerCase();
  }

  void _hidePropertyOptions() {
    if (!_showSocietyOptions && !_showBlockOptions && !_showFlatOptions) {
      return;
    }
    setState(() {
      _showSocietyOptions = false;
      _showBlockOptions = false;
      _showFlatOptions = false;
    });
  }

  Future<void> _loadSocieties([String query = '']) async {
    final token = ++_societyLoadToken;
    setState(() => _isLoadingSocieties = true);
    try {
      final societies =
          await SupabaseRepository.instance.fetchSocieties(query: query);
      if (!mounted || token != _societyLoadToken) return;
      setState(() => _societies = societies);
    } finally {
      if (mounted && token == _societyLoadToken) {
        setState(() => _isLoadingSocieties = false);
      }
    }
  }

  Future<void> _loadBlocks({String query = ''}) async {
    final society = _selectedSociety;
    if (society == null) return;
    final societyId = society.id;
    final token = ++_blockLoadToken;
    setState(() => _isLoadingBlocks = true);
    try {
      final blocks = await SupabaseRepository.instance.fetchBlocks(
        societyId: societyId,
        query: query,
      );
      if (!mounted ||
          token != _blockLoadToken ||
          _selectedSociety?.id != societyId) {
        return;
      }
      setState(() => _blocks = blocks);
    } finally {
      if (mounted &&
          token == _blockLoadToken &&
          _selectedSociety?.id == societyId) {
        setState(() => _isLoadingBlocks = false);
      }
    }
  }

  Future<void> _loadFlats({String query = ''}) async {
    final block = _selectedBlock;
    if (block == null) return;
    final blockId = block.id;
    final token = ++_flatLoadToken;
    setState(() => _isLoadingFlats = true);
    try {
      final flats = await SupabaseRepository.instance.fetchFlats(
        blockId: blockId,
        query: query,
      );
      if (!mounted ||
          token != _flatLoadToken ||
          _selectedBlock?.id != blockId) {
        return;
      }
      setState(() => _flats = flats);
    } finally {
      if (mounted && token == _flatLoadToken && _selectedBlock?.id == blockId) {
        setState(() => _isLoadingFlats = false);
      }
    }
  }

  void _selectSociety(PropertyOption option) {
    setState(() {
      _selectedSociety = option;
      _societyController.text = option.name;
      _selectedBlock = null;
      _selectedFlat = null;
      _blockController.clear();
      _flatController.clear();
      _blocks = const [];
      _flats = const [];
      _showSocietyOptions = false;
      _showBlockOptions = false;
      _showFlatOptions = false;
      _blockLoadToken++;
      _flatLoadToken++;
    });
    _saveStartFlow();
    _loadBlocks();
  }

  void _selectBlock(PropertyOption option) {
    setState(() {
      _selectedBlock = option;
      _blockController.text = option.name;
      _selectedFlat = null;
      _flatController.clear();
      _flats = const [];
      _showBlockOptions = false;
      _showFlatOptions = false;
      _flatLoadToken++;
    });
    _saveStartFlow();
    _loadFlats();
  }

  void _selectFlat(PropertyOption option) {
    setState(() {
      _selectedFlat = option;
      _flatController.text = option.name;
      _showFlatOptions = false;
    });
    _saveStartFlow();
  }

  void _clearSociety() {
    setState(() {
      _selectedSociety = null;
      _selectedBlock = null;
      _selectedFlat = null;
      _societyController.clear();
      _blockController.clear();
      _flatController.clear();
      _blocks = const [];
      _flats = const [];
      _showSocietyOptions = true;
      _showBlockOptions = false;
      _showFlatOptions = false;
      _blockLoadToken++;
      _flatLoadToken++;
    });
    _saveStartFlow();
    _loadSocieties();
  }

  void _clearBlock() {
    setState(() {
      _selectedBlock = null;
      _selectedFlat = null;
      _blockController.clear();
      _flatController.clear();
      _flats = const [];
      _showBlockOptions = true;
      _showFlatOptions = false;
      _flatLoadToken++;
    });
    _saveStartFlow();
    _loadBlocks();
  }

  void _clearFlat() {
    setState(() {
      _selectedFlat = null;
      _flatController.clear();
      _showFlatOptions = true;
    });
    _saveStartFlow();
    _loadFlats();
  }

  void _onSocietySearchChanged(String query) {
    if (_selectedSociety != null && query.trim() != _selectedSociety!.name) {
      setState(() {
        _selectedSociety = null;
        _selectedBlock = null;
        _selectedFlat = null;
        _blockController.clear();
        _flatController.clear();
        _blocks = const [];
        _flats = const [];
        _showSocietyOptions = true;
        _showBlockOptions = false;
        _showFlatOptions = false;
        _blockLoadToken++;
        _flatLoadToken++;
      });
    }
    _loadSocieties(query);
  }

  void _onBlockSearchChanged(String query) {
    if (_selectedBlock != null && query.trim() != _selectedBlock!.name) {
      setState(() {
        _selectedBlock = null;
        _selectedFlat = null;
        _flatController.clear();
        _flats = const [];
        _showBlockOptions = true;
        _showFlatOptions = false;
        _flatLoadToken++;
      });
    }
    _loadBlocks(query: query);
  }

  void _onFlatSearchChanged(String query) {
    if (_selectedFlat != null && query.trim() != _selectedFlat!.name) {
      setState(() {
        _selectedFlat = null;
        _showFlatOptions = true;
      });
    }
    _loadFlats(query: query);
  }

  Future<void> _authenticate() async {
    if (!_canAuthenticate) {
      await _showMessage(
        'Enter login details',
        'Enter your registered mobile number and password to continue.',
      );
      return;
    }
    setState(() => _isAuthenticating = true);
    try {
      final login = await SupabaseRepository.instance.authenticateInspector(
        mobileNumber: _mobileController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _authenticatedInspector = login;
        _mobileController.text = login.phone ?? _mobileController.text;
        _passwordController.clear();
      });
      InspectionSession.inspectorId = login.userId;
      InspectionSession.inspectorName = login.displayName;
      InspectionSession.mobileNumber = login.phone;
      InspectionSession.authToken = login.authToken;
      InspectionSession.lastLoginAt = DateTime.now();
      await InspectionDraftStorage.saveSession();
      await _loadDashboardStats();
      _startDashboardRefresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${login.displayName}')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _isConnectionError(error)
          ? 'Unable to connect. Check your internet connection and try again.'
          : 'The mobile number or password is incorrect. Please check and try again.';
      await _showMessage(
        _isConnectionError(error) ? 'Connection problem' : 'Login failed',
        message,
      );
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      if (_inspectionMode == _InspectionMode.individual) {
        await _startIndividualInspection();
      } else if (_inspectionMode == _InspectionMode.society) {
        await _startSocietyInspection();
      } else {
        await _startFlatInspection();
      }
    } catch (error) {
      if (!mounted) return;
      if (_isExpiredSessionError(error)) {
        await _clearExpiredLogin();
        if (!mounted) return;
        await _showMessage(
          'Login expired',
          'Your login session has expired. Please enter your mobile number and password again.',
        );
        return;
      }
      await _showMessage(
        'Inspection could not start',
        _isConnectionError(error)
            ? 'We could not connect to the server. Check your internet connection and try again.'
            : 'We could not create this inspection. Please try again. If the problem continues, contact support.',
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _attemptStartInspection() async {
    final missing = _missingInspectionDetails();
    if (missing != null) {
      await _showMessage('Cannot start inspection', missing);
      return;
    }
    await _saveStartFlow();
    await _signIn();
  }

  String? _missingInspectionDetails() {
    if (_inspectionMode == null) return 'Select the property type first.';
    if (_inspectionPlan == null) return 'Select an inspection plan first.';
    if (_inspectionMode == _InspectionMode.flat) {
      if (_selectedSociety == null) return 'Select a society to continue.';
      if (_selectedBlock == null) return 'Select a block to continue.';
      if (_selectedFlat == null) return 'Select a flat to continue.';
    } else if (_inspectionMode == _InspectionMode.society) {
      if (_selectedSociety == null) return 'Select a society to continue.';
    } else {
      if (_individualPropertyController.text.trim().length < 2) {
        return 'Enter the property or house name.';
      }
      if (_ownerNameController.text.trim().length < 2) {
        return 'Enter the owner name.';
      }
      final digits = _ownerMobileController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) return 'Enter a valid owner mobile number.';
    }
    return null;
  }

  bool _isConnectionError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('timeout') ||
        text.contains('failed host lookup') ||
        text.contains('connection');
  }

  Future<void> _showMessage(String title, String message) {
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

  bool _isExpiredSessionError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('expired inspector session') ||
        text.contains('invalid or expired') ||
        text.contains('session_token') ||
        text.contains('session token');
  }

  Future<void> _clearExpiredLogin() async {
    InspectionSession.clearInspectorAuth();
    await InspectionDraftStorage.saveSession();
    if (!mounted) return;
    setState(() {
      _authenticatedInspector = null;
      _passwordController.clear();
      _selectedSociety = null;
      _selectedBlock = null;
      _selectedFlat = null;
      _societyController.clear();
      _blockController.clear();
      _flatController.clear();
      _blocks = const [];
      _flats = const [];
      _showSocietyOptions = false;
      _showBlockOptions = false;
      _showFlatOptions = false;
    });
  }

  Future<void> _startFlatInspection() async {
    final authenticatedInspector = _authenticatedInspector;
    if (authenticatedInspector == null ||
        authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }
    await InspectionDraftStorage.clearAreas();
    InspectionSession.beginInspectionScope('flat');
    final login = SupabaseRepository.instance.createInspectorLoginFromSelection(
      authenticatedInspector: authenticatedInspector,
      society: _selectedSociety!,
      block: _selectedBlock!,
      flat: _selectedFlat!,
    );

    InspectionSession.inspectorId = login.userId;
    InspectionSession.inspectorName = login.displayName;
    InspectionSession.mobileNumber = login.phone;
    InspectionSession.authToken = login.authToken;
    InspectionSession.inspectionPlan = _inspectionPlan;
    InspectionSession.inspectionCode = null;
    InspectionSession.propertyOwnerName = null;
    InspectionSession.propertyOwnerMobile = null;

    final property = login.property;
    if (property != null) {
      InspectionSession.profileId = property.profileId;
      InspectionSession.propertyId = property.propertyId;
      InspectionSession.keprId = property.propertyCode;
      InspectionSession.societyName = property.propertyName;
      InspectionSession.flatNumber = property.block;
      final started = await SupabaseRepository.instance.startInspection(
        propertyId: property.propertyId,
        authToken: login.authToken!,
        inspectionType: 'flat',
        title:
            'Flat Inspection - ${property.block ?? property.propertyName ?? property.propertyCode ?? property.propertyId}',
        inspectorName: login.displayName,
      );
      if (started == null || started.inspectionType != 'flat') {
        throw Exception('Database did not create a flat inspection.');
      }
      InspectionSession.inspectionId = started.inspectionId;
      InspectionSession.inspectionCode = started.inspectionCode;
    }
    await InspectionDraftStorage.saveSession();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => property == null
            ? const PropertyDetailsScreen()
            : const InspectionsDashboardScreen(),
      ),
    );
  }

  Future<void> _startSocietyInspection() async {
    final authenticatedInspector = _authenticatedInspector;
    final society = _selectedSociety;
    if (authenticatedInspector == null ||
        authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }
    if (society == null) {
      throw Exception('Please select society.');
    }

    await InspectionDraftStorage.clearAreas();
    InspectionSession.beginInspectionScope('society');
    InspectionSession.inspectorId = authenticatedInspector.userId;
    InspectionSession.inspectorName = authenticatedInspector.displayName;
    InspectionSession.mobileNumber = authenticatedInspector.phone;
    InspectionSession.authToken = authenticatedInspector.authToken;
    InspectionSession.inspectionPlan = _inspectionPlan;
    InspectionSession.inspectionCode = null;
    InspectionSession.profileId = society.id;
    InspectionSession.propertyId = society.id;
    InspectionSession.keprId = society.propertyCode;
    InspectionSession.societyName = society.name;
    InspectionSession.flatNumber = 'Society Inspection';
    InspectionSession.propertyOwnerName = null;
    InspectionSession.propertyOwnerMobile = null;
    final started = await SupabaseRepository.instance.startInspection(
      propertyId: society.id,
      authToken: authenticatedInspector.authToken!,
      inspectionType: 'society',
      title: 'Society Inspection - ${society.name}',
      inspectorName: authenticatedInspector.displayName,
    );
    if (started == null || started.inspectionType != 'society') {
      throw Exception('Database did not create a society inspection.');
    }
    InspectionSession.inspectionId = started.inspectionId;
    InspectionSession.inspectionCode = started.inspectionCode;

    await InspectionDraftStorage.saveSession();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InspectionsDashboardScreen()),
    );
  }

  Future<void> _startIndividualInspection() async {
    final authenticatedInspector = _authenticatedInspector;
    if (authenticatedInspector == null ||
        authenticatedInspector.authToken == null) {
      throw Exception('Please sign in first.');
    }

    final propertyName = _individualPropertyController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final ownerMobile = _ownerMobileController.text.trim();
    if (propertyName.isEmpty || ownerName.isEmpty || ownerMobile.isEmpty) {
      throw Exception(
          'Property name, owner name, and owner mobile are required.');
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final inspectionRef = 'individual-$now';
    final inspectionCode = await SupabaseRepository.instance.nextInspectionCode(
      inspectionType: 'individual',
    );

    await InspectionDraftStorage.clearInspectionDraft();
    InspectionSession.beginInspectionScope('individual');
    InspectionSession.inspectorId = authenticatedInspector.userId;
    InspectionSession.inspectorName = authenticatedInspector.displayName;
    InspectionSession.mobileNumber = authenticatedInspector.phone;
    InspectionSession.authToken = authenticatedInspector.authToken;
    InspectionSession.inspectionPlan = _inspectionPlan;
    InspectionSession.inspectionCode = inspectionCode;
    InspectionSession.propertyId = inspectionRef;
    InspectionSession.inspectionId = inspectionRef;
    InspectionSession.societyName = propertyName;
    InspectionSession.flatNumber = 'Owner: $ownerName';
    InspectionSession.propertyOwnerName = ownerName;
    InspectionSession.propertyOwnerMobile = ownerMobile;
    await InspectionDraftStorage.saveSession();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InspectionsDashboardScreen()),
    );
  }
}
