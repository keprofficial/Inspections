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
  });

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
    );
  }
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
