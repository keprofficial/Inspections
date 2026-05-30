import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/colors.dart';
import '../constants/app_styles.dart';
import '../widgets/kepr_logo.dart';
import '../widgets/kepr_button.dart';
import 'property_details_screen.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Alex Rivera');
    _usernameController = TextEditingController(text: '@arivera');
    _phoneController = TextEditingController(text: '+91 ');
    _passwordController = TextEditingController(text: 'password123');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              const KeprLogo(size: 88),
              const SizedBox(height: 28),

              // Heading
              Text(
                'Create an account',
                style: AppStyles.headlineMd.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join the future of professional efficiency.',
                style: AppStyles.bodyMd.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Form Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neutral200),
                  boxShadow: AppColors.shadowSm,
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      Text(
                        'Full name',
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: AppStyles.buildInputDecoration(
                          hint: 'Alex Rivera',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username
                      Text(
                        'Username',
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: AppStyles.buildInputDecoration(
                          hint: '@arivera',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number
                      Text(
                        'Mobile number',
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() {}),
                        decoration: AppStyles.buildInputDecoration(
                          hint: '+91 98765 43210',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      Text(
                        'Password',
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: AppStyles.buildInputDecoration(
                          hint: '********',
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.neutral400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Terms Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) =>
                                setState(() => _agreedToTerms = value ?? false),
                            activeColor: AppColors.coral,
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: AppStyles.bodySm
                                    .copyWith(color: AppColors.neutral700),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: AppStyles.bodySm
                                        .copyWith(color: AppColors.coral),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: AppStyles.bodySm
                                        .copyWith(color: AppColors.neutral700),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppStyles.bodySm
                                        .copyWith(color: AppColors.coral),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: AppStyles.bodySm
                                        .copyWith(color: AppColors.neutral700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                child: KeprButton(
                  label: 'Create Account',
                  showArrow: true,
                  isLoading: _isSendingOtp,
                  enabled: _agreedToTerms &&
                      _phoneController.text.trim().length >= 8,
                  onPressed: _createAccount,
                ),
              ),
              const SizedBox(height: 32),

              // Sign In Link
              RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: AppStyles.bodyMd.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    final phone = _normalizePhone(_phoneController.text);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter mobile number with country code.')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    // TODO: Re-enable Supabase phone OTP after SMS provider setup is complete.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSendingOtp = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PropertyDetailsScreen()),
    );
  }

  String? _normalizePhone(String raw) {
    final compact = raw.replaceAll(RegExp(r'[\s()-]'), '');
    if (!compact.startsWith('+') || compact.length < 8) return null;
    return compact;
  }
}
