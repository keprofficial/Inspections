import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_logo.dart';
import 'property_details_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final TextEditingController _otpController;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool get _isComplete => _otpController.text.trim().length >= 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: KeprLogo(size: 88)),
              const SizedBox(height: 32),
              Text(
                'Verify mobile number',
                textAlign: TextAlign.center,
                style: AppStyles.headlineMd.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMd.copyWith(color: AppColors.neutral600),
              ),
              const SizedBox(height: 28),
              Text(
                'OTP',
                style: AppStyles.labelMd.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                onChanged: (_) => setState(() {}),
                decoration: AppStyles.buildInputDecoration(
                  hint: '123456',
                ),
              ),
              const SizedBox(height: 20),
              KeprButton(
                label: 'Verify & Continue',
                isLoading: _isVerifying,
                enabled: _isComplete,
                onPressed: _isComplete ? _verifyOtp : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isVerifying ? null : _resendOtp,
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PropertyDetailsScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resend OTP: $error')),
      );
    }
  }
}
