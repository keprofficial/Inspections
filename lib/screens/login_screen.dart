import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_logo.dart';

/// Inspector sign-in. A single-purpose screen — the mode, plan, and property
/// pickers that used to share this file now live in the start-inspection flow.
class LoginScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LoginScreen({Key? key, required this.onAuthenticated})
      : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canAuthenticate =>
      _mobileController.text.trim().length >= 8 &&
      _passwordController.text.isNotEmpty;

  Future<void> _authenticate() async {
    if (!_canAuthenticate || _isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final login = await SupabaseRepository.instance.authenticateInspector(
        mobileNumber: _mobileController.text,
        password: _passwordController.text,
      );
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
      widget.onAuthenticated();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: KeprLogo(size: 84)),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Inspector sign in',
                    textAlign: TextAlign.center,
                    style: AppStyles.headlineMd.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in with your mobile number and password.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMd.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppCard(
                    elevation: AppElevation.raised,
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('Mobile number'),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          onChanged: (_) => setState(() {}),
                          decoration: AppStyles.buildInputDecoration(
                            hint: '9876543210',
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _label('Password'),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _authenticate(),
                          decoration: AppStyles.buildInputDecoration(
                            hint: 'Enter password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        KeprButton(
                          label: 'Sign in',
                          height: AppSizes.minTapTarget,
                          isLoading: _isAuthenticating,
                          enabled: _canAuthenticate && !_isAuthenticating,
                          onPressed: _authenticate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
