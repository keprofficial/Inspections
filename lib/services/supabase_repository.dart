import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class SavedProperty {
  final String profileId;
  final String propertyId;

  const SavedProperty({
    required this.profileId,
    required this.propertyId,
  });
}

class SupabaseRepository {
  SupabaseRepository._();

  static final SupabaseRepository instance = SupabaseRepository._();

  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    return Supabase.instance.client;
  }

  bool get isEnabled => _client != null;

  Future<SavedProperty?> savePropertyDetails({
    required String fullName,
    required String mobileNumber,
    required String societyName,
    required String flatNumber,
    required String keprId,
    String? address,
  }) async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) {
      // Development OTP bypass: keep the app usable until phone auth is enabled.
      return null;
    }

    final profile = await client
        .from('profiles')
        .upsert({
          'auth_user_id': user.id,
          'full_name': fullName,
          'mobile_number': mobileNumber,
        }, onConflict: 'auth_user_id')
        .select('id')
        .single();

    final profileId = profile['id'] as String?;
    if (profileId == null) {
      throw Exception('Failed to create profile: missing ID in response');
    }

    final property = await client
        .from('properties')
        .upsert({
          'profile_id': profileId,
          'society_name': societyName,
          'flat_number': flatNumber,
          'kepr_id': keprId,
          'address': address,
        }, onConflict: 'profile_id,kepr_id')
        .select('id')
        .single();

    final propertyId = property['id'] as String?;
    if (propertyId == null) {
      throw Exception('Failed to create property: missing ID in response');
    }

    return SavedProperty(
      profileId: profileId,
      propertyId: propertyId,
    );
  }

  Future<String?> startInspection({
    required String propertyId,
    required String title,
  }) async {
    final client = _client;
    if (client == null) return null;

    final response = await client
        .from('inspections')
        .insert({
          'property_id': propertyId,
          'title': title,
          'status': 'in_progress',
        })
        .select('id')
        .single();

    final inspectionId = response['id'] as String?;
    if (inspectionId == null) {
      throw Exception('Failed to start inspection: missing ID in response');
    }
    return inspectionId;
  }

  Future<void> submitArea({
    required String inspectionId,
    required InspectionArea area,
  }) async {
    final client = _client;
    if (client == null) return;

    final areaResponse = await client
        .from('inspection_areas')
        .upsert({
          'inspection_id': inspectionId,
          'template_key': area.templateKey,
          'name': area.name,
          'status': area.status,
          'progress': area.progress,
        }, onConflict: 'inspection_id,name')
        .select('id')
        .single();

    final areaId = areaResponse['id'] as String?;
    if (areaId == null) {
      throw Exception(
          'Failed to create inspection area: missing ID in response');
    }

    final rows = area.items.map((item) {
      return {
        'inspection_area_id': areaId,
        'item_key': item.id,
        'name': item.name,
        'category': item.category,
        'inspection_type': item.inspectionType,
        'description': item.description,
        'how_to': item.howTo,
        'equipment_needed': item.equipmentNeeded,
        'severity': item.severity,
        'status': item.completed ? 'completed' : 'pending',
        'notes': item.notes,
        'photo_names': item.photoPaths,
      };
    }).toList();

    if (rows.isNotEmpty) {
      await client
          .from('inspection_results')
          .upsert(rows, onConflict: 'inspection_area_id,item_key');
    }
  }

  Future<String> saveInspectionPhoto({
    required List<int> bytes,
    required String fileName,
    required String itemId,
    String? keprId,
    String? societyName,
    String? flatNumber,
    String? propertyId,
    String? inspectionId,
    String? areaName,
  }) async {
    final client = _client;
    if (client == null) return fileName;
    final user = client.auth.currentUser;

    final response = await client
        .from('inspection_photos')
        .insert({
          'auth_user_id': user?.id,
          'property_id': propertyId,
          'inspection_id': inspectionId,
          'kepr_id': keprId,
          'society_name': societyName,
          'flat_number': flatNumber,
          'area_name': areaName,
          'item_key': itemId,
          'file_name': _safePathPart(fileName),
          'mime_type': 'image/jpeg',
          'byte_size': bytes.length,
          'image_base64': base64Encode(bytes),
        })
        .select('id')
        .single();

    return response['id'] as String? ?? fileName;
  }

  String _safePathPart(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<String?> submitReport({
    required String propertyId,
    required String inspectionId,
    required List<InspectionArea> areas,
  }) async {
    final client = _client;
    if (client == null) return null;

    final totalItems =
        areas.fold<int>(0, (sum, area) => sum + area.items.length);
    final completedItems = areas.fold<int>(
      0,
      (sum, area) => sum + area.items.where((item) => item.completed).length,
    );
    final progress =
        totalItems == 0 ? 0 : ((completedItems / totalItems) * 100).round();

    await client.from('inspections').update({
      'status': 'submitted',
      'submitted_at': DateTime.now().toIso8601String(),
      'progress': progress,
    }).eq('id', inspectionId);

    final response = await client
        .from('inspection_reports')
        .upsert({
          'property_id': propertyId,
          'inspection_id': inspectionId,
          'total_items': totalItems,
          'completed_items': completedItems,
          'pending_items': totalItems - completedItems,
          'progress': progress,
        }, onConflict: 'inspection_id')
        .select('id')
        .single();

    final reportId = response['id'] as String?;
    if (reportId == null) {
      throw Exception('Failed to create report: missing ID in response');
    }
    return reportId;
  }
}
