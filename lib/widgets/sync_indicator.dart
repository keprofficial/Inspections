import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../services/sync_status.dart';

/// A small dot in the app bar showing whether the draft has reached the server.
class SyncStatusDot extends StatelessWidget {
  const SyncStatusDot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncStatus.instance.isOnline,
      builder: (context, online, _) {
        return ValueListenableBuilder<SyncState>(
          valueListenable: SyncStatus.instance.state,
          builder: (context, state, __) {
            final (color, label) = _describe(online, state);
            return Tooltip(
              message: label,
              child: Semantics(
                label: 'Sync status: $label',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: state == SyncState.saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  (Color, String) _describe(bool online, SyncState state) {
    if (!online) return (AppColors.warning, 'Offline — saved on this device');
    switch (state) {
      case SyncState.synced:
        return (AppColors.success, 'All work synced');
      case SyncState.saving:
        return (AppColors.info, 'Saving…');
      case SyncState.localOnly:
        return (AppColors.warning, 'Saved on this device only');
    }
  }
}

/// A thin banner shown under the app bar when the browser goes offline.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncStatus.instance.isOnline,
      builder: (context, online, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: online
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  color: const Color(0xFFFEF3C7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 16,
                        color: Color(0xFF92400E),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Offline — your work is saved on this device.',
                          style: AppStyles.labelSm.copyWith(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
