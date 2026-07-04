// Inspection Models
class InspectionArea {
  final String id;
  final String name;
  final String icon;
  final String templateKey;
  final int progress;
  final String status; // 'completed', 'pending', 'in-progress', 'urgent'
  final int issues;
  final int? completed;
  final List<InspectionItem> items;

  const InspectionArea({
    required this.id,
    required this.name,
    required this.icon,
    required this.templateKey,
    required this.progress,
    required this.status,
    required this.issues,
    this.completed,
    this.items = const [],
  });

  factory InspectionArea.fromJson(Map<String, dynamic> json) {
    return InspectionArea(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'home',
      templateKey: json['templateKey']?.toString() ?? '',
      progress: _intFromJson(json['progress']),
      status: json['status']?.toString() ?? 'pending',
      issues: _intFromJson(json['issues']),
      completed:
          json['completed'] == null ? null : _intFromJson(json['completed']),
      items: _listFromJson(json['items'])
          .map(InspectionItem.fromJson)
          .toList(growable: false),
    );
  }

  InspectionArea copyWith({
    String? id,
    String? name,
    String? icon,
    String? templateKey,
    int? progress,
    String? status,
    int? issues,
    int? completed,
    List<InspectionItem>? items,
  }) {
    return InspectionArea(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      templateKey: templateKey ?? this.templateKey,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      issues: issues ?? this.issues,
      completed: completed ?? this.completed,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'templateKey': templateKey,
      'progress': progress,
      'status': status,
      'issues': issues,
      'completed': completed,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class InspectionItem {
  final String id;
  final String name;
  final String category;
  final String inspectionType;
  final String description;
  final String howTo;
  final String equipmentNeeded;
  final String? severity; // 'low', 'medium', 'high', 'critical'
  final bool completed;
  final String? notes;
  final List<String> photoPaths;
  final List<String> photoEvidenceBase64;
  final String? serviceCode;
  final double? estimatedCost;
  final List<String> materialCodes;
  final List<InspectionSelectedService> selectedServices;

  const InspectionItem({
    required this.id,
    required this.name,
    required this.category,
    this.inspectionType = '',
    required this.description,
    this.howTo = '',
    this.equipmentNeeded = '',
    this.severity,
    required this.completed,
    this.notes,
    this.photoPaths = const [],
    this.photoEvidenceBase64 = const [],
    this.serviceCode,
    this.estimatedCost,
    this.materialCodes = const [],
    this.selectedServices = const [],
  });

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      inspectionType: json['inspectionType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      howTo: json['howTo']?.toString() ?? '',
      equipmentNeeded: json['equipmentNeeded']?.toString() ?? '',
      severity: json['severity']?.toString(),
      completed: json['completed'] == true,
      notes: json['notes']?.toString(),
      photoPaths: _stringListFromJson(json['photoPaths']),
      photoEvidenceBase64: _stringListFromJson(json['photoEvidenceBase64']),
      serviceCode: json['serviceCode']?.toString(),
      estimatedCost: _doubleFromJson(json['estimatedCost']),
      materialCodes: _stringListFromJson(json['materialCodes']),
      selectedServices: _listFromJson(json['selectedServices'])
          .map(InspectionSelectedService.fromJson)
          .toList(growable: false),
    );
  }

  InspectionItem copyWith({
    String? id,
    String? name,
    String? category,
    String? inspectionType,
    String? description,
    String? howTo,
    String? equipmentNeeded,
    String? severity,
    bool? completed,
    String? notes,
    List<String>? photoPaths,
    List<String>? photoEvidenceBase64,
    String? serviceCode,
    double? estimatedCost,
    List<String>? materialCodes,
    List<InspectionSelectedService>? selectedServices,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      inspectionType: inspectionType ?? this.inspectionType,
      description: description ?? this.description,
      howTo: howTo ?? this.howTo,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      severity: severity ?? this.severity,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? this.photoPaths,
      photoEvidenceBase64: photoEvidenceBase64 ?? this.photoEvidenceBase64,
      serviceCode: serviceCode ?? this.serviceCode,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      materialCodes: materialCodes ?? this.materialCodes,
      selectedServices: selectedServices ?? this.selectedServices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'inspectionType': inspectionType,
      'description': description,
      'howTo': howTo,
      'equipmentNeeded': equipmentNeeded,
      'severity': severity,
      'completed': completed,
      'notes': notes,
      'photoPaths': photoPaths,
      'photoEvidenceBase64': photoEvidenceBase64,
      'serviceCode': serviceCode,
      'estimatedCost': estimatedCost,
      'materialCodes': materialCodes,
      'selectedServices':
          selectedServices.map((service) => service.toJson()).toList(),
    };
  }
}

class InspectionSelectedService {
  final String? id;
  final String serviceCode;
  final String name;
  final double estimatedCost;
  final List<String> materialCodes;
  final bool isCustomQuote;

  const InspectionSelectedService({
    this.id,
    required this.serviceCode,
    required this.name,
    required this.estimatedCost,
    this.materialCodes = const [],
    this.isCustomQuote = false,
  });

  factory InspectionSelectedService.fromJson(Map<String, dynamic> json) {
    return InspectionSelectedService(
      id: json['id']?.toString(),
      serviceCode: json['serviceCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      estimatedCost: _doubleFromJson(json['estimatedCost']) ?? 0,
      materialCodes: _stringListFromJson(json['materialCodes']),
      isCustomQuote: json['isCustomQuote'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceCode': serviceCode,
      'name': name,
      'estimatedCost': estimatedCost,
      'materialCodes': materialCodes,
      'isCustomQuote': isCustomQuote,
    };
  }
}

List<Map<String, dynamic>> _listFromJson(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }).toList(growable: false);
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _doubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class Villa {
  final String id;
  final String name;
  final String flatNumber;
  final String societyName;
  final int overallProgress;
  final String auditDate;
  final List<InspectionArea> inspectionAreas;

  Villa({
    required this.id,
    required this.name,
    required this.flatNumber,
    required this.societyName,
    required this.overallProgress,
    required this.auditDate,
    required this.inspectionAreas,
  });
}

class Inspector {
  final String id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String? image;
  final int completedAudits;
  final int activeAudits;
  final int complianceRating;
  final bool certified;

  Inspector({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    this.image,
    required this.completedAudits,
    required this.activeAudits,
    required this.complianceRating,
    required this.certified,
  });
}
