import '../models/models.dart';

class ServiceRecommendation {
  final String serviceCode;
  final String label;
  final double estimatedCost;
  final List<String> materialCodes;

  const ServiceRecommendation({
    required this.serviceCode,
    required this.label,
    required this.estimatedCost,
    this.materialCodes = const [],
  });
}

ServiceRecommendation recommendServiceForItem(InspectionItem item) {
  final haystack = [
    item.category,
    item.inspectionType,
    item.name,
    item.description,
    item.equipmentNeeded,
  ].join(' ').toLowerCase();

  if (_hasAny(haystack, const [
    'electrical',
    'mcb',
    'switch',
    'socket',
    'wiring',
    'earthing',
    'voltage',
    'fan',
    'light',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'ELEC_REPAIR',
      label: 'Electrical repair',
      estimatedCost: 750,
      materialCodes: ['ELEC_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'plumbing',
    'leak',
    'tap',
    'faucet',
    'drain',
    'flush',
    'sink',
    'water',
    'geyser',
    'pipe',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'PLUMB_REPAIR',
      label: 'Plumbing repair',
      estimatedCost: 650,
      materialCodes: ['PLUMB_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'door',
    'lock',
    'hinge',
    'frame',
    'cabinet',
    'cupboard',
    'window',
    'carpentry',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'CARP_REPAIR',
      label: 'Carpentry / lock repair',
      estimatedCost: 700,
      materialCodes: ['CARP_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'appliance',
    'chimney',
    'microwave',
    'refrigerator',
    'fridge',
    'washing machine',
    'ac ',
    'air conditioner',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'APPL_REPAIR',
      label: 'Appliance repair',
      estimatedCost: 899,
      materialCodes: ['APPL_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'pest',
    'termite',
    'cockroach',
    'bed bug',
    'rodent',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'PEST_CONTROL',
      label: 'Pest control',
      estimatedCost: 999,
      materialCodes: ['PEST_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'clean',
    'stain',
    'dust',
    'mold',
    'mould',
    'grime',
    'sanit',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'CLEAN_DEEP',
      label: 'Deep cleaning',
      estimatedCost: 1499,
      materialCodes: ['CLEAN_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'paint',
    'wall',
    'crack',
    'seepage',
    'plaster',
    'tile',
    'floor',
    'civil',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'CIVIL_REPAIR',
      label: 'Civil repair',
      estimatedCost: 1200,
      materialCodes: ['CIVIL_BASIC'],
    );
  }

  if (_hasAny(haystack, const [
    'camera',
    'intercom',
    'doorbell',
    'security',
  ])) {
    return const ServiceRecommendation(
      serviceCode: 'SECURITY_REPAIR',
      label: 'Security device repair',
      estimatedCost: 850,
      materialCodes: ['SECURITY_BASIC'],
    );
  }

  return const ServiceRecommendation(
    serviceCode: 'GENERAL_REPAIR',
    label: 'General repair',
    estimatedCost: 500,
    materialCodes: ['GENERAL_BASIC'],
  );
}

bool _hasAny(String value, List<String> needles) {
  return needles.any(value.contains);
}
