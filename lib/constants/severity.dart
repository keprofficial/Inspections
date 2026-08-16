import 'package:flutter/material.dart';

import 'colors.dart';

/// The single source of truth for how a finding severity looks and what
/// evidence it requires.
///
/// Every screen, badge, and the PDF must resolve severity through this class.
/// Do not use raw `Colors.green` / `Colors.orange` / `Colors.red.shade900`
/// for severity anywhere else.
enum Severity {
  noIssue,
  low,
  medium,
  high,
  critical;

  /// The value persisted in drafts, Supabase, and the PDF. Do not change.
  String get value {
    switch (this) {
      case Severity.noIssue:
        return 'no_issue';
      case Severity.low:
        return 'low';
      case Severity.medium:
        return 'medium';
      case Severity.high:
        return 'high';
      case Severity.critical:
        return 'critical';
    }
  }

  String get label {
    switch (this) {
      case Severity.noIssue:
        return 'No issue';
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
      case Severity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case Severity.noIssue:
        return AppColors.success;
      case Severity.low:
        return const Color(0xFF65A30D);
      case Severity.medium:
        return AppColors.warning;
      case Severity.high:
        return AppColors.error;
      case Severity.critical:
        return AppColors.crimson;
    }
  }

  /// Colour is never the only signal — every severity also carries an icon.
  IconData get icon {
    switch (this) {
      case Severity.noIssue:
        return Icons.check_circle_outline;
      case Severity.low:
        return Icons.info_outline;
      case Severity.medium:
        return Icons.error_outline;
      case Severity.high:
        return Icons.warning_amber_rounded;
      case Severity.critical:
        return Icons.dangerous_outlined;
    }
  }

  /// Photo evidence is compulsory only for high and critical findings.
  /// Capture stays available at every severity.
  bool get requiresPhoto => this == Severity.high || this == Severity.critical;

  /// Technician notes are required for high and critical findings.
  bool get requiresNotes => this == Severity.high || this == Severity.critical;

  /// A service must be selected for critical findings.
  bool get requiresService => this == Severity.critical;

  /// High and critical findings carry a service/cost estimate.
  bool get hasServiceEstimate =>
      this == Severity.high || this == Severity.critical;

  bool get isIssue => this != Severity.noIssue;

  static Severity? fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final severity in Severity.values) {
      if (severity.value == normalized) return severity;
    }
    // Tolerate historical rows that stored 'none' or 'noissue'.
    if (normalized == 'none' || normalized == 'noissue') {
      return Severity.noIssue;
    }
    return null;
  }

  /// The four issue levels, in escalation order. Excludes [Severity.noIssue],
  /// which is presented separately and first because it is the common answer.
  static const List<Severity> issueLevels = [
    Severity.low,
    Severity.medium,
    Severity.high,
    Severity.critical,
  ];
}
