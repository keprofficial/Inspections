import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import '../widgets/kepr_button.dart';

/// Add / customise / re-map inspection areas.
///
/// Lifted out of the dashboard widget unchanged in behaviour: the three modes
/// (add from template, custom area + check, modify existing mapping) and the
/// ad-hoc custom-check sheet all work exactly as before.
class AreaManagerSheet {
  AreaManagerSheet._();

  /// Ad-hoc plans build their own checklist, so they get the simpler sheet.
  static Future<List<InspectionArea>?> showAdhoc(
    BuildContext context, {
    required List<InspectionArea> areas,
  }) {
    final areaController = TextEditingController();
    final checkController = TextEditingController();

    return showModalBottomSheet<List<InspectionArea>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetTitle(sheetContext, 'Add custom inspection'),
            const SizedBox(height: AppSpacing.lg),
            _label('Area name'),
            TextField(
              controller: areaController,
              decoration: AppStyles.buildInputDecoration(
                hint: 'e.g. Utility Room, Terrace, Store Room',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Inspection check'),
            TextField(
              controller: checkController,
              minLines: 2,
              maxLines: 4,
              decoration: AppStyles.buildInputDecoration(
                hint: 'Describe the custom check',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            KeprButton(
              label: 'Add custom inspection',
              height: AppSizes.minTapTarget,
              width: double.infinity,
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                final areaName = areaController.text.trim();
                final checkName = checkController.text.trim();
                if (areaName.isEmpty || checkName.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Enter both area name and inspection check.'),
                    ),
                  );
                  return;
                }
                final key = 'adhoc-${DateTime.now().millisecondsSinceEpoch}';
                final item = InspectionItem(
                  id: '$key-1',
                  name: checkName,
                  category: 'Adhoc Inspection',
                  inspectionType: 'Custom Check',
                  description: 'Inspector-defined check for $areaName.',
                  howTo: 'Source: Adhoc inspector checklist',
                  equipmentNeeded: 'Manual check, device camera',
                  severity: 'medium',
                  completed: false,
                );
                final newArea = InspectionArea(
                  id: 'area-$key',
                  name: areaName,
                  icon: 'build',
                  templateKey: key,
                  progress: 0,
                  status: 'pending',
                  issues: 1,
                  completed: 0,
                  items: [item],
                );
                Navigator.pop(sheetContext, [...areas, newArea]);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// The standard sheet: add from a DB template, build a custom area, or
  /// re-map an existing area to a different template.
  static Future<List<InspectionArea>?> show(
    BuildContext context, {
    required List<InspectionArea> areas,
    required List<InspectionAreaTemplate> templates,
  }) {
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No DB checklist templates available. Run checklist SQL setup '
            'first.',
          ),
        ),
      );
      return Future.value(null);
    }

    final nameController = TextEditingController();
    final customAreaController = TextEditingController();
    final customInspectionController = TextEditingController();
    final editNameController = TextEditingController();

    InspectionAreaTemplate selectedTemplate = templates.first;
    InspectionAreaTemplate editTemplate = templates.first;
    InspectionArea? selectedArea = areas.isEmpty ? null : areas.first;
    var mode = 'add';

    final initialArea = selectedArea;
    if (initialArea != null) {
      editNameController.text = initialArea.name;
      editTemplate = templates.firstWhere(
        (template) => template.key == initialArea.templateKey,
        orElse: () => templates.first,
      );
    }

    return showModalBottomSheet<List<InspectionArea>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetTitle(sheetContext, 'Manage inspection areas'),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'add',
                        icon: Icon(Icons.add_home_work_outlined),
                        label: Text('Add'),
                      ),
                      ButtonSegment(
                        value: 'custom',
                        icon: Icon(Icons.playlist_add_check),
                        label: Text('Custom'),
                      ),
                      ButtonSegment(
                        value: 'modify',
                        icon: Icon(Icons.tune),
                        label: Text('Modify'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setSheetState(() => mode = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (mode == 'add') ...[
                    _label('Area type mapping'),
                    DropdownButtonFormField<InspectionAreaTemplate>(
                      value: selectedTemplate,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final template in templates)
                          DropdownMenuItem(
                            value: template,
                            child: Text(template.name),
                          ),
                      ],
                      onChanged: (template) {
                        if (template == null) return;
                        setSheetState(() {
                          selectedTemplate = template;
                          if (nameController.text.trim().isEmpty) {
                            nameController.text = template.name;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _label('Display name'),
                    TextField(
                      controller: nameController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Bedroom 3, Hall, Extra Balcony',
                      ),
                    ),
                  ] else if (mode == 'custom') ...[
                    _label('Custom area name'),
                    TextField(
                      controller: customAreaController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Utility Room, Store Room, Office',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _label('Custom inspection check'),
                    TextField(
                      controller: customInspectionController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'e.g. Check false ceiling access panel',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This creates a custom inspection area with your check '
                      'and the standard wall dampness check.',
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ] else ...[
                    _label('Existing area'),
                    DropdownButtonFormField<InspectionArea>(
                      value: selectedArea,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final area in areas)
                          DropdownMenuItem(
                            value: area,
                            child: Text(area.name),
                          ),
                      ],
                      onChanged: (area) {
                        if (area == null) return;
                        setSheetState(() {
                          selectedArea = area;
                          editNameController.text = area.name;
                          editTemplate = templates.firstWhere(
                            (template) => template.key == area.templateKey,
                            orElse: () => templates.first,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _label('New display name'),
                    TextField(
                      controller: editNameController,
                      decoration: AppStyles.buildInputDecoration(
                        hint: 'Display name',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _label('Template mapping'),
                    DropdownButtonFormField<InspectionAreaTemplate>(
                      value: editTemplate,
                      isExpanded: true,
                      decoration: AppStyles.buildInputDecoration(),
                      items: [
                        for (final template in templates)
                          DropdownMenuItem(
                            value: template,
                            child: Text(template.name),
                          ),
                      ],
                      onChanged: (template) {
                        if (template == null) return;
                        setSheetState(() => editTemplate = template);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Changing mapping replaces this area checklist with the '
                      'selected template.',
                      style: AppStyles.bodySm.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  KeprButton(
                    label: mode == 'modify'
                        ? 'Update mapping'
                        : mode == 'custom'
                            ? 'Add custom inspection'
                            : 'Add area',
                    height: AppSizes.minTapTarget,
                    width: double.infinity,
                    icon: Icon(
                      mode == 'modify' ? Icons.check : Icons.add,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final result = _apply(
                        mode: mode,
                        areas: areas,
                        selectedArea: selectedArea,
                        selectedTemplate: selectedTemplate,
                        editTemplate: editTemplate,
                        nameController: nameController,
                        editNameController: editNameController,
                        customAreaController: customAreaController,
                        customInspectionController: customInspectionController,
                      );
                      if (result == null) return;
                      Navigator.pop(sheetContext, result);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static List<InspectionArea>? _apply({
    required String mode,
    required List<InspectionArea> areas,
    required InspectionArea? selectedArea,
    required InspectionAreaTemplate selectedTemplate,
    required InspectionAreaTemplate editTemplate,
    required TextEditingController nameController,
    required TextEditingController editNameController,
    required TextEditingController customAreaController,
    required TextEditingController customInspectionController,
  }) {
    if (mode == 'modify') {
      final area = selectedArea;
      if (area == null) return null;
      final displayName = editNameController.text.trim().isEmpty
          ? area.name
          : editNameController.text.trim();
      final mappingChanged = area.templateKey != editTemplate.key;
      final mappedItems = mappingChanged
          ? inspectionItemsForTemplate(editTemplate)
          : area.items;
      final updated = area.copyWith(
        name: displayName,
        icon: editTemplate.iconName,
        templateKey: editTemplate.key,
        issues: mappedItems.length,
        completed: mappingChanged ? 0 : area.completed,
        progress: mappingChanged ? 0 : area.progress,
        status: mappingChanged ? 'pending' : area.status,
        items: mappedItems,
      );
      return areas
          .map((candidate) => candidate.id == area.id ? updated : candidate)
          .toList(growable: false);
    }

    if (mode == 'custom') {
      final displayName = customAreaController.text.trim().isEmpty
          ? 'Custom Inspection'
          : customAreaController.text.trim();
      final inspectionName = customInspectionController.text.trim().isEmpty
          ? 'Custom inspection check'
          : customInspectionController.text.trim();
      final key = 'custom-${DateTime.now().millisecondsSinceEpoch}';
      final customTemplate = InspectionAreaTemplate(
        key: key,
        name: displayName,
        iconName: 'build',
        items: [
          InspectionItem(
            id: '$key-1',
            name: inspectionName,
            category: 'Custom Inspection',
            inspectionType: 'Custom Check',
            description: 'Inspector-defined inspection check for $displayName.',
            howTo: 'Source: Inspector custom inspection',
            equipmentNeeded: 'Manual check, device camera',
            severity: 'medium',
            completed: false,
          ),
        ],
      );
      final templateItems = inspectionItemsForTemplate(customTemplate);
      return [
        ...areas,
        InspectionArea(
          id: 'area-$key',
          name: displayName,
          icon: customTemplate.iconName,
          templateKey: customTemplate.key,
          progress: 0,
          status: 'pending',
          issues: templateItems.length,
          completed: 0,
          items: templateItems,
        ),
      ];
    }

    final displayName = nameController.text.trim().isEmpty
        ? selectedTemplate.name
        : nameController.text.trim();
    final templateItems = inspectionItemsForTemplate(selectedTemplate);
    return [
      ...areas,
      InspectionArea(
        id: 'area-${selectedTemplate.key}-'
            '${DateTime.now().millisecondsSinceEpoch}',
        name: displayName,
        icon: selectedTemplate.iconName,
        templateKey: selectedTemplate.key,
        progress: 0,
        status: 'pending',
        issues: templateItems.length,
        completed: 0,
        items: templateItems,
      ),
    ];
  }

  static Widget _sheetTitle(BuildContext context, String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppStyles.headlineMd.copyWith(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  static Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppStyles.labelMd.copyWith(color: AppColors.navy),
      ),
    );
  }
}
