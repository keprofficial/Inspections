import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/colors.dart';
import '../constants/app_styles.dart';
import '../widgets/kepr_button.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_logo.dart';
import 'create_account_property_details_screen.dart';
import 'inspections_dashboard_screen.dart';
import 'profile_screen.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late TextEditingController _keprIdController;
  late TextEditingController _societyController;
  late TextEditingController _flatController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _keprIdController = TextEditingController();
    _societyController = TextEditingController();
    _flatController = TextEditingController();
  }

  @override
  void dispose() {
    _keprIdController.dispose();
    _societyController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  bool get isComplete =>
      _keprIdController.text.isNotEmpty &&
      _societyController.text.isNotEmpty &&
      _flatController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const KeprBrandMark(height: 34),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card
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
                        // Heading
                        Text(
                          'Enter Flat/house details',
                          style: AppStyles.headlineMd.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Kepr Unique ID
                        Text(
                          'Kepr Unique ID',
                          style:
                              AppStyles.labelMd.copyWith(color: AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _keprIdController,
                          onChanged: (_) => setState(() {}),
                          decoration: AppStyles.buildInputDecoration(
                            hint: 'Enter your unique ID',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Society Name
                        Text(
                          'Society Name',
                          style:
                              AppStyles.labelMd.copyWith(color: AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _societyController,
                          onChanged: (_) => setState(() {}),
                          decoration: AppStyles.buildInputDecoration(
                            hint: 'e.g. Green Valley Apartments',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Flat Number
                        Text(
                          'Flat number / House number',
                          style:
                              AppStyles.labelMd.copyWith(color: AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _flatController,
                          onChanged: (_) => setState(() {}),
                          decoration: AppStyles.buildInputDecoration(
                            hint: 'e.g. B-402',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: KeprButton(
                            label: 'Continue',
                            isLoading: _isSaving,
                            enabled: isComplete,
                            onPressed:
                                isComplete ? _continueToInspection : null,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Divider(color: AppColors.neutral200),
                        const SizedBox(height: 16),

                        // Sign Up Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: AppStyles.bodyMd
                                  .copyWith(color: AppColors.neutral600),
                              children: [
                                TextSpan(
                                  text: 'Create Account',
                                  style: AppStyles.bodyMd.copyWith(
                                    color: AppColors.coral,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateAccountPropertyDetailsScreen(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Bottom Nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeTab: BottomNavTab.home,
              onTabChange: _handleBottomNav,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNav(BottomNavTab tab) {
    if (tab == BottomNavTab.home) return;
    if (tab == BottomNavTab.inspections) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InspectionsDashboardScreen(),
        ),
      );
    }
    if (tab == BottomNavTab.profile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    }
  }

  String? _validateInput(String input, String fieldName) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '$fieldName cannot be empty';
    }
    if (trimmed.length > 255) {
      return '$fieldName cannot exceed 255 characters';
    }
    if (RegExp(r'''[';"\\]''').hasMatch(trimmed) || trimmed.contains('--')) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  Future<bool> _checkNetworkConnection() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<void> _continueToInspection() async {
    final keprIdError = _validateInput(_keprIdController.text, 'Kepr ID');
    final societyError =
        _validateInput(_societyController.text, 'Society Name');
    final flatError = _validateInput(_flatController.text, 'Flat Number');

    if (keprIdError != null || societyError != null || flatError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            keprIdError ?? societyError ?? flatError ?? 'Validation failed',
          ),
        ),
      );
      return;
    }

    final hasNetwork = await _checkNetworkConnection();
    if (!hasNetwork) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await SupabaseRepository.instance.savePropertyDetails(
        fullName: 'Existing User',
        mobileNumber: '',
        societyName: _societyController.text.trim(),
        flatNumber: _flatController.text.trim(),
        keprId: _keprIdController.text.trim(),
      );
      if (saved != null) {
        InspectionSession.profileId = saved.profileId;
        InspectionSession.propertyId = saved.propertyId;
        InspectionSession.inspectionId =
            await SupabaseRepository.instance.startInspection(
          propertyId: saved.propertyId,
          title: 'Annual Audit - ${_flatController.text.trim()}',
        );
      }
      InspectionSession.keprId = _keprIdController.text.trim();
      InspectionSession.societyName = _societyController.text.trim();
      InspectionSession.flatNumber = _flatController.text.trim();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InspectionsDashboardScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save property: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
