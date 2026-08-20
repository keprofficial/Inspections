import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color palette used for hash-based fallback (12 distinct vivid colors).
// Unrecognised icon names rotate through this list so each area gets a
// unique colour rather than all falling back to the same coral.
// ---------------------------------------------------------------------------
const List<Color> _fallbackColors = [
  Color(0xFF5C6BC0), // indigo
  Color(0xFF26A69A), // teal
  Color(0xFF8D6E63), // brown
  Color(0xFF546E7A), // blue grey
  Color(0xFF7E57C2), // purple
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFFB300), // amber
  Color(0xFFEF5350), // red
  Color(0xFF00ACC1), // cyan dark
  Color(0xFF558B2F), // dark green
  Color(0xFFFF5722), // deep orange
];

// Fallback icon set — mirrors the colour list so each slot feels intentional.
const List<IconData> _fallbackIcons = [
  Icons.home_work_rounded,
  Icons.domain_rounded,
  Icons.meeting_room_rounded,
  Icons.warehouse_rounded,
  Icons.apartment_rounded,
  Icons.business_rounded,
  Icons.grass_rounded,
  Icons.bolt_rounded,
  Icons.build_circle_rounded,
  Icons.water_damage_rounded,
  Icons.park_rounded,
  Icons.foundation_rounded,
];

/// Returns the accent color for an inspection area based on its icon name.
/// Each recognised area type has a distinct vivid color; unrecognised names
/// derive a unique color from a hash so no two unknown areas look the same.
Color iconColorFor(String iconName) {
  switch (iconName.toLowerCase()) {
    // ── Flat / residential areas ───────────────────────────────────────────
    case 'kitchen':
    case 'cooking':
    case 'cook':
      return const Color(0xFFFF7043); // deep orange

    case 'bed':
    case 'bedroom':
    case 'master_bed':
    case 'king_bed':
      return const Color(0xFF7E57C2); // deep purple

    case 'bathroom':
    case 'toilet':
    case 'wc':
    case 'washroom':
      return const Color(0xFF1E88E5); // blue

    case 'weekend':
    case 'living_room':
    case 'lounge':
    case 'hall':
    case 'drawing_room':
      return const Color(0xFF26A69A); // teal

    case 'balcony':
    case 'terrace':
    case 'patio':
    case 'rooftop':
      return const Color(0xFF43A047); // green

    case 'door_front_door':
    case 'door':
    case 'entrance':
    case 'main_entrance':
    case 'lobby':
    case 'corridor':
    case 'passage':
    case 'reception':
      return const Color(0xFF8D6E63); // warm brown

    case 'electrical_services':
    case 'electrical':
    case 'electricity':
    case 'wiring':
    case 'power_room':
    case 'dg_room':
    case 'generator':
    case 'flash_on':
    case 'bolt':
      return const Color(0xFFFFB300); // amber

    case 'inventory_2':
    case 'storage':
    case 'store':
    case 'utility':
    case 'store_room':
    case 'utility_room':
    case 'warehouse':
      return const Color(0xFF78909C); // blue grey

    case 'water_drop':
    case 'water':
    case 'plumbing':
    case 'pipe':
    case 'drain':
    case 'water_tank':
    case 'pump_room':
    case 'sump':
    case 'overhead_tank':
      return const Color(0xFF039BE5); // light blue

    case 'build':
    case 'maintenance':
    case 'repair':
    case 'handyman':
    case 'construction':
      return const Color(0xFFE53935); // red

    case 'roofing':
    case 'roof':
    case 'ceiling':
      return const Color(0xFF3949AB); // indigo

    case 'ac_unit':
    case 'ac':
    case 'hvac':
    case 'air_conditioning':
      return const Color(0xFF00BCD4); // cyan

    case 'local_parking':
    case 'parking':
    case 'garage':
    case 'car_park':
    case 'vehicle_parking':
    case 'directions_car':
      return const Color(0xFF546E7A); // slate

    // ── Society / common areas ─────────────────────────────────────────────
    case 'yard':
    case 'garden':
    case 'outdoor':
    case 'exterior':
    case 'landscape':
    case 'landscaping':
    case 'park':
    case 'nature':
    case 'grass':
      return const Color(0xFF558B2F); // dark green

    case 'fitness_center':
    case 'gym':
    case 'sports':
    case 'sports_tennis':
    case 'sports_basketball':
    case 'sports_soccer':
      return const Color(0xFFFF5722); // deep orange

    case 'security':
    case 'cctv':
    case 'lock':
    case 'fire_extinguisher':
    case 'fire_safety':
    case 'fire_fighting':
      return const Color(0xFFD32F2F); // red dark

    case 'window':
      return const Color(0xFF0288D1); // light blue

    case 'stairs':
    case 'staircase':
    case 'lift':
    case 'elevator':
      return const Color(0xFF5C6BC0); // indigo light

    case 'dining':
    case 'dining_room':
      return const Color(0xFFFF8F00); // amber dark

    case 'pool':
    case 'swimming_pool':
    case 'water_pool':
      return const Color(0xFF0097A7); // dark cyan

    case 'meeting_room':
    case 'community_hall':
    case 'clubhouse':
    case 'club_house':
    case 'conference':
    case 'event_hall':
    case 'banquet':
      return const Color(0xFF6A1B9A); // deep purple

    case 'apartment':
    case 'building':
    case 'society_office':
    case 'office':
    case 'admin_office':
    case 'domain':
    case 'business':
      return const Color(0xFF1565C0); // dark blue

    case 'home_work':
    case 'whole_unit':
    case 'entire_unit':
      return const Color(0xFF00695C); // dark teal

    default:
      // Derive a unique color from a hash of the icon name so that different
      // unrecognised areas each get a visually distinct gradient.
      final idx = iconName.toLowerCase().hashCode.abs() % _fallbackColors.length;
      return _fallbackColors[idx];
  }
}

/// Returns the icon for an inspection area based on its icon name.
IconData iconDataFor(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'kitchen':
    case 'cooking':
    case 'cook':
      return Icons.kitchen_rounded;

    case 'bed':
    case 'bedroom':
    case 'master_bed':
    case 'king_bed':
      return Icons.king_bed_rounded;

    case 'bathroom':
    case 'toilet':
    case 'wc':
    case 'washroom':
      return Icons.bathtub_rounded;

    case 'weekend':
    case 'living_room':
    case 'lounge':
    case 'hall':
    case 'drawing_room':
      return Icons.weekend_rounded;

    case 'balcony':
    case 'terrace':
    case 'patio':
    case 'rooftop':
      return Icons.balcony_rounded;

    case 'door_front_door':
    case 'door':
    case 'entrance':
    case 'main_entrance':
    case 'lobby':
    case 'corridor':
    case 'passage':
    case 'reception':
      return Icons.door_front_door_rounded;

    case 'electrical_services':
    case 'electrical':
    case 'electricity':
    case 'wiring':
    case 'power_room':
    case 'dg_room':
    case 'generator':
    case 'flash_on':
    case 'bolt':
      return Icons.electrical_services_rounded;

    case 'inventory_2':
    case 'storage':
    case 'store':
    case 'utility':
    case 'store_room':
    case 'utility_room':
    case 'warehouse':
      return Icons.inventory_2_rounded;

    case 'water_drop':
    case 'water':
    case 'plumbing':
    case 'pipe':
    case 'drain':
    case 'water_tank':
    case 'pump_room':
    case 'sump':
    case 'overhead_tank':
      return Icons.water_drop_rounded;

    case 'build':
    case 'maintenance':
    case 'repair':
    case 'handyman':
    case 'construction':
      return Icons.handyman_rounded;

    case 'roofing':
    case 'roof':
    case 'ceiling':
      return Icons.roofing_rounded;

    case 'ac_unit':
    case 'ac':
    case 'hvac':
    case 'air_conditioning':
      return Icons.ac_unit_rounded;

    case 'local_parking':
    case 'parking':
    case 'garage':
    case 'car_park':
    case 'vehicle_parking':
    case 'directions_car':
      return Icons.local_parking_rounded;

    case 'yard':
    case 'garden':
    case 'outdoor':
    case 'exterior':
    case 'landscape':
    case 'landscaping':
    case 'park':
    case 'nature':
    case 'grass':
      return Icons.park_rounded;

    case 'fitness_center':
    case 'gym':
    case 'sports':
    case 'sports_tennis':
    case 'sports_basketball':
    case 'sports_soccer':
      return Icons.fitness_center_rounded;

    case 'security':
    case 'cctv':
    case 'lock':
      return Icons.security_rounded;

    case 'fire_extinguisher':
    case 'fire_safety':
    case 'fire_fighting':
      return Icons.fire_extinguisher_rounded;

    case 'window':
      return Icons.window_rounded;

    case 'stairs':
    case 'staircase':
      return Icons.stairs_rounded;

    case 'lift':
    case 'elevator':
      return Icons.elevator_rounded;

    case 'dining':
    case 'dining_room':
      return Icons.dining_rounded;

    case 'pool':
    case 'swimming_pool':
    case 'water_pool':
      return Icons.pool_rounded;

    case 'meeting_room':
    case 'community_hall':
    case 'clubhouse':
    case 'club_house':
    case 'conference':
    case 'event_hall':
    case 'banquet':
      return Icons.meeting_room_rounded;

    case 'apartment':
    case 'building':
    case 'domain':
      return Icons.apartment_rounded;

    case 'society_office':
    case 'office':
    case 'admin_office':
    case 'business':
      return Icons.business_rounded;

    case 'home_work':
    case 'whole_unit':
    case 'entire_unit':
      return Icons.home_work_rounded;

    default:
      // Derive a unique icon from a hash of the name so different unknown
      // areas don't all show the same house silhouette.
      final idx = iconName.toLowerCase().hashCode.abs() % _fallbackIcons.length;
      return _fallbackIcons[idx];
  }
}

/// A colorful gradient icon container matching the Kepr-Homecare service icon style.
/// Pass [colorOverride] to force a specific base color (e.g. AppColors.error for
/// critical/urgent areas) while keeping the area's original icon shape.
Widget areaIconBox(
  String iconName, {
  Color? colorOverride,
  double size = 48,
  double iconSize = 24,
  double radius = 12,
}) {
  final color = colorOverride ?? iconColorFor(iconName);
  final dark = Color.lerp(color, Colors.black, 0.28) ?? color;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, dark],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.38),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Icon(
      iconDataFor(iconName),
      color: Colors.white,
      size: iconSize,
    ),
  );
}

/// Returns a severity color for use in item cards.
Color severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return const Color(0xFFC62828);
    case 'high':
      return const Color(0xFFEF5350);
    case 'medium':
      return const Color(0xFFFFA000);
    case 'low':
      return const Color(0xFF43A047);
    default:
      return const Color(0xFF78909C);
  }
}

/// Returns an icon for a given severity level.
IconData severityIcon(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return Icons.emergency_rounded;
    case 'high':
      return Icons.warning_rounded;
    case 'medium':
      return Icons.info_rounded;
    case 'low':
      return Icons.check_circle_rounded;
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}
