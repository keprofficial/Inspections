import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'inspection_session.dart';

class InspectionDraftStorage {
  InspectionDraftStorage._();

  static const _sessionKey = 'kepr.inspection.session.v1';
  static const _areasKey = 'kepr.inspection.areas.v1';
  static const _submittedReportsKey = 'kepr.inspection.submitted_reports.v1';

  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      InspectionSession.profileId = data['profileId']?.toString();
      InspectionSession.propertyId = data['propertyId']?.toString();
      InspectionSession.inspectionId = data['inspectionId']?.toString();
      InspectionSession.inspectionCode = data['inspectionCode']?.toString();
      InspectionSession.keprId = data['keprId']?.toString();
      InspectionSession.societyName = data['societyName']?.toString();
      InspectionSession.flatNumber = data['flatNumber']?.toString();
      InspectionSession.inspectorId = data['inspectorId']?.toString();
      InspectionSession.inspectorName = data['inspectorName']?.toString();
      InspectionSession.mobileNumber = data['mobileNumber']?.toString();
      InspectionSession.authToken = data['authToken']?.toString();
      InspectionSession.inspectionMode = data['inspectionMode']?.toString();
      InspectionSession.propertyOwnerName =
          data['propertyOwnerName']?.toString();
      InspectionSession.propertyOwnerMobile =
          data['propertyOwnerMobile']?.toString();
      final lastLoginRaw = data['lastLoginAt']?.toString();
      InspectionSession.lastLoginAt =
          lastLoginRaw == null ? null : DateTime.tryParse(lastLoginRaw);
    } catch (_) {
      await prefs.remove(_sessionKey);
    }
  }

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'profileId': InspectionSession.profileId,
        'propertyId': InspectionSession.propertyId,
        'inspectionId': InspectionSession.inspectionId,
        'inspectionCode': InspectionSession.inspectionCode,
        'keprId': InspectionSession.keprId,
        'societyName': InspectionSession.societyName,
        'flatNumber': InspectionSession.flatNumber,
        'inspectorId': InspectionSession.inspectorId,
        'inspectorName': InspectionSession.inspectorName,
        'mobileNumber': InspectionSession.mobileNumber,
        'authToken': InspectionSession.authToken,
        'inspectionMode': InspectionSession.inspectionMode,
        'propertyOwnerName': InspectionSession.propertyOwnerName,
        'propertyOwnerMobile': InspectionSession.propertyOwnerMobile,
        'lastLoginAt': InspectionSession.lastLoginAt?.toIso8601String(),
      }),
    );
  }

  static Future<List<InspectionArea>?> loadAreas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_areasKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .whereType<Map>()
          .map((row) => InspectionArea.fromJson(
                row.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList(growable: false);
    } catch (_) {
      await prefs.remove(_areasKey);
      return null;
    }
  }

  static Future<void> saveAreas(List<InspectionArea> areas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _areasKey,
      jsonEncode(areas.map((area) => area.toJson()).toList()),
    );
  }

  static Future<void> saveArea(InspectionArea area) async {
    final areas = await loadAreas();
    if (areas == null) return;

    final updated = areas.map((current) {
      return current.id == area.id ? area : current;
    }).toList(growable: false);
    await saveAreas(updated);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_areasKey);
    await prefs.remove(_submittedReportsKey);
  }

  static Future<void> clearAreas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_areasKey);
  }

  static Future<void> clearInspectionDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_areasKey);
    InspectionSession.clearInspection();
    await saveSession();
  }

  static Future<void> saveSubmittedReport(
    SubmittedInspectionReport report,
  ) async {
    final reports = await loadSubmittedReports();
    final updated = [
      report,
      ...reports.where((item) => item.inspectionId != report.inspectionId),
    ].take(25).toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _submittedReportsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<SubmittedInspectionReport>> loadSubmittedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_submittedReportsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .whereType<Map>()
          .map((row) => SubmittedInspectionReport.fromJson(
                row.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList(growable: false);
    } catch (_) {
      await prefs.remove(_submittedReportsKey);
      return const [];
    }
  }
}

class SubmittedInspectionReport {
  final String inspectionId;
  final String? inspectionType;
  final String? propertyId;
  final String societyName;
  final String flatNumber;
  final String? propertyCode;
  final String reportUrl;
  final DateTime submittedAt;

  const SubmittedInspectionReport({
    required this.inspectionId,
    this.inspectionType,
    this.propertyId,
    required this.societyName,
    required this.flatNumber,
    this.propertyCode,
    required this.reportUrl,
    required this.submittedAt,
  });

  factory SubmittedInspectionReport.fromJson(Map<String, dynamic> json) {
    return SubmittedInspectionReport(
      inspectionId: json['inspectionId']?.toString() ?? '',
      inspectionType: json['inspectionType']?.toString(),
      propertyId: json['propertyId']?.toString(),
      societyName: json['societyName']?.toString() ?? '-',
      flatNumber: json['flatNumber']?.toString() ?? '-',
      propertyCode: json['propertyCode']?.toString(),
      reportUrl: json['reportUrl']?.toString() ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspectionId': inspectionId,
      'inspectionType': inspectionType,
      'propertyId': propertyId,
      'societyName': societyName,
      'flatNumber': flatNumber,
      'propertyCode': propertyCode,
      'reportUrl': reportUrl,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}
