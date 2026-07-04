import '../lib/data/inspection_checklist_data.dart';

const _defaultKeys = {
  'main-entrance-door',
  'living-room',
  'master-bedroom',
  'bedroom-2',
  'kitchen',
  'balcony',
  'electrical-panel-mcb-room',
  'water-tank-overhead',
  'loft-storage',
};

void main() {
  final out = StringBuffer()
    ..writeln('-- Generated from lib/data/inspection_checklist_data.dart')
    ..writeln('-- Run supabase_checklist_templates.sql first.')
    ..writeln('begin;')
    ..writeln();

  for (var i = 0; i < inspectionAreaTemplates.length; i++) {
    final template = inspectionAreaTemplates[i];
    out.writeln(
      "insert into public.inspection_checklist_templates "
      "(template_key, name, icon_name, sort_order, is_default, is_active) "
      "values (${_q(template.key)}, ${_q(template.name)}, "
      "${_q(template.iconName)}, $i, ${_defaultKeys.contains(template.key)}, true) "
      "on conflict (template_key) do update set "
      "name = excluded.name, "
      "icon_name = excluded.icon_name, "
      "sort_order = excluded.sort_order, "
      "is_default = excluded.is_default, "
      "is_active = true, "
      "updated_at = now();",
    );

    for (var itemIndex = 0; itemIndex < template.items.length; itemIndex++) {
      final item = template.items[itemIndex];
      out.writeln(
        "insert into public.inspection_checklist_items "
        "(id, template_key, sort_order, name, category, inspection_type, "
        "description, how_to, equipment_needed, severity, is_active) "
        "values (${_q(item.id)}, ${_q(template.key)}, $itemIndex, "
        "${_q(item.name)}, ${_q(item.category)}, ${_q(item.inspectionType)}, "
        "${_q(item.description)}, ${_q(item.howTo)}, "
        "${_q(item.equipmentNeeded)}, ${_q(item.severity ?? 'medium')}, true) "
        "on conflict (id) do update set "
        "template_key = excluded.template_key, "
        "sort_order = excluded.sort_order, "
        "name = excluded.name, "
        "category = excluded.category, "
        "inspection_type = excluded.inspection_type, "
        "description = excluded.description, "
        "how_to = excluded.how_to, "
        "equipment_needed = excluded.equipment_needed, "
        "severity = excluded.severity, "
        "is_active = true, "
        "updated_at = now();",
      );
    }
    out.writeln();
  }

  out
    ..writeln('commit;')
    ..writeln()
    ..writeln('select')
    ..writeln(
        '  (select count(*) from public.inspection_checklist_templates) as templates,')
    ..writeln(
        '  (select count(*) from public.inspection_checklist_items) as items;');

  print(out.toString());
}

String _q(Object? value) {
  if (value == null) return 'null';
  return "'${value.toString().replaceAll("'", "''")}'";
}
