import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../constants/colors.dart';
import '../constants/app_styles.dart';
import '../widgets/kepr_logo.dart';
import '../widgets/kepr_button.dart';
import 'property_details_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: '+91 98765 43210');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                const KeprLogo(size: 88),
                const SizedBox(height: 36),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.shadowMd,
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      Text(
                        'Welcome back!',
                        style: AppStyles.headlineMd.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: 'New to Kepr? ',
                          style: AppStyles.bodyMd
                              .copyWith(color: AppColors.neutral500),
                          children: [
                            TextSpan(
                              text: 'Sign up for free',
                              style: AppStyles.bodyMd.copyWith(
                                color: AppColors.coral,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone Input
                      Text(
                        'Mobile number',
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        enabled: false,
                        decoration: AppStyles.buildInputDecoration(
                          hint: '+91 98765 43210',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Demo mode: Phone OTP verification disabled. Integrating later.',
                        style: AppStyles.bodySm
                            .copyWith(color: AppColors.neutral500),
                      ),
                      const SizedBox(height: 24),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: KeprButton(
                          label: 'Continue',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PropertyDetailsScreen()),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer
                      Column(
                        children: [
                          Divider(color: AppColors.neutral200),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Terms of Service',
                                  style: AppStyles.labelSm
                                      .copyWith(color: AppColors.coral),
                                ),
                              ),
                              Text(
                                ' • ',
                                style: AppStyles.labelSm
                                    .copyWith(color: AppColors.neutral500),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Privacy Policy',
                                  style: AppStyles.labelSm
                                      .copyWith(color: AppColors.coral),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2026 Kepr Inc. All rights reserved.',
                            style: AppStyles.labelSm
                                .copyWith(color: AppColors.neutral500),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
}
