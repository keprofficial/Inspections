import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum SyncState {
  /// Draft is saved on the device and on Supabase.
  synced,

  /// A save is in flight.
  saving,

  /// Saved on the device only — the server write failed or we are offline.
  localOnly,
}

/// Tracks connectivity and draft-sync state so the UI can tell the inspector
/// whether their work has actually left the device.
///
/// The app previously saved drafts to both SharedPreferences and Supabase with
/// no indication of which succeeded, so a silent server failure only surfaced
/// as a blocking error at final submit.
class SyncStatus {
  SyncStatus._();

  static final SyncStatus instance = SyncStatus._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<SyncState> state = ValueNotifier<SyncState>(
    SyncState.synced,
  );
  final ValueNotifier<DateTime?> lastSavedAt = ValueNotifier<DateTime?>(null);

  StreamSubscription<ConnectivityResult>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final result = await Connectivity().checkConnectivity();
      isOnline.value = result != ConnectivityResult.none;
      _subscription = Connectivity().onConnectivityChanged.listen((result) {
        isOnline.value = result != ConnectivityResult.none;
      });
    } catch (_) {
      // Connectivity detection is a convenience. If the platform refuses,
      // assume online rather than blocking the inspector with a false banner.
      isOnline.value = true;
    }
  }

  void markSaving() => state.value = SyncState.saving;

  void markSynced() {
    state.value = SyncState.synced;
    lastSavedAt.value = DateTime.now();
  }

  void markLocalOnly() {
    state.value = SyncState.localOnly;
    lastSavedAt.value = DateTime.now();
  }

  /// Human-readable "last saved" text for the submit bar.
  String describeLastSaved() {
    final saved = lastSavedAt.value;
    if (saved == null) return 'Not saved yet';
    final elapsed = DateTime.now().difference(saved);
    if (elapsed.inSeconds < 5) return 'Saved just now';
    if (elapsed.inSeconds < 60) return 'Saved ${elapsed.inSeconds}s ago';
    if (elapsed.inMinutes < 60) return 'Saved ${elapsed.inMinutes}m ago';
    return 'Saved ${elapsed.inHours}h ago';
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
