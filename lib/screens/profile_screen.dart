import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/app_styles.dart';
import '../widgets/kepr_header.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/badge.dart';
import '../services/inspection_session.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(BottomNavTab)? onTabChange;

  const ProfileScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: const KeprHeader(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Column(
                      children: [
                        // Red Background
                        Container(
                          height: 80,
                          color: AppColors.crimson,
                        ),
                        // Avatar
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: const Center(
                              child: Text(
                                'AR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name & Title
                        Text(
                          'Alex Rivera',
                          style: AppStyles.headlineMd.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lead Safety Inspector',
                          style: AppStyles.bodyMd
                              .copyWith(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 12),
                        // Badges
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: const [
                            AppBadge(
                                label: 'Certified',
                                variant: BadgeVariant.success),
                            AppBadge(
                                label: 'Active', variant: BadgeVariant.info),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Activity Summary
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVITY SUMMARY',
                          style: AppStyles.labelSm
                              .copyWith(color: AppColors.neutral500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      '48',
                                      style: AppStyles.displayLg.copyWith(
                                        fontSize: 32,
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completed',
                                      style: AppStyles.bodySm.copyWith(
                                        color: AppColors.neutral600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      '3',
                                      style: AppStyles.displayLg.copyWith(
                                        fontSize: 32,
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Active Audits',
                                      style: AppStyles.bodySm.copyWith(
                                        color: AppColors.neutral600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compliance Rating',
                                    style: AppStyles.labelMd.copyWith(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '98%',
                                    style: AppStyles.displayLg.copyWith(
                                      fontSize: 24,
                                      color: AppColors.coral,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified,
                                    color: AppColors.coral,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personal Details
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Personal Details',
                              style: AppStyles.labelMd.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  const Icon(Icons.edit,
                                      size: 16, color: AppColors.coral),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: AppStyles.labelSm
                                        .copyWith(color: AppColors.coral),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailField('Full Name', 'Alex Rivera'),
                        const SizedBox(height: 16),
                        _buildDetailField('Username', '@arivera'),
                        const SizedBox(height: 16),
                        _buildDetailField('Mobile Number', '+1 (555) 000-0000'),
                        const SizedBox(height: 16),
                        _buildDetailField(
                            'Email Address', 'alex.rivera@kepr.io'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings & Preferences
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neutral200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Settings & Preferences',
                            style: AppStyles.labelMd.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildSettingItem(
                          Icons.notifications,
                          'Notification Settings',
                          'Manage push and email alerts',
                        ),
                        Divider(color: AppColors.neutral200, height: 0),
                        _buildSettingItem(
                          Icons.security,
                          'Privacy & Security',
                          'Update password and 2FA',
                        ),
                        Divider(color: AppColors.neutral200, height: 0),
                        _buildSettingItem(
                          Icons.help,
                          'Support & Feedback',
                          'Contact help center',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  GestureDetector(
                    onTap: () {
                      InspectionSession.clear();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: AppColors.coral),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: AppStyles.labelMd
                                .copyWith(color: AppColors.coral),
                          ),
                        ],
                      ),
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
              activeTab: BottomNavTab.profile,
              onTabChange: (tab) {
                if (tab != BottomNavTab.profile) {
                  widget.onTabChange?.call(tab);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.labelSm.copyWith(
            color: AppColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.bodyMd.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.neutral400, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyles.bodySm
                          .copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
