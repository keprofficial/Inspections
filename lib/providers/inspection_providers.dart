import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';

// ── Inspection Session ────────────────────────────────────────────────────────

/// Snapshot of the current inspector's identity. Rebuilt when
/// [inspectionSessionProvider.notifier].refresh() is called.
class InspectionSessionState {
  final String? inspectorId;
  final String? inspectorName;
  final String? mobileNumber;
  final String? authToken;
  final DateTime? lastLoginAt;
  final String? inspectionId;
  final String? inspectionMode;
  final String? inspectionPlan;
  final String? societyName;
  final String? flatNumber;
  final bool isActive;

  const InspectionSessionState({
    this.inspectorId,
    this.inspectorName,
    this.mobileNumber,
    this.authToken,
    this.lastLoginAt,
    this.inspectionId,
    this.inspectionMode,
    this.inspectionPlan,
    this.societyName,
    this.flatNumber,
    this.isActive = false,
  });

  factory InspectionSessionState.fromSession() {
    return InspectionSessionState(
      inspectorId:    InspectionSession.inspectorId,
      inspectorName:  InspectionSession.inspectorName,
      mobileNumber:   InspectionSession.mobileNumber,
      authToken:      InspectionSession.authToken,
      lastLoginAt:    InspectionSession.lastLoginAt,
      inspectionId:   InspectionSession.inspectionId,
      inspectionMode: InspectionSession.inspectionMode,
      inspectionPlan: InspectionSession.inspectionPlan,
      societyName:    InspectionSession.societyName,
      flatNumber:     InspectionSession.flatNumber,
      isActive:       InspectionSession.isActive,
    );
  }

  bool get hasFreshSession => InspectionSession.hasFreshInspectorSession;
}

class InspectionSessionNotifier extends StateNotifier<InspectionSessionState> {
  InspectionSessionNotifier()
      : super(InspectionSessionState.fromSession());

  void refresh() => state = InspectionSessionState.fromSession();

  Future<void> persist() async {
    await InspectionDraftStorage.saveSession();
    refresh();
  }

  void clear() {
    InspectionSession.clear();
    state = InspectionSessionState.fromSession();
  }
}

final inspectionSessionProvider =
    StateNotifierProvider<InspectionSessionNotifier, InspectionSessionState>(
  (ref) => InspectionSessionNotifier(),
);

// ── Dashboard Stats ───────────────────────────────────────────────────────────

class DashboardStats {
  final List<SubmittedInspectionReport> reports;
  final bool isLoading;
  final String? error;

  const DashboardStats({
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  int get total => reports.length;

  int get today {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return reports.where((r) => !r.submittedAt.toLocal().isBefore(start)).length;
  }

  int get thisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return reports.where((r) => !r.submittedAt.toLocal().isBefore(weekStart)).length;
  }

  int get thisMonth {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return reports.where((r) => !r.submittedAt.toLocal().isBefore(start)).length;
  }

  List<int> get weeklyDailyCounts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      return reports.where((r) {
        final s = r.submittedAt.toLocal();
        return !s.isBefore(day) && s.isBefore(next);
      }).length;
    });
  }
}

class DashboardStatsNotifier extends StateNotifier<DashboardStats> {
  DashboardStatsNotifier() : super(const DashboardStats());

  Future<void> load({
    String? inspectorId,
    String? inspectorName,
    String? inspectorMobile,
  }) async {
    if (state.isLoading) return;
    state = DashboardStats(reports: state.reports, isLoading: true);
    try {
      final remote = await SupabaseRepository.instance
          .fetchSubmittedInspectionReports(
        inspectorId: inspectorId,
        inspectorName: inspectorName,
        inspectorMobile: inspectorMobile,
        limit: 200,
      );
      remote.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      state = DashboardStats(reports: remote, isLoading: false);
    } catch (e) {
      state = DashboardStats(
        reports: state.reports,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStats>(
  (ref) => DashboardStatsNotifier(),
);
