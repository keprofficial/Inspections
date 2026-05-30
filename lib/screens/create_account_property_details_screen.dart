import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_logo.dart';
import 'inspections_dashboard_screen.dart';

class CreateAccountPropertyDetailsScreen extends StatefulWidget {
  const CreateAccountPropertyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<CreateAccountPropertyDetailsScreen> createState() =>
      _CreateAccountPropertyDetailsScreenState();
}

class _CreateAccountPropertyDetailsScreenState
    extends State<CreateAccountPropertyDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _societyController;
  late final TextEditingController _flatController;
  late final TextEditingController _keprIdController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _societyController = TextEditingController();
    _flatController = TextEditingController();
    _keprIdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _societyController.dispose();
    _flatController.dispose();
    _keprIdController.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _societyController.text.trim().isNotEmpty &&
      _flatController.text.trim().isNotEmpty &&
      _keprIdController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account &\nProperty Details',
                        textAlign: TextAlign.center,
                        style: AppStyles.headlineMd.copyWith(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Join the community and register your space for\nseamless property management.',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMd.copyWith(
                          color: const Color(0xFF4A2C2C),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _buildPersonalDetailsCard(),
                      const SizedBox(height: 26),
                      _buildPropertyDetailsCard(),
                      const SizedBox(height: 26),
                      _buildLocationCard(),
                      const SizedBox(height: 44),
                      KeprButton(
                        label: 'Create User Account',
                        showArrow: true,
                        height: 58,
                        isLoading: _isSaving,
                        enabled: _isComplete,
                        onPressed: _isComplete ? _createAccount : null,
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          text: 'By clicking create, you agree to our ',
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: AppStyles.bodySm.copyWith(
                                color: AppColors.crimson,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy.',
                              style: AppStyles.bodySm.copyWith(
                                color: AppColors.crimson,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: AppStyles.bodySm.copyWith(
                          color: const Color(0xFF4A2C2C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeTab: BottomNavTab.profile,
              onTabChange: _handleBottomNav,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNav(BottomNavTab tab) {
    if (tab == BottomNavTab.home) {
      Navigator.pop(context);
      return;
    }
    if (tab == BottomNavTab.inspections) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InspectionsDashboardScreen(),
        ),
      );
    }
  }

  Future<void> _createAccount() async {
    setState(() => _isSaving = true);
    try {
      final saved = await SupabaseRepository.instance.savePropertyDetails(
        fullName: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        societyName: _societyController.text.trim(),
        flatNumber: _flatController.text.trim(),
        keprId: _keprIdController.text.trim(),
        address: '123, Wing B, Green Meadows, Mumbai',
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InspectionsDashboardScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create account: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppColors.neutral50,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2B7B4), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              tooltip: 'Back',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.neutral200),
              ),
            ),
            const SizedBox(width: 12),
            const KeprBrandMark(height: 36),
            const Spacer(),
            Text(
              'New property',
              style: AppStyles.labelMd.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return _SectionCard(
      icon: Icons.person_outline,
      title: 'PERSONAL DETAILS',
      children: [
        _buildLabel('Full Name'),
        _buildInput(
          controller: _nameController,
          hint: 'e.g. John Doe',
        ),
        const SizedBox(height: 24),
        _buildLabel('Mobile Number'),
        Row(
          children: [
            Container(
              height: 52,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E7E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+91',
                style: AppStyles.bodyMd.copyWith(
                  color: const Color(0xFF4A4F5C),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInput(
                controller: _phoneController,
                hint: '98765 43210',
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsCard() {
    return _SectionCard(
      icon: Icons.apartment,
      title: 'PROPERTY DETAILS',
      children: [
        _buildLabel('Society Name'),
        _buildInput(
          controller: _societyController,
          hint: 'e.g. Green Meadows Residency',
        ),
        const SizedBox(height: 24),
        _buildLabel('Flat / House Number'),
        _buildInput(
          controller: _flatController,
          hint: 'e.g. A-402',
        ),
        const SizedBox(height: 24),
        _buildLabel('Kepr Unique ID'),
        _buildInput(
          controller: _keprIdController,
          hint: 'KPR-XXXX-XXXX',
          suffixIcon: const Icon(
            Icons.info_outline,
            color: Color(0xFF4A2C2C),
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.shadowSm,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF405070),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'LOCATION\nDETAILS',
                    style: AppStyles.labelMd.copyWith(
                      color: const Color(0xFF263656),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.my_location,
                    color: AppColors.crimson,
                    size: 20,
                  ),
                  label: Text(
                    'Detect\nLocation',
                    textAlign: TextAlign.center,
                    style: AppStyles.labelMd.copyWith(
                      color: AppColors.crimson,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 204,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _MapPreviewPainter(),
                ),
                const Center(
                  child: Icon(
                    Icons.push_pin,
                    color: AppColors.crimson,
                    size: 42,
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF0B6B4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: Color(0xFF5A2626),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '123, Wing B, Green Meadows, Mumbai, ...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodySm.copyWith(
                              color: const Color(0xFF2B1D1D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppStyles.labelMd.copyWith(
          color: const Color(0xFF2B1111),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF0B6B4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF0B6B4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.coral, width: 2),
        ),
        hintStyle: AppStyles.bodyMd.copyWith(
          color: AppColors.neutral500,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF405070), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppStyles.labelMd.copyWith(
                  color: const Color(0xFF263656),
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()..color = const Color(0xFF89D4E7);
    final landPaint = Paint()..color = const Color(0xFFD9F4E5);
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final smallRoadPaint = Paint()
      ..color = const Color(0xFFB6D5CF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, waterPaint);

    final landPath = Path()
      ..moveTo(size.width * 0.42, 0)
      ..cubicTo(size.width * 0.55, size.height * 0.16, size.width * 0.48,
          size.height * 0.42, size.width * 0.62, size.height * 0.56)
      ..cubicTo(size.width * 0.78, size.height * 0.72, size.width * 0.64,
          size.height * 0.9, size.width * 0.74, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(landPath, landPaint);

    final peninsula = Path()
      ..moveTo(size.width * 0.38, 0)
      ..cubicTo(size.width * 0.30, size.height * 0.22, size.width * 0.36,
          size.height * 0.44, size.width * 0.29, size.height * 0.66)
      ..cubicTo(size.width * 0.24, size.height * 0.82, size.width * 0.33,
          size.height * 0.94, size.width * 0.25, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(peninsula, Paint()..color = const Color(0xFFCFECDC));

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.74, size.height * 0.82),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.82),
      Offset(size.width * 0.76, size.height * 0.18),
      smallRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, 0),
      Offset(size.width * 0.4, size.height),
      smallRoadPaint,
    );

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: const TextSpan(
        text: 'Mumbai',
        style: TextStyle(
          color: Color(0xFF48636D),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    )..layout(maxWidth: size.width);
    labelPainter.paint(
      canvas,
      Offset(size.width * 0.45, size.height * 0.44),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
