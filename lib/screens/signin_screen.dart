import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
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
  _InspectionMode _inspectionMode = _InspectionMode.flat;
  String _inspectionPlan = 'free';
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
      _inspectionPlan =
          InspectionSession.inspectionPlan == 'paid' ? 'paid' : 'free';
    } else if ((InspectionSession.authToken ?? '').isNotEmpty) {
      InspectionSession.clearInspectorAuth();
      InspectionDraftStorage.saveSession();
    }
    _loadSocieties();
  }

  @override
  void dispose() {
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

  bool get _supportsFreePaidPlan =>
      _inspectionMode == _InspectionMode.flat ||
      _inspectionMode == _InspectionMode.society;

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
                              enabled: _canAuthenticate,
                              onPressed:
                                  _canAuthenticate ? _authenticate : null,
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
                          if (_supportsFreePaidPlan) ...[
                            const SizedBox(height: 18),
                            _buildInspectionPlanSelector(),
                          ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final cards = [
            Expanded(
              child: _buildModeCard(
                mode: _InspectionMode.flat,
                icon: Icons.apartment_outlined,
                title: 'Flat',
                subtitle: 'Society, block, flat',
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: _buildModeCard(
                mode: _InspectionMode.society,
                icon: Icons.business_outlined,
                title: 'Society',
                subtitle: 'Common areas',
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: _buildModeCard(
                mode: _InspectionMode.individual,
                icon: Icons.person_pin_circle_outlined,
                title: 'Individual',
                subtitle: 'Owner property',
              ),
            ),
          ];
          return Row(children: cards);
        },
      ),
    );
  }

  Widget _buildModeCard({
    required _InspectionMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _inspectionMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() {
          _inspectionMode = mode;
          _inspectionPlan =
              mode == _InspectionMode.individual ? 'paid' : _inspectionPlan;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 88),
          padding:
              EdgeInsets.all(MediaQuery.of(context).size.width < 380 ? 8 : 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.coral : const Color(0xFFE6ECF3),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(248, 95, 90, 0.20),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(selected ? 0.95 : 0.75),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.coral.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.coral.withOpacity(0.35)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 19,
                          color:
                              selected ? AppColors.coral : AppColors.neutral600,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: selected ? 1 : 0,
                        child: const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColors.coral,
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
                      color: selected
                          ? AppColors.neutral700
                          : AppColors.neutral500,
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
      child: Row(
        children: [
          Expanded(
            child: _buildPlanCard(
              plan: 'free',
              title: 'Free',
              subtitle: '50 basic checks',
              icon: Icons.fact_check_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPlanCard(
              plan: 'paid',
              title: 'Paid',
              subtitle: 'Full checklist',
              icon: Icons.workspace_premium_outlined,
            ),
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
      onTap: () => setState(() => _inspectionPlan = plan),
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
        icon: Icons.business_outlined,
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
        onChanged: (_) => setState(() {}),
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
        onChanged: (_) => setState(() {}),
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
        onChanged: (_) => setState(() {}),
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
      _inspectionPlan = 'free';
      _blocks = const [];
      _flats = const [];
      _showSocietyOptions = false;
      _showBlockOptions = false;
      _showFlatOptions = false;
      _blockLoadToken++;
      _flatLoadToken++;
    });
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
    _loadFlats();
  }

  void _selectFlat(PropertyOption option) {
    setState(() {
      _selectedFlat = option;
      _flatController.text = option.name;
      _showFlatOptions = false;
    });
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
    _loadBlocks();
  }

  void _clearFlat() {
    setState(() {
      _selectedFlat = null;
      _flatController.clear();
      _showFlatOptions = true;
    });
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome ${login.displayName}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Login expired. Please enter mobile and password again.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start inspection: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
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
    InspectionSession.inspectionPlan = 'paid';
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
