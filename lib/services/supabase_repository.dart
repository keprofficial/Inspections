import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import 'inspection_draft_storage.dart';
import 'inspection_session.dart';

class SavedProperty {
  final String profileId;
  final String propertyId;
  final String? propertyName;
  final String? block;
  final String? propertyCode;
  final String? address;

  const SavedProperty({
    required this.profileId,
    required this.propertyId,
    this.propertyName,
    this.block,
    this.propertyCode,
    this.address,
  });
}

class InspectorLogin {
  final String? userId;
  final String displayName;
  final String? phone;
  final String? authToken;
  final SavedProperty? property;

  const InspectorLogin({
    this.userId,
    required this.displayName,
    this.phone,
    this.authToken,
    this.property,
  });
}

class StartedInspection {
  final String inspectionId;
  final String? inspectionCode;
  final String inspectionType;

  const StartedInspection({
    required this.inspectionId,
    this.inspectionCode,
    required this.inspectionType,
  });
}

class ServiceMatch {
  final String? id;
  final String serviceCode;
  final String name;
  final String? description;
  final double estimatedCost;
  final List<String> materialCodes;
  final bool isCustomQuote;

  const ServiceMatch({
    this.id,
    required this.serviceCode,
    required this.name,
    this.description,
    required this.estimatedCost,
    this.materialCodes = const [],
    this.isCustomQuote = false,
  });

  factory ServiceMatch.fromSelected(InspectionSelectedService value) {
    return ServiceMatch(
      id: value.id,
      serviceCode: value.serviceCode,
      name: value.name,
      estimatedCost: value.estimatedCost,
      materialCodes: value.materialCodes,
      isCustomQuote: value.isCustomQuote,
    );
  }

  InspectionSelectedService toSelected() {
    return InspectionSelectedService(
      id: id,
      serviceCode: serviceCode,
      name: name,
      estimatedCost: estimatedCost,
      materialCodes: materialCodes,
      isCustomQuote: isCustomQuote,
    );
  }
}

class PropertyOption {
  final String id;
  final String name;
  final String? propertyCode;
  final String? address;

  const PropertyOption({
    required this.id,
    required this.name,
    this.propertyCode,
    this.address,
  });

  factory PropertyOption.fromRow(Map<String, dynamic> row) {
    return PropertyOption(
      id: row['id'] as String,
      name: row['name']?.toString() ?? '',
      propertyCode: row['property_code']?.toString(),
      address: row['address']?.toString(),
    );
  }
}

class SupabaseRepository {
  SupabaseRepository._();

  static final SupabaseRepository instance = SupabaseRepository._();
  static const inspectionPhotoBucket = 'inspection-photos';

  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isEnabled => _client != null;

  Future<InspectorLogin> authenticateInspector({
    required String mobileNumber,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
          'Supabase is not configured. Add SUPABASE_PUBLISHABLE_KEY.');
    }

    final response = await client.rpc(
      'inspection_app_login',
      params: {
        'p_payload': {
          'mobile_number': mobileNumber,
          'password': password,
        },
      },
    );

    final data = response as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Invalid mobile number or password.');
    }

    return InspectorLogin(
      userId: data['inspector_id']?.toString(),
      displayName: data['display_name']?.toString() ?? 'Inspector',
      phone: data['mobile_number']?.toString(),
      authToken: data['session_token']?.toString(),
    );
  }

  Future<List<PropertyOption>> fetchSocieties({String query = ''}) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('properties')
        .select('id,name,property_code,address')
        .eq('type', 'society')
        .order('name')
        .limit(100);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PropertyOption.fromRow)
        .where((option) => _matchesOption(option, query))
        .where((option) => option.name.isNotEmpty)
        .take(20)
        .toList();
  }

  Future<List<PropertyOption>> fetchBlocks({
    required String societyId,
    String query = '',
  }) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('properties')
        .select('id,name,property_code,address')
        .eq('type', 'block')
        .eq('parent_property_id', societyId)
        .order('name')
        .limit(100);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PropertyOption.fromRow)
        .where((option) => _matchesOption(option, query))
        .where((option) => option.name.isNotEmpty)
        .take(50)
        .toList();
  }

  Future<List<PropertyOption>> fetchFlats({
    required String blockId,
    String query = '',
  }) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('properties')
        .select('id,name,property_code,address')
        .eq('type', 'flat')
        .eq('parent_property_id', blockId)
        .order('name')
        .limit(200);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PropertyOption.fromRow)
        .where((option) => _matchesOption(option, query))
        .where((option) => option.name.isNotEmpty)
        .take(100)
        .toList();
  }

  bool _matchesOption(PropertyOption option, String query) {
    final trimmed = _searchText(query);
    if (trimmed.isEmpty) return true;
    return _searchText(option.name).contains(trimmed) ||
        _searchText(option.propertyCode ?? '').contains(trimmed);
  }

  String _searchText(String value) {
    return value.trim().toLowerCase();
  }

  Future<List<InspectionAreaTemplate>> fetchChecklistTemplates({
    bool defaultsOnly = false,
    String inspectionKind = 'flat',
    String inspectionPlan = 'paid',
  }) async {
    final client = _client;
    if (client == null) return const [];

    try {
      var templateQuery = client
          .from('inspection_checklist_templates')
          .select('template_key,name,icon_name,sort_order,is_default')
          .eq('is_active', true)
          .eq('inspection_kind', inspectionKind);
      if (defaultsOnly) {
        templateQuery = templateQuery.eq('is_default', true);
      }

      final templateRows = await templateQuery.order('sort_order');
      final templates = (templateRows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (templates.isEmpty) return const [];

      final keys = templates
          .map((row) => row['template_key']?.toString() ?? '')
          .where((key) => key.isNotEmpty)
          .toList(growable: false);
      if (keys.isEmpty) return const [];

      final freePlanItemIds = <String>{};
      final freePlanSortOrder = <String, int>{};
      if (inspectionPlan == 'free') {
        final planRows = await client
            .from('inspection_checklist_plan_items')
            .select('item_id,sort_order')
            .eq('inspection_kind', inspectionKind)
            .eq('plan_key', 'free')
            .eq('is_active', true)
            .order('sort_order');
        for (final row
            in (planRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
          final itemId = row['item_id']?.toString() ?? '';
          if (itemId.isNotEmpty) {
            freePlanItemIds.add(itemId);
            freePlanSortOrder[itemId] =
                int.tryParse(row['sort_order']?.toString() ?? '') ?? 0;
          }
        }
        if (freePlanItemIds.isEmpty) return const [];
      }

      var itemQuery = client
          .from('inspection_checklist_items')
          .select(
            'id,template_key,sort_order,name,category,inspection_type,description,how_to,equipment_needed,severity',
          )
          .eq('is_active', true)
          .inFilter('template_key', keys);
      if (freePlanItemIds.isNotEmpty) {
        itemQuery = itemQuery.inFilter('id', freePlanItemIds.toList());
      }
      final itemRows = await itemQuery.order('sort_order');

      final itemsByTemplate = <String, List<InspectionItem>>{};
      for (final row
          in (itemRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
        final templateKey = row['template_key']?.toString() ?? '';
        if (templateKey.isEmpty) continue;
        itemsByTemplate.putIfAbsent(templateKey, () => []).add(
              InspectionItem(
                id: row['id']?.toString() ?? '',
                name: row['name']?.toString() ?? '',
                category: row['category']?.toString() ?? 'General',
                inspectionType: row['inspection_type']?.toString() ?? '',
                description: row['description']?.toString() ?? '',
                howTo: row['how_to']?.toString() ?? '',
                equipmentNeeded: row['equipment_needed']?.toString() ?? '',
                severity: row['severity']?.toString() ?? 'medium',
                completed: false,
              ),
            );
      }
      if (freePlanSortOrder.isNotEmpty) {
        for (final items in itemsByTemplate.values) {
          items.sort(
            (a, b) => (freePlanSortOrder[a.id] ?? 0)
                .compareTo(freePlanSortOrder[b.id] ?? 0),
          );
        }
      }

      return [
        for (final row in templates)
          InspectionAreaTemplate(
            key: row['template_key']?.toString() ?? '',
            name: row['name']?.toString() ?? '',
            iconName: row['icon_name']?.toString() ?? 'home_work',
            items: itemsByTemplate[row['template_key']?.toString() ?? ''] ??
                const [],
          ),
      ]
          .where((template) =>
              template.key.isNotEmpty &&
              template.name.isNotEmpty &&
              template.items.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<String> fetchChecklistKindForInspectionType({
    required String inspectionType,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }

    final row = await client
        .from('inspection_app_types')
        .select('checklist_kind')
        .eq('inspection_type', inspectionType)
        .eq('is_active', true)
        .maybeSingle();

    final kind = row?['checklist_kind']?.toString();
    if (kind == null || kind.isEmpty) {
      throw Exception(
        'Inspection type "$inspectionType" is not configured in DB.',
      );
    }
    return kind;
  }

  Future<InspectorLogin> signInInspector({
    required String inspectorName,
    required String mobileNumber,
    required String societyName,
    required String blockName,
    required String flatNumber,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
          'Supabase is not configured. Add SUPABASE_PUBLISHABLE_KEY.');
    }

    final normalizedPhone = _normalizePhone(mobileNumber);
    final trimmedName = inspectorName.trim();
    final trimmedSocietyName = societyName.trim();
    final trimmedBlockName = blockName.trim();
    final trimmedFlatNumber = flatNumber.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Inspector name is required.');
    }
    if (normalizedPhone.length < 8) {
      throw Exception('Valid mobile number is required.');
    }
    if (trimmedSocietyName.isEmpty ||
        trimmedBlockName.isEmpty ||
        trimmedFlatNumber.isEmpty) {
      throw Exception('Society, block, and flat number are required.');
    }

    final property = await _findLiveFlat(
      client,
      societyName: trimmedSocietyName,
      blockName: trimmedBlockName,
      flatNumber: trimmedFlatNumber,
    );
    if (property == null) {
      throw Exception(
          'No flat found for $trimmedSocietyName, block $trimmedBlockName, flat $trimmedFlatNumber');
    }

    return InspectorLogin(
      displayName: trimmedName,
      phone: normalizedPhone,
      property: property,
    );
  }

  InspectorLogin createInspectorLoginFromSelection({
    required InspectorLogin authenticatedInspector,
    required PropertyOption society,
    required PropertyOption block,
    required PropertyOption flat,
  }) {
    if (authenticatedInspector.authToken == null ||
        authenticatedInspector.authToken!.isEmpty) {
      throw Exception('Inspector login expired. Please sign in again.');
    }

    return InspectorLogin(
      userId: authenticatedInspector.userId,
      displayName: authenticatedInspector.displayName,
      phone: authenticatedInspector.phone,
      authToken: authenticatedInspector.authToken,
      property: SavedProperty(
        profileId: '',
        propertyId: flat.id,
        propertyName: society.name,
        block: '${block.name} - ${flat.name}',
        propertyCode: flat.propertyCode,
        address: society.address,
      ),
    );
  }

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
      return _findLivePropertyByCode(client, keprId);
    }

    try {
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
        propertyName: societyName,
        block: flatNumber,
        propertyCode: keprId,
        address: address,
      );
    } catch (_) {
      final liveProperty = await _findLivePropertyByCode(client, keprId);
      if (liveProperty != null) return liveProperty;
      rethrow;
    }
  }

  Future<StartedInspection?> startInspection({
    required String propertyId,
    required String title,
    required String authToken,
    String inspectionType = 'flat',
    String? inspectorName,
  }) async {
    final client = _client;
    if (client == null) return null;

    final Object? response;
    try {
      response = await client.rpc(
        'inspection_app_start',
        params: {
          'p_payload': {
            'property_id': propertyId,
            'session_token': authToken,
            'inspection_type': inspectionType,
            'inspector_name': inspectorName ?? 'Kepr Inspector',
            'summary': title,
          },
        },
      );
    } catch (error) {
      throw Exception(
        'Could not start inspection. Run supabase_inspection_rpc.sql in '
        'Supabase SQL Editor first. $error',
      );
    }

    if (response is Map) {
      final data =
          response.map((key, value) => MapEntry(key.toString(), value));
      final inspectionId = data['inspection_id']?.toString();
      if (inspectionId == null || inspectionId.isEmpty) {
        throw Exception('Failed to start inspection: missing ID in response');
      }
      return StartedInspection(
        inspectionId: inspectionId,
        inspectionCode: data['inspection_code']?.toString(),
        inspectionType: data['inspection_type']?.toString() ?? inspectionType,
      );
    }

    final inspectionId = response?.toString();
    if (inspectionId == null || inspectionId.isEmpty) {
      throw Exception('Failed to start inspection: missing ID in response');
    }
    return StartedInspection(
      inspectionId: inspectionId,
      inspectionType: inspectionType,
    );
  }

  Future<String> nextInspectionCode({
    required String inspectionType,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }

    final response = await client.rpc(
      'inspection_app_next_code',
      params: {
        'p_payload': {
          'inspection_type': inspectionType,
        },
      },
    );

    if (response is Map) {
      final code = response['inspection_code']?.toString();
      if (code != null && code.isNotEmpty) return code;
    }

    throw Exception('Could not generate inspection code from DB.');
  }

  Future<void> submitArea({
    required String inspectionId,
    required InspectionArea area,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
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
          'service_code': item.serviceCode,
          'estimated_cost': item.estimatedCost,
          'material_codes': item.materialCodes,
        };
      }).toList();

      if (rows.isNotEmpty) {
        await client
            .from('inspection_results')
            .upsert(rows, onConflict: 'inspection_area_id,item_key');
      }
    } catch (_) {
      // The live partner schema stores reportable findings in inspection_issues
      // instead of per-section inspection_results. Report generation handles it.
    }
  }

  Future<String> saveInspectionPhoto({
    required List<int> bytes,
    required String fileName,
    required String itemId,
    required String itemName,
    String? keprId,
    String? societyName,
    String? flatNumber,
    String? propertyId,
    String? inspectionId,
    String? areaName,
  }) async {
    final client = _client;
    if (client == null) return fileName;
    final uploadBytes = _compressImageForUpload(Uint8List.fromList(bytes));
    final safeAreaName = _safePathPart(areaName ?? 'inspection-area');
    final safeFileName =
        '${DateTime.now().microsecondsSinceEpoch}_${_safePathPart(fileName)}';
    final storagePath = [
      propertyId ?? 'local-property',
      inspectionId ?? 'local-inspection',
      safeAreaName,
      safeFileName,
    ].join('/');
    final fallbackStoragePath = [
      'uploads',
      propertyId ?? 'local-property',
      safeFileName,
    ].join('/');
    var uploadedPath = storagePath;

    try {
      await client.storage.from(inspectionPhotoBucket).uploadBinary(
            storagePath,
            uploadBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
    } catch (error) {
      try {
        uploadedPath = fallbackStoragePath;
        await _uploadWithRest(
          path: fallbackStoragePath,
          bytes: uploadBytes,
          contentType: 'image/jpeg',
        );
      } catch (retryError) {
        throw Exception(
          'Image upload failed for bucket $inspectionPhotoBucket. '
          'Primary error: $error. Retry error: $retryError',
        );
      }
    }

    final photoUrl =
        client.storage.from(inspectionPhotoBucket).getPublicUrl(uploadedPath);

    try {
      await client.from('inspection_photos').insert({
        'auth_user_id': client.auth.currentUser?.id,
        'property_id': propertyId,
        'inspection_id': inspectionId,
        'kepr_id': keprId,
        'society_name': societyName,
        'flat_number': flatNumber,
        'area_name': areaName,
        'item_key': itemId,
        'file_name': safeFileName,
        'mime_type': 'image/jpeg',
        'byte_size': uploadBytes.length,
        'photo_url': photoUrl,
      });
    } catch (_) {
      // Photo evidence URL is stored on inspection_issues.photo_urls. The legacy
      // inspection_photos row is best-effort for older deployments.
    }

    return photoUrl;
  }

  Uint8List _compressImageForUpload(Uint8List bytes) {
    if (bytes.length <= 50 * 1024) return bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    var width = decoded.width > 960 ? 960 : decoded.width;
    var quality = 60;
    Uint8List encoded = bytes;

    while (true) {
      final resized = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;
      encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (encoded.length <= 50 * 1024) return encoded;
      if (quality > 32) {
        quality -= 7;
      } else if (width > 480) {
        width = (width * 0.82).round().clamp(420, width).toInt();
      } else {
        return encoded;
      }
    }
  }

  Future<String> uploadInspectionReportPdf({
    required List<int> bytes,
    required String inspectionId,
    required String inspectionType,
    String? propertyId,
    String? societyName,
  }) async {
    final client = _client;
    if (client == null) return '';

    final safeSociety = _safePathPart(societyName ?? 'property');
    final safeFileName =
        '${DateTime.now().microsecondsSinceEpoch}_kepr_full_report.pdf';
    final storagePath = [
      inspectionType,
      propertyId ?? 'local-property',
      inspectionId,
      'reports',
      safeSociety,
      safeFileName,
    ].join('/');
    final fallbackStoragePath = [
      'reports',
      inspectionType,
      propertyId ?? 'local-property',
      safeFileName,
    ].join('/');
    var uploadedPath = storagePath;

    try {
      await client.storage.from(inspectionPhotoBucket).uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
    } catch (_) {
      uploadedPath = fallbackStoragePath;
      await _uploadWithRest(
        path: fallbackStoragePath,
        bytes: bytes,
        contentType: 'application/pdf',
      );
    }

    return client.storage
        .from(inspectionPhotoBucket)
        .getPublicUrl(uploadedPath);
  }

  Future<void> _uploadWithRest({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    final uri = Uri.parse(
      '${SupabaseConfig.url}/storage/v1/object/$inspectionPhotoBucket/$path',
    );
    final response = await http.post(
      uri,
      headers: {
        'apikey': SupabaseConfig.publishableKey,
        'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
        'Content-Type': contentType,
      },
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'REST upload failed ${response.statusCode}: ${response.body}',
      );
    }
  }

  String _safePathPart(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  Future<SubmitReportResult?> submitReport({
    required String propertyId,
    required String inspectionId,
    required List<InspectionArea> areas,
    required String authToken,
    String? reportPdfUrl,
  }) async {
    final client = _client;
    if (client == null) return null;

    final totalItems =
        areas.fold<int>(0, (sum, area) => sum + area.items.length);
    final completedItems = areas.fold<int>(
      0,
      (sum, area) => sum + area.items.where((item) => item.completed).length,
    );
    final healthScore = _calculateHealthScore(areas);

    try {
      final criticalItems = <MapEntry<InspectionArea, InspectionItem>>[];
      for (final area in areas) {
        for (final item in area.items) {
          final severity = (item.severity ?? '').toLowerCase();
          if (item.completed && severity == 'critical') {
            criticalItems.add(MapEntry(area, item));
          }
        }
      }

      final issueRows = <Map<String, dynamic>>[];
      for (final entry in criticalItems) {
        final area = entry.key;
        final item = entry.value;
        final services = await _resolveServices(client, item);
        final description = [
          area.name,
          item.name,
          if ((item.notes ?? '').trim().isNotEmpty) item.notes!.trim(),
        ].join(' - ');

        for (final service in services) {
          issueRows.add({
            'inspection_id': inspectionId,
            'severity': 'critical',
            'category': service.isCustomQuote ? 'General' : item.category,
            'description': description,
            'photo_urls': item.photoPaths,
            'status': 'open',
            'linked_service_id': service.serviceId,
            'plan_covered': false,
            'resident_approval_needed': true,
            'service_code': service.serviceCode,
            'estimated_cost': service.estimatedCost,
            'is_custom': service.isCustomQuote,
            'custom_title': service.isCustomQuote
                ? '${service.serviceName} - ${item.name}'
                : item.name,
            'issue_ref': _issueRef(
              inspectionId,
              area.templateKey,
              '${item.id}-${service.serviceCode}',
            ),
            'material_codes': service.materialCodes,
          });
        }
      }

      final response = await client.rpc(
        'inspection_app_submit_report',
        params: {
          'p_payload': {
            'inspection_id': inspectionId,
            'session_token': authToken,
            'overall_health_score': healthScore,
            'summary':
                '$completedItems of $totalItems checks complete. Health score $healthScore. ${issueRows.length} critical issues uploaded.',
            'report_pdf_url': reportPdfUrl,
            'issues': issueRows,
          },
        },
      );

      return SubmitReportResult(
        inspectionId: response?.toString() ?? inspectionId,
        criticalIssueRows: issueRows.length,
        criticalItems: criticalItems.length,
        healthScore: healthScore,
        reportPdfUrl: reportPdfUrl,
      );
    } catch (error) {
      final errorText = error.toString();
      if (errorText.contains('character varying(10)')) {
        throw Exception(
          'Could not submit inspection report because the live DB still has '
          'inspection_issues.service_code limited to 10 characters. Run the '
          'latest supabase_inspection_rpc.sql in Supabase SQL Editor, then try '
          'Final Submit again. $error',
        );
      }
      throw Exception(
        'Could not submit inspection report. Run supabase_inspection_rpc.sql '
        'in Supabase SQL Editor first. $error',
      );
    }
  }

  int _calculateHealthScore(List<InspectionArea> areas) {
    var score = 100.0;
    for (final area in areas) {
      for (final item in area.items) {
        if (!item.completed) continue;
        switch ((item.severity ?? '').toLowerCase()) {
          case 'critical':
            score -= 2.5;
            break;
          case 'high':
            score -= 1.5;
            break;
          case 'medium':
            score -= 0.5;
            break;
          case 'low':
            score -= 0.2;
            break;
          default:
            break;
        }
      }
    }
    return score.clamp(0, 100).round();
  }

  Future<void> saveInspectionDraft({
    required List<InspectionArea> areas,
  }) async {
    final client = _client;
    final inspectionId = InspectionSession.inspectionId;
    if (client == null || inspectionId == null) return;

    try {
      await client.rpc(
        'inspection_app_save_draft',
        params: {
          'p_payload': {
            'inspection_id': inspectionId,
            'session_token': InspectionSession.authToken,
            'inspector_id': InspectionSession.inspectorId,
            'areas': areas.map((area) => area.toJson()).toList(),
          },
        },
      );
    } catch (_) {
      // Backend draft persistence is optional until the draft RPC SQL is run.
      // Local cache remains the immediate recovery path.
    }
  }

  Future<List<InspectionArea>?> loadInspectionDraft() async {
    final client = _client;
    final inspectionId = InspectionSession.inspectionId;
    if (client == null || inspectionId == null) return null;

    try {
      final response = await client.rpc(
        'inspection_app_load_draft',
        params: {
          'p_payload': {
            'inspection_id': inspectionId,
            'session_token': InspectionSession.authToken,
            'inspector_id': InspectionSession.inspectorId,
          },
        },
      );
      if (response is! Map) return null;
      final areas = response['areas'];
      if (areas is! List) return null;
      return areas
          .whereType<Map>()
          .map((row) => InspectionArea.fromJson(
                row.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<String?> submitIndividualInspection({
    required String inspectionRef,
    required String inspectionCode,
    String inspectionType = 'individual',
    required List<InspectionArea> areas,
    required String inspectorName,
    required String? inspectorId,
    required String? inspectorMobile,
    required String propertyName,
    required String ownerName,
    required String ownerMobile,
    required String reportPdfUrl,
  }) async {
    final client = _client;
    if (client == null) return null;

    final totalItems =
        areas.fold<int>(0, (sum, area) => sum + area.items.length);
    final completedItems = areas.fold<int>(
      0,
      (sum, area) => sum + area.items.where((item) => item.completed).length,
    );
    final criticalIssues = <Map<String, dynamic>>[];

    for (final area in areas) {
      for (final item in area.items) {
        final severity = (item.severity ?? '').toLowerCase();
        if (!item.completed || severity != 'critical') continue;
        criticalIssues.add({
          'area_name': area.name,
          'item_id': item.id,
          'issue_name': item.name,
          'category': item.category,
          'severity': severity,
          'notes': item.notes,
          'photo_urls': item.photoPaths,
          'service_codes': item.selectedServices
              .map((service) => service.serviceCode)
              .toList(),
          'service_names':
              item.selectedServices.map((service) => service.name).toList(),
          'estimated_cost': item.selectedServices.fold<double>(
            0,
            (sum, service) => sum + service.estimatedCost,
          ),
          'material_codes': item.selectedServices
              .expand((service) => service.materialCodes)
              .toSet()
              .toList(),
        });
      }
    }

    try {
      final response = await client
          .from('individual_inspections')
          .insert({
            'inspection_ref': inspectionRef,
            'inspection_code': inspectionCode,
            'inspection_type': inspectionType,
            'inspector_id': inspectorId,
            'inspector_name': inspectorName,
            'inspector_mobile': inspectorMobile,
            'property_name': propertyName,
            'property_owner_name': ownerName,
            'property_owner_mobile': ownerMobile,
            'report_pdf_url': reportPdfUrl,
            'total_checks': totalItems,
            'completed_checks': completedItems,
            'critical_issue_count': criticalIssues.length,
            'checklist': areas.map((area) => area.toJson()).toList(),
            'critical_issues': criticalIssues,
          })
          .select('id')
          .maybeSingle();
      return response?['id']?.toString();
    } catch (error) {
      throw Exception(
        'Could not save individual inspection. Run '
        'supabase_individual_inspections.sql in Supabase SQL Editor first. '
        '$error',
      );
    }
  }

  Future<List<SubmittedInspectionReport>> fetchSubmittedInspectionReports({
    String? inspectorId,
    String? inspectorName,
    String? inspectorMobile,
    int limit = 50,
  }) async {
    final client = _client;
    if (client == null) return const [];

    final reports = <SubmittedInspectionReport>[];

    try {
      var query = client
          .from('inspections')
          .select(
            'id,title,inspector_name,inspection_type,property_id,inspection_code,submitted_at,created_at,full_report_pdf_url,properties(name,property_code,type)',
          )
          .not('full_report_pdf_url', 'is', null);
      final name = inspectorName?.trim();
      final rows = await query
          .order('submitted_at', ascending: false, nullsFirst: false)
          .limit(limit * 4);
      for (final row in (rows as List<dynamic>).whereType<Map>()) {
        final data = row.map((key, value) => MapEntry(key.toString(), value));
        final url = data['full_report_pdf_url']?.toString() ?? '';
        if (url.isEmpty) continue;
        final rowInspectorName = data['inspector_name']?.toString().trim();
        if (name != null &&
            name.isNotEmpty &&
            rowInspectorName != null &&
            rowInspectorName.isNotEmpty &&
            !_sameInspectorName(rowInspectorName, name)) {
          continue;
        }
        final property = data['properties'];
        final propertyMap = property is Map
            ? property.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{};
        reports.add(
          SubmittedInspectionReport(
            inspectionId: data['id']?.toString() ?? '',
            inspectionType: data['inspection_type']?.toString() ?? 'flat',
            propertyId: data['property_id']?.toString(),
            societyName: propertyMap['name']?.toString() ??
                data['title']?.toString() ??
                'Flat Inspection',
            flatNumber: data['title']?.toString() ?? 'Flat inspection',
            propertyCode: data['inspection_code']?.toString() ??
                propertyMap['property_code']?.toString(),
            reportUrl: url,
            submittedAt: _dateFromDb(data['submitted_at']) ??
                _dateFromDb(data['created_at']) ??
                DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // Older deployments may not expose full_report_pdf_url via REST yet.
    }

    try {
      var query = client.from('individual_inspections').select(
            'id,inspection_ref,inspection_code,inspection_type,inspector_id,inspector_name,inspector_mobile,property_name,property_owner_name,property_owner_mobile,report_pdf_url,submitted_at',
          );
      final id = inspectorId?.trim();
      final mobile = inspectorMobile?.trim();
      final name = inspectorName?.trim();
      if (id != null && id.isNotEmpty) {
        query = query.eq('inspector_id', id);
      } else if (mobile != null && mobile.isNotEmpty) {
        query = query.eq('inspector_mobile', mobile);
      } else if (name != null && name.isNotEmpty) {
        query = query.eq('inspector_name', name);
      }
      final rows = await query
          .order('submitted_at', ascending: false, nullsFirst: false)
          .limit(limit);
      for (final row in (rows as List<dynamic>).whereType<Map>()) {
        final data = row.map((key, value) => MapEntry(key.toString(), value));
        final url = data['report_pdf_url']?.toString() ?? '';
        if (url.isEmpty) continue;
        reports.add(
          SubmittedInspectionReport(
            inspectionId: data['inspection_ref']?.toString() ??
                data['id']?.toString() ??
                '',
            inspectionType: data['inspection_type']?.toString() ?? 'individual',
            propertyId: data['inspection_ref']?.toString(),
            societyName:
                data['property_name']?.toString() ?? 'Individual Inspection',
            flatNumber:
                'Owner: ${data['property_owner_name']?.toString() ?? '-'}',
            propertyCode: data['inspection_code']?.toString() ??
                data['property_owner_mobile']?.toString(),
            reportUrl: url,
            submittedAt: _dateFromDb(data['submitted_at']) ?? DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // Individual inspections table is optional until the SQL setup is run.
    }

    reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return reports.take(limit).toList(growable: false);
  }

  DateTime? _dateFromDb(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool _sameInspectorName(String left, String right) {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalize(left) == normalize(right);
  }

  Future<SavedProperty?> _findLivePropertyByCode(
    SupabaseClient client,
    String keprId,
  ) async {
    final propertyCode = keprId.trim();
    if (propertyCode.isEmpty) return null;

    try {
      final property = await client
          .from('properties')
          .select('id,name,block,property_code,address')
          .eq('property_code', propertyCode)
          .maybeSingle();
      if (property == null) return null;

      final propertyId = property['id'] as String?;
      if (propertyId == null) return null;

      return SavedProperty(
        profileId: '',
        propertyId: propertyId,
        propertyName: property['name'] as String?,
        block: property['block'] as String?,
        propertyCode: property['property_code'] as String?,
        address: property['address'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<SavedProperty?> _findLiveFlat(
    SupabaseClient client, {
    required String societyName,
    required String blockName,
    required String flatNumber,
  }) async {
    try {
      final society = await client
          .from('properties')
          .select('id,name,address,property_code')
          .eq('type', 'society')
          .ilike('name', societyName)
          .limit(1)
          .maybeSingle();
      if (society == null) return null;

      final societyId = society['id'] as String?;
      if (societyId == null) return null;

      final block = await client
          .from('properties')
          .select('id,name,property_code')
          .eq('type', 'block')
          .eq('parent_property_id', societyId)
          .ilike('name', blockName)
          .limit(1)
          .maybeSingle();
      if (block == null) return null;

      final blockId = block['id'] as String?;
      if (blockId == null) return null;

      final flat = await client
          .from('properties')
          .select('id,name,property_code')
          .eq('type', 'flat')
          .eq('parent_property_id', blockId)
          .ilike('name', flatNumber)
          .limit(1)
          .maybeSingle();
      if (flat == null) return null;

      final flatId = flat['id'] as String?;
      if (flatId == null) return null;

      return SavedProperty(
        profileId: '',
        propertyId: flatId,
        propertyName: society['name'] as String?,
        block: '${block['name']} - ${flat['name']}',
        propertyCode: flat['property_code'] as String?,
        address: society['address'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<_ResolvedService>> _resolveServices(
    SupabaseClient client,
    InspectionItem item,
  ) async {
    if (item.selectedServices.isNotEmpty) {
      return item.selectedServices
          .map(
            (service) => _ResolvedService(
              serviceId: service.id,
              serviceCode: _fitServiceCode(service.serviceCode),
              serviceName: service.name,
              estimatedCost: service.estimatedCost,
              materialCodes: service.materialCodes,
              isCustomQuote: service.isCustomQuote,
            ),
          )
          .toList(growable: false);
    }

    if ((item.serviceCode ?? '').trim().isEmpty) {
      return const [];
    }

    final storedCodes = item.serviceCode!
        .split(',')
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false);
    final resolved = <_ResolvedService>[];
    for (final storedCode in storedCodes) {
      try {
        final service = await client
            .from('services')
            .select('id,name,service_code,base_price,base_price_paise')
            .eq('service_code', storedCode)
            .eq('is_active', true)
            .maybeSingle();
        if (service == null) continue;

        final serviceCode = service['service_code'] as String? ?? storedCode;
        final basePrice = _numberAsDouble(service['base_price']);
        final basePricePaise = _numberAsDouble(service['base_price_paise']);
        resolved.add(
          _ResolvedService(
            serviceId: service['id'] as String?,
            serviceCode: _fitServiceCode(serviceCode),
            serviceName: service['name']?.toString() ?? 'Service',
            estimatedCost: basePrice ??
                (basePricePaise == null ? null : basePricePaise / 100) ??
                0,
            materialCodes: const [],
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return resolved;
  }

  Future<List<ServiceMatch>> searchServicesForInspectionItem(
    InspectionItem item,
  ) async {
    final matches = await searchServices(
      query: _serviceSearchText(item),
      limit: 8,
    );
    return matches;
  }

  Future<List<ServiceMatch>> searchServices({
    required String query,
    ServiceMatch? fallback,
    int limit = 20,
  }) async {
    final client = _client;
    if (client == null) {
      return fallback == null ? const [] : [fallback];
    }

    final normalizedQuery = _searchText(query);
    try {
      final rows = await client
          .from('services')
          .select(
            'id,name,description,service_code,base_price,base_price_paise,category,subcategory_name',
          )
          .eq('is_active', true)
          .order('name')
          .limit(250);

      final matches = (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_serviceMatchFromRow)
          .where((service) => service.serviceCode.isNotEmpty)
          .where((service) => _matchesService(service, normalizedQuery))
          .take(limit)
          .toList();

      if (matches.isNotEmpty) return _attachDefaultMaterials(matches);
    } catch (_) {}

    return const [];
  }

  bool _matchesService(ServiceMatch service, String query) {
    if (query.isEmpty) return true;
    return _searchText(service.name).contains(query) ||
        _searchText(service.serviceCode).contains(query) ||
        _searchText(service.description ?? '').contains(query);
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s()-]'), '');
  }

  String _serviceSearchText(InspectionItem item) {
    final terms = [
      item.category,
      item.inspectionType,
      item.name,
    ].join(' ').toLowerCase();

    if (terms.contains('electrical') ||
        terms.contains('switch') ||
        terms.contains('mcb')) {
      return 'electric';
    }
    if (terms.contains('plumb') ||
        terms.contains('leak') ||
        terms.contains('water')) {
      return 'plumb';
    }
    if (terms.contains('clean') || terms.contains('stain')) {
      return 'clean';
    }
    if (terms.contains('carp') ||
        terms.contains('door') ||
        terms.contains('lock')) {
      return 'carp';
    }
    if (terms.contains('pest') || terms.contains('termite')) {
      return 'pest';
    }
    if (terms.contains('paint') ||
        terms.contains('wall') ||
        terms.contains('civil')) {
      return 'paint';
    }
    return item.category.split(' ').first;
  }

  ServiceMatch _serviceMatchFromRow(Map<String, dynamic> row) {
    final basePrice = _numberAsDouble(row['base_price']);
    final basePricePaise = _numberAsDouble(row['base_price_paise']);
    return ServiceMatch(
      id: row['id'] as String?,
      serviceCode: row['service_code']?.toString() ?? '',
      name: row['name']?.toString() ?? 'Service',
      description: row['description']?.toString(),
      estimatedCost:
          basePrice ?? (basePricePaise == null ? 0 : basePricePaise / 100),
    );
  }

  Future<List<ServiceMatch>> _attachDefaultMaterials(
    List<ServiceMatch> services,
  ) async {
    final client = _client;
    if (client == null || services.isEmpty) return services;

    final serviceIds = services
        .map((service) => service.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (serviceIds.isEmpty) return services;

    try {
      final rows = await client
          .from('service_material_defaults')
          .select(
              'service_id,quantity,materials_catalog(material_code,unit_price)')
          .inFilter('service_id', serviceIds)
          .eq('is_included', true)
          .order('sort_order');

      final codesByService = <String, List<String>>{};
      final materialCostByService = <String, double>{};
      for (final row
          in (rows as List<dynamic>).whereType<Map<String, dynamic>>()) {
        final serviceId = row['service_id']?.toString();
        if (serviceId == null || serviceId.isEmpty) continue;
        final material = row['materials_catalog'];
        if (material is! Map) continue;
        final materialCode = material['material_code']?.toString();
        if (materialCode == null || materialCode.isEmpty) continue;
        final quantity = _numberAsDouble(row['quantity']) ?? 1;
        final unitPrice = _numberAsDouble(material['unit_price']) ?? 0;
        codesByService.putIfAbsent(serviceId, () => []).add(materialCode);
        materialCostByService[serviceId] =
            (materialCostByService[serviceId] ?? 0) + (unitPrice * quantity);
      }

      return services.map((service) {
        final serviceId = service.id;
        if (serviceId == null || !codesByService.containsKey(serviceId)) {
          return service;
        }
        return ServiceMatch(
          id: service.id,
          serviceCode: service.serviceCode,
          name: service.name,
          description: service.description,
          estimatedCost:
              service.estimatedCost + (materialCostByService[serviceId] ?? 0),
          materialCodes: codesByService[serviceId] ?? const [],
          isCustomQuote: service.isCustomQuote,
        );
      }).toList(growable: false);
    } catch (_) {
      return services;
    }
  }

  double? _numberAsDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _issueRef(String inspectionId, String areaKey, String itemId) {
    final raw = '$inspectionId-$areaKey-$itemId';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _fitServiceCode(String value) {
    final code = value.trim();
    if (code.length <= 10) return code;
    return code.substring(0, 10);
  }
}

class SubmitReportResult {
  final String inspectionId;
  final int criticalIssueRows;
  final int criticalItems;
  final int healthScore;
  final String? reportPdfUrl;

  const SubmitReportResult({
    required this.inspectionId,
    required this.criticalIssueRows,
    required this.criticalItems,
    required this.healthScore,
    this.reportPdfUrl,
  });
}

class _ResolvedService {
  final String? serviceId;
  final String serviceCode;
  final String serviceName;
  final double estimatedCost;
  final List<String> materialCodes;
  final bool isCustomQuote;

  const _ResolvedService({
    this.serviceId,
    required this.serviceCode,
    required this.serviceName,
    required this.estimatedCost,
    required this.materialCodes,
    this.isCustomQuote = false,
  });
}
