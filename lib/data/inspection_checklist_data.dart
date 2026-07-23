import '../models/models.dart';

class InspectionAreaTemplate {
  final String key;
  final String name;
  final String iconName;
  final List<InspectionItem> items;
  const InspectionAreaTemplate(
      {required this.key,
      required this.name,
      required this.iconName,
      required this.items});
}

const List<InspectionAreaTemplate> inspectionAreaTemplates = [
  InspectionAreaTemplate(
      key: 'main-entrance-door',
      name: 'Main Entrance Door',
      iconName: 'door_front_door',
      items: [
        InspectionItem(
          id: 'main-entrance-door-1',
          name:
              'Test main door deadlock with all keys — lock and unlock smoothly, no stiffness',
          category: 'Security & Access',
          inspectionType: 'Lock & Key Audit',
          description: 'Lock & Key Audit. Equipment needed: All door keys.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'All door keys',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-2',
          name:
              'Check door chain / door limiter — attaches firmly and limits opening correctly',
          category: 'Security & Access',
          inspectionType: 'Lock & Key Audit',
          description: 'Lock & Key Audit. Equipment needed: Manual check.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-3',
          name:
              'Inspect door frame and strike plate — no splitting, screws fully seated',
          category: 'Security & Access',
          inspectionType: 'Lock & Key Audit',
          description:
              'Lock & Key Audit. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-4',
          name:
              'Verify intercom / video door phone inside unit — can speak and see visitor',
          category: 'Security & Access',
          inspectionType: 'Lock & Key Audit',
          description:
              'Lock & Key Audit. Equipment needed: Manual check (test call from lobby).',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check (test call from lobby)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-5',
          name:
              'Check video doorbell or camera — clear image, night vision functional, app connected',
          category: 'Security & Access',
          inspectionType: 'Video Doorbell / Camera Check',
          description:
              'Video Doorbell / Camera Check. Equipment needed: Manual check, smartphone app.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check, smartphone app',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-6',
          name:
              'Inspect door viewer (peephole) and security chain for secure fitting',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 67',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-7',
          name:
              'Check door closer — door should close fully at controlled speed without slamming',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'main-entrance-door-8',
          name:
              'Inspect door frame for swelling / warping — door should not require force to close',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 62',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'living-room',
      name: 'Living Room',
      iconName: 'weekend',
      items: [
        InspectionItem(
          id: 'living-room-9',
          name: 'Check ceiling fan at full speed for wobble and bearing noise',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 35',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-10',
          name:
              'Test all ceiling lights and any wall accent lights — check for flicker',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 36',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-11',
          name:
              'Inspect all switch boards — firm click action, no cracked covers, no scorch marks',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Manual check, plug-in socket tester.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 25',
          equipmentNeeded: 'Manual check, plug-in socket tester',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-12',
          name:
              'Test all socket outlets — no wobble in face plate, no warm-to-touch plates',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Plug-in socket tester / phone charger.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 26',
          equipmentNeeded: 'Plug-in socket tester / phone charger',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-13',
          name:
              'Inspect AC unit — check for water drip from indoor unit, test remote all modes',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description:
              'AC Unit Check. Equipment needed: Manual check, AC remote.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 41',
          equipmentNeeded: 'Manual check, AC remote',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-14',
          name:
              'Pull out AC filter — check dust level; schedule cleaning if grey/black',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description:
              'AC Unit Check. Equipment needed: Manual check (pull out filter).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 42',
          equipmentNeeded: 'Manual check (pull out filter)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-15',
          name:
              'Check AC condensate drain outlet — water discharges freely, no indoor drip',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description: 'AC Unit Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 44',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-16',
          name:
              'Inspect AC outdoor condenser unit — fins not bent, no debris blocking airflow',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description:
              'AC Unit Check. Equipment needed: Manual check, soft brush.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 43',
          equipmentNeeded: 'Manual check, soft brush',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-17',
          name:
              'Check AC electrical isolator switch — accessible, not corroded, operates freely',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description: 'AC Unit Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 46',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-18',
          name:
              'Tap floor tiles with rubber mallet or coin — hollow sound indicates debonded tile',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Rubber mallet or coin.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 57',
          equipmentNeeded: 'Rubber mallet or coin',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-19',
          name:
              'Inspect grout lines on floor tiles for crumbling, discolouration, or mould',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description: 'Flooring Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 58',
          equipmentNeeded: 'Manual check, torch',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-20',
          name:
              'Check wooden / laminate flooring for lifting, warping, or squeaking boards',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Manual check (walk across).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 59',
          equipmentNeeded: 'Manual check (walk across)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-21',
          name:
              'Inspect skirting boards — no gaps at floor joint, no paint peeling, secure to wall',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description: 'Flooring Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 61',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-22',
          name:
              'Shine torch at 45° along walls to reveal hairline cracks; check window corners',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Torch (angled lighting).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 50',
          equipmentNeeded: 'Torch (angled lighting)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-23',
          name: 'Measure any crack wider than 0.5mm — document width and date',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Crack width gauge or feeler gauge.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 51',
          equipmentNeeded: 'Crack width gauge or feeler gauge',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-24',
          name:
              'Inspect ceiling for brown water stain patches (top floor units — terrace leak)',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Torch, moisture meter (optional).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 52',
          equipmentNeeded: 'Torch, moisture meter (optional)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-25',
          name:
              'Check for window condensation pooling on sill — sign of poor ventilation',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Manual check, tissue.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 114',
          equipmentNeeded: 'Manual check, tissue',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-26',
          name:
              'Verify cross-ventilation — windows on opposing sides can open freely',
          category: 'HVAC & Ventilation',
          inspectionType: 'Ventilation Check',
          description: 'Ventilation Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 117',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-27',
          name:
              'Inspect all window handles, stays, and locking mechanisms — operable without force',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 65',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-28',
          name:
              'Check mosquito mesh / fly screen on all windows — no tears, seated correctly',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 66',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-29',
          name:
              'Check all sliding door tracks — lubricate, door glides without lifting or jamming',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description:
              'Door & Window Check. Equipment needed: Manual check, silicone spray.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 68',
          equipmentNeeded: 'Manual check, silicone spray',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-30',
          name:
              'Inspect curtain tracks, blinds, and window coverings — operate correctly',
          category: 'Storage & General',
          inspectionType: 'General Cleanliness Audit',
          description:
              'General Cleanliness Audit. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 137',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-31',
          name:
              'Check ceiling paint for peeling or staining — photograph and log locations',
          category: 'Storage & General',
          inspectionType: 'General Cleanliness Audit',
          description:
              'General Cleanliness Audit. Equipment needed: Torch, smartphone camera.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 136',
          equipmentNeeded: 'Torch, smartphone camera',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-32',
          name:
              'Test smoke detector — press test button, alarm sounds within 5 seconds',
          category: 'Fire Safety',
          inspectionType: 'Smoke Detector Check',
          description:
              'Smoke Detector Check. Equipment needed: Manual check (press test button).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 102',
          equipmentNeeded: 'Manual check (press test button)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-33',
          name:
              'Record smoke detector model and installation date — replace after 10 years',
          category: 'Fire Safety',
          inspectionType: 'Smoke Detector Check',
          description:
              'Smoke Detector Check. Equipment needed: Manual check (back label).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 103',
          equipmentNeeded: 'Manual check (back label)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'living-room-34',
          name:
              'Note any general maintenance items: scratches, paint touch-up, damaged fixtures',
          category: 'Storage & General',
          inspectionType: 'General Cleanliness Audit',
          description:
              'General Cleanliness Audit. Equipment needed: Inspection report pad.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 135',
          equipmentNeeded: 'Inspection report pad',
          severity: 'low',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'master-bedroom',
      name: 'Master Bedroom',
      iconName: 'bed',
      items: [
        InspectionItem(
          id: 'master-bedroom-35',
          name:
              'Test ceiling fan — full speed, check for wobble and bearing noise',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 35',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-36',
          name:
              'Test all light points including bedside reading lamp and wall-mounted lights',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 37',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-37',
          name:
              'Inspect all switch boards and socket outlets — no cracks, scorch, wobble',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Manual check, plug-in socket tester.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 25',
          equipmentNeeded: 'Manual check, plug-in socket tester',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-38',
          name:
              'Inspect AC unit — no indoor water drip, filter condition, cooling efficiency',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description: 'AC Unit Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 41',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-39',
          name:
              'Pull out AC filter — check dust block; record for cleaning schedule',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description:
              'AC Unit Check. Equipment needed: Manual check (pull out filter).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 42',
          equipmentNeeded: 'Manual check (pull out filter)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-40',
          name:
              'Check AC condensate drain — discharges freely, no water tracking on wall',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description: 'AC Unit Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 44',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-41',
          name:
              'Shine torch at 45° along walls — look for hairline cracks, check window corners',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Torch (angled lighting).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 50',
          equipmentNeeded: 'Torch (angled lighting)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-42',
          name: 'Check ceiling for brown stain patches or plaster bulging',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Torch, moisture meter (optional).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 52',
          equipmentNeeded: 'Torch, moisture meter (optional)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-43',
          name: 'Tap floor tiles with coin — hollow sound = debonded tile risk',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Rubber mallet or coin.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 57',
          equipmentNeeded: 'Rubber mallet or coin',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-44',
          name:
              'Check wooden / laminate flooring for lifting, warping, squeaking boards',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Manual check (walk across).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 59',
          equipmentNeeded: 'Manual check (walk across)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-45',
          name:
              'Inspect door — no scraping, deadlock and latch operate smoothly with key',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description:
              'Door & Window Check. Equipment needed: Manual check, key.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 63',
          equipmentNeeded: 'Manual check, key',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-46',
          name:
              'Check window seals and handles — rubber seal not brittle, handles lock firmly',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 65',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-47',
          name:
              'Inspect wardrobe interiors for mould, musty smell, or moisture buildup',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Manual check (smell), moisture meter.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 115',
          equipmentNeeded: 'Manual check (smell), moisture meter',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-48',
          name:
              'Check exterior wall behind wardrobe for black/green mould spots',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Torch, mirror (to check behind furniture).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 113',
          equipmentNeeded: 'Torch, mirror (to check behind furniture)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-49',
          name: 'Inspect mattress seams and headboard joints for bed bug signs',
          category: 'Pest Control',
          inspectionType: 'Bed Bug Check',
          description:
              'Bed Bug Check. Equipment needed: Torch, gloves, magnifying glass.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 98',
          equipmentNeeded: 'Torch, gloves, magnifying glass',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-50',
          name:
              'Check bed base fabric underside and carpet edge for dark spotting (bed bug frass)',
          category: 'Pest Control',
          inspectionType: 'Bed Bug Check',
          description: 'Bed Bug Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 99',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bedroom-51',
          name:
              'Test smoke detector — press test button, alarm sounds within 5 seconds',
          category: 'Fire Safety',
          inspectionType: 'Smoke Detector Check',
          description:
              'Smoke Detector Check. Equipment needed: Manual check (press test button).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 102',
          equipmentNeeded: 'Manual check (press test button)',
          severity: 'critical',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'bedroom-2',
      name: 'Bedroom 2',
      iconName: 'bed',
      items: [
        InspectionItem(
          id: 'bedroom-2-52',
          name:
              'Test ceiling fan — full speed, check for wobble and bearing noise',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 35',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-53',
          name: 'Test all light points and bedside / wall lights',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 37',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-54',
          name:
              'Inspect switch boards and socket outlets — no cracks, scorch, wobble',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Manual check, plug-in socket tester.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 25',
          equipmentNeeded: 'Manual check, plug-in socket tester',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-55',
          name:
              'Inspect AC unit (if fitted) — no indoor water drip, test all remote modes',
          category: 'Electrical',
          inspectionType: 'AC Unit Check',
          description:
              'AC Unit Check. Equipment needed: Manual check, AC remote.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 41',
          equipmentNeeded: 'Manual check, AC remote',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-56',
          name:
              'Shine torch at 45° along walls — check for hairline cracks at corners',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Torch (angled lighting).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 50',
          equipmentNeeded: 'Torch (angled lighting)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-57',
          name:
              'Tap floor tiles with coin — solid sound expected; hollow = debonded',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Rubber mallet or coin.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 57',
          equipmentNeeded: 'Rubber mallet or coin',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-58',
          name: 'Inspect door lock and hinge — no scraping, smooth operation',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description:
              'Door & Window Check. Equipment needed: Manual check, key.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 63',
          equipmentNeeded: 'Manual check, key',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-59',
          name: 'Check window seals, handles, and mosquito mesh condition',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description: 'Door & Window Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 65',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-60',
          name:
              'Inspect wardrobe/storage for mould signs and check exterior wall behind',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Manual check, moisture meter.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 115',
          equipmentNeeded: 'Manual check, moisture meter',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-61',
          name: 'Inspect mattress seams and headboard for bed bug signs',
          category: 'Pest Control',
          inspectionType: 'Bed Bug Check',
          description:
              'Bed Bug Check. Equipment needed: Torch, gloves, magnifying glass.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 98',
          equipmentNeeded: 'Torch, gloves, magnifying glass',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bedroom-2-62',
          name:
              'Test smoke detector (if installed) — alarm sounds within 5 seconds',
          category: 'Fire Safety',
          inspectionType: 'Smoke Detector Check',
          description:
              'Smoke Detector Check. Equipment needed: Manual check (press test button).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 102',
          equipmentNeeded: 'Manual check (press test button)',
          severity: 'critical',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'master-bathroom',
      name: 'Master Bathroom',
      iconName: 'bathroom',
      items: [
        InspectionItem(
          id: 'master-bathroom-63',
          name:
              'Turn on taps fully — check for drips when closed, low pressure, aerator blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 1',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-64',
          name:
              'Test hot and cold mix — temperature blends correctly from mixer tap',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, thermometer (optional).',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check, thermometer (optional)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-65',
          name: 'Check tap handles for loose fixings or cracked ceramic',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: New (Added) —',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-66',
          name:
              'Flush toilet — cistern refills within 60 seconds, no phantom flushing sound',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description: 'Flush & WC Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 5',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-67',
          name: 'Check toilet base seal — no odour or dampness around base',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description:
              'Flush & WC Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 6',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-68',
          name:
              'Inspect toilet bowl for cracks, staining, and rim jet blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description:
              'Flush & WC Check. Equipment needed: Manual check, torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 7',
          equipmentNeeded: 'Manual check, torch, gloves',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-69',
          name:
              'Check flush inlet valve — no continuous hissing or water hammer noise',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description:
              'Flush & WC Check. Equipment needed: Manual check (listen carefully).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 9',
          equipmentNeeded: 'Manual check (listen carefully)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-70',
          name:
              'Test toilet paper holder, towel rail, brush holder — secure wall fixing',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description: 'Flush & WC Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 8',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-71',
          name:
              'Pour 5 litres into drain — drain within 10 seconds; gurgling = blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Manual check, bucket of water.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 10',
          equipmentNeeded: 'Manual check, bucket of water',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-72',
          name: 'Remove floor drain cover — check for hair/soap blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Gloves, small wire hook.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 11',
          equipmentNeeded: 'Gloves, small wire hook',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-73',
          name:
              'Inspect geyser for leakage from PRV, rust staining at base, body corrosion',
          category: 'Plumbing & Water',
          inspectionType: 'Water Heater / Geyser Check',
          description:
              'Water Heater / Geyser Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 14',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-74',
          name:
              'Record geyser manufacturing date — flag units older than 8 years',
          category: 'Plumbing & Water',
          inspectionType: 'Water Heater / Geyser Check',
          description:
              'Water Heater / Geyser Check. Equipment needed: Manual check (label inside cover).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 15',
          equipmentNeeded: 'Manual check (label inside cover)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-75',
          name:
              'Check geyser thermostat — should not exceed 60°C to prevent scalding',
          category: 'Plumbing & Water',
          inspectionType: 'Water Heater / Geyser Check',
          description:
              'Water Heater / Geyser Check. Equipment needed: Manual check, thermometer.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 16',
          equipmentNeeded: 'Manual check, thermometer',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-76',
          name: 'Inspect geyser earth wire connection and RCD/ELCB operation',
          category: 'Plumbing & Water',
          inspectionType: 'Water Heater / Geyser Check',
          description:
              'Water Heater / Geyser Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 17',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-77',
          name:
              'Open under-vanity cabinet — check pipe joints with dry paper towel for moisture',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Torch, paper towel.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 18',
          equipmentNeeded: 'Torch, paper towel',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-78',
          name:
              'Inspect shower enclosure base tray and door seal — no water tracking outside',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Manual check, paper towel.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 20',
          equipmentNeeded: 'Manual check, paper towel',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-79',
          name:
              'Check tile grout lines on walls — crumbling grout allows water behind tiles',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Manual check, screwdriver (gentle probe).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 53',
          equipmentNeeded: 'Manual check, screwdriver (gentle probe)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-80',
          name:
              'Press hand on bathroom-adjacent wall — cold/clammy = active seepage',
          category: 'Civil & Structural',
          inspectionType: 'Seepage & Damp Check',
          description:
              'Seepage & Damp Check. Equipment needed: Manual check, moisture meter.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 54',
          equipmentNeeded: 'Manual check, moisture meter',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-81',
          name:
              'Check for white efflorescence deposits at wall base — indicates water wicking',
          category: 'Civil & Structural',
          inspectionType: 'Seepage & Damp Check',
          description:
              'Seepage & Damp Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 56',
          equipmentNeeded: 'Manual check, torch',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-82',
          name:
              'Wet bathroom floor tiles and walk — verify non-slip rating is adequate',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Manual check (wet test).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 60',
          equipmentNeeded: 'Manual check (wet test)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-83',
          name:
              'Inspect bathroom ceiling corners and behind cistern for mould (black spots)',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Torch, mirror.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 113',
          equipmentNeeded: 'Torch, mirror',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-84',
          name:
              'Check exhaust fan — starts within 3 seconds, blades clean, louvre flap opens',
          category: 'HVAC & Ventilation',
          inspectionType: 'Bathroom Exhaust Fan Check',
          description:
              'Bathroom Exhaust Fan Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 110',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-85',
          name: 'Test exhaust fan timer or humidity sensor switch',
          category: 'HVAC & Ventilation',
          inspectionType: 'Bathroom Exhaust Fan Check',
          description:
              'Bathroom Exhaust Fan Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 111',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-86',
          name: 'Verify light fitting is IP44 moisture-zone rated',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check (check IP rating label).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 39',
          equipmentNeeded: 'Manual check (check IP rating label)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-87',
          name:
              'Check no standard sockets inside bathroom (shaver socket only permitted)',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description: 'Switch & Socket Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 28',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'master-bathroom-88',
          name:
              'Check for mosquito breeding — AC condensate tray and standing water points',
          category: 'Pest Control',
          inspectionType: 'Mosquito Breeding Check',
          description:
              'Mosquito Breeding Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 95',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'bathroom-2',
      name: 'Bathroom 2',
      iconName: 'bathroom',
      items: [
        InspectionItem(
          id: 'bathroom-2-89',
          name:
              'Turn on taps fully — check for drips, low pressure, aerator blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 1',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-90',
          name:
              'Flush toilet — cistern refills within 60 seconds, no phantom flushing',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description: 'Flush & WC Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 5',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-91',
          name: 'Check toilet base seal and bowl for cracks or staining',
          category: 'Plumbing & Water',
          inspectionType: 'Flush & WC Check',
          description:
              'Flush & WC Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 6',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-92',
          name:
              'Pour 5 litres into drain — check speed; remove cover, clear hair/soap block',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Manual check, bucket, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 10',
          equipmentNeeded: 'Manual check, bucket, gloves',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-93',
          name:
              'Inspect geyser (if present) — PRV, rust staining, geyser age label',
          category: 'Plumbing & Water',
          inspectionType: 'Water Heater / Geyser Check',
          description:
              'Water Heater / Geyser Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 14',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-94',
          name:
              'Open under-vanity cabinet — check pipe joints for moisture or drip staining',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Torch, paper towel.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 18',
          equipmentNeeded: 'Torch, paper towel',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-95',
          name:
              'Check tile grout on walls and non-slip condition of floor tiles',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 53',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-96',
          name: 'Inspect ceiling corners for mould growth',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description: 'Mould & Condensation Check. Equipment needed: Torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 113',
          equipmentNeeded: 'Torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-97',
          name: 'Check exhaust fan operation and louvre flap',
          category: 'HVAC & Ventilation',
          inspectionType: 'Bathroom Exhaust Fan Check',
          description:
              'Bathroom Exhaust Fan Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 110',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-98',
          name:
              'Verify light fitting is IP44 rated and no standard sockets inside',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 39',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'bathroom-2-99',
          name:
              'Check for cockroach harbourage in pipe chase and behind cistern',
          category: 'Pest Control',
          inspectionType: 'Cockroach Activity Check',
          description:
              'Cockroach Activity Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 91',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'kitchen',
      name: 'Kitchen',
      iconName: 'kitchen',
      items: [
        InspectionItem(
          id: 'kitchen-100',
          name:
              'Turn on taps fully — check for drips, low pressure, aerator blockage',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 1',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-101',
          name: 'Check kitchen sink basket strainer — clean and mesh intact',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Manual check, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 12',
          equipmentNeeded: 'Manual check, gloves',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-102',
          name:
              'Pour 5 litres into sink drain — drain within 10 seconds, no gurgling',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Manual check, bucket.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 10',
          equipmentNeeded: 'Manual check, bucket',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-103',
          name:
              'Open under-sink cabinet — shine torch at all pipe joints with dry paper towel',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Torch, paper towel.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 18',
          equipmentNeeded: 'Torch, paper towel',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-104',
          name:
              'Check sink-to-counter silicone seal — any gap or crack must be resealed',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description:
              'Sink & Counter Check. Equipment needed: Torch, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 81',
          equipmentNeeded: 'Torch, screwdriver',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-105',
          name:
              'Press counter tiles near sink — loose tiles indicate water under grout',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description: 'Sink & Counter Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 82',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-106',
          name:
              'Inspect kitchen counter surface for chips, cracks, or delamination',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description: 'Sink & Counter Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 82',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-107',
          name:
              'Check kitchen cabinet hinges and drawer runners — smooth operation',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description: 'Sink & Counter Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 83',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-108',
          name:
              'Test waste disposal unit (if fitted) — runs without jam, no base leak',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description:
              'Sink & Counter Check. Equipment needed: Manual check (run with water).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 84',
          equipmentNeeded: 'Manual check (run with water)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-109',
          name:
              'Inspect refrigerator area — coil not blocked, no ice maker water leak',
          category: 'Kitchen',
          inspectionType: 'Sink & Counter Check',
          description:
              'Sink & Counter Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 85',
          equipmentNeeded: 'Manual check, torch',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-110',
          name:
              'Check kitchen socket outlets near sink — must have splash-back protection',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description: 'Switch & Socket Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 27',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-111',
          name:
              'Test all remaining socket outlets and light switches in kitchen',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Manual check, plug-in tester.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 25',
          equipmentNeeded: 'Manual check, plug-in tester',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-112',
          name:
              'Check under-cabinet LED strip lighting — no flickering, secure mounting',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 38',
          equipmentNeeded: 'Manual check',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-113',
          name:
              'Inspect gas flexible hose — no cracks, kinks, rubber deterioration',
          category: 'Kitchen',
          inspectionType: 'Gas Line Visual Check',
          description:
              'Gas Line Visual Check. Equipment needed: Manual check (NO flame/spark).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 76',
          equipmentNeeded: 'Manual check (NO flame/spark)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-114',
          name: 'Check gas hose date label — replace if older than 5 years',
          category: 'Kitchen',
          inspectionType: 'Gas Line Visual Check',
          description:
              'Gas Line Visual Check. Equipment needed: Manual check (label on hose).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 77',
          equipmentNeeded: 'Manual check (label on hose)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-115',
          name:
              'Verify gas shut-off valve accessible and operable — resident knows location',
          category: 'Kitchen',
          inspectionType: 'Gas Line Visual Check',
          description: 'Gas Line Visual Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 79',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-116',
          name:
              'Apply soapy water to regulator connection — bubbles = gas leak (open windows if detected)',
          category: 'Kitchen',
          inspectionType: 'Gas Line Visual Check',
          description:
              'Gas Line Visual Check. Equipment needed: Soapy water, brush.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 76',
          equipmentNeeded: 'Soapy water, brush',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-117',
          name:
              'Test all stove burners — ignite cleanly, blue flame (not yellow/orange)',
          category: 'Kitchen',
          inspectionType: 'Gas Line Visual Check',
          description:
              'Gas Line Visual Check. Equipment needed: Manual check (turn on burners).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 80',
          equipmentNeeded: 'Manual check (turn on burners)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-118',
          name:
              'Turn on exhaust fan — tissue held at inlet should be drawn inward',
          category: 'Kitchen',
          inspectionType: 'Exhaust Fan Check',
          description:
              'Exhaust Fan Check. Equipment needed: Manual check, tissue paper.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 73',
          equipmentNeeded: 'Manual check, tissue paper',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-119',
          name:
              'Inspect chimney/hood grease trap — check oil level, clean if >50% full',
          category: 'Kitchen',
          inspectionType: 'Exhaust Fan Check',
          description:
              'Exhaust Fan Check. Equipment needed: Gloves, container for oil disposal.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 74',
          equipmentNeeded: 'Gloves, container for oil disposal',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-120',
          name:
              'Check exhaust duct exit on external wall — bird screen intact, duct not kinked',
          category: 'Kitchen',
          inspectionType: 'Exhaust Fan Check',
          description:
              'Exhaust Fan Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 75',
          equipmentNeeded: 'Manual check, torch',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-121',
          name:
              'Check built-in oven/microwave — door seal intact, interior clean, element OK',
          category: 'Kitchen',
          inspectionType: 'Appliance & Fixture Check',
          description:
              'Appliance & Fixture Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 86',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-122',
          name:
              'Test dishwasher (if installed) — run quick cycle, check for leaks, door latch secure',
          category: 'Kitchen',
          inspectionType: 'Appliance & Fixture Check',
          description:
              'Appliance & Fixture Check. Equipment needed: Manual check (run cycle).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 87',
          equipmentNeeded: 'Manual check (run cycle)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-123',
          name:
              'Inspect backsplash tiles behind hob — no loose tiles, grout intact',
          category: 'Kitchen',
          inspectionType: 'Appliance & Fixture Check',
          description:
              'Appliance & Fixture Check. Equipment needed: Manual check, gentle press on tiles.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 88',
          equipmentNeeded: 'Manual check, gentle press on tiles',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-124',
          name: 'Check kitchen tile grout on walls for crumbling or mould',
          category: 'Civil & Structural',
          inspectionType: 'Wall & Ceiling Crack Check',
          description:
              'Wall & Ceiling Crack Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 53',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-125',
          name:
              'Check for seepage staining on kitchen exterior wall or paint bubbling',
          category: 'Civil & Structural',
          inspectionType: 'Seepage & Damp Check',
          description:
              'Seepage & Damp Check. Equipment needed: Torch, moisture meter.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 54',
          equipmentNeeded: 'Torch, moisture meter',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-126',
          name: 'Wet kitchen floor tiles — verify non-slip rating adequate',
          category: 'Civil & Structural',
          inspectionType: 'Flooring Check',
          description:
              'Flooring Check. Equipment needed: Manual check (wet test).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 60',
          equipmentNeeded: 'Manual check (wet test)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-127',
          name:
              'Inspect grease duct for condensate drip inside duct — fire hazard',
          category: 'HVAC & Ventilation',
          inspectionType: 'Mould & Condensation Check',
          description:
              'Mould & Condensation Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 116',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-128',
          name:
              'Torch into kitchen cabinets — check for cockroach egg casings near hinges',
          category: 'Pest Control',
          inspectionType: 'Cockroach Activity Check',
          description:
              'Cockroach Activity Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 90',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-129',
          name:
              'Check behind refrigerator and under dishwasher for cockroach activity',
          category: 'Pest Control',
          inspectionType: 'Cockroach Activity Check',
          description:
              'Cockroach Activity Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 92',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-130',
          name:
              'Check window sills for active ant trails — trace entry point, seal with silicone',
          category: 'Pest Control',
          inspectionType: 'Ant Trail Check',
          description:
              'Ant Trail Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 93',
          equipmentNeeded: 'Manual check, torch',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-131',
          name:
              'Verify smoke detector is positioned 3m away from hob — no false alarm risk',
          category: 'Fire Safety',
          inspectionType: 'Smoke Detector Check',
          description:
              'Smoke Detector Check. Equipment needed: Manual check (measure distance).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 104',
          equipmentNeeded: 'Manual check (measure distance)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-132',
          name:
              'Check fire extinguisher — Class F (wet chemical), pressure in green zone, pin intact',
          category: 'Fire Safety',
          inspectionType: 'Fire Extinguisher Check',
          description:
              'Fire Extinguisher Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 105',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'kitchen-133',
          name:
              'Confirm extinguisher is wall-mounted at accessible height, not blocked',
          category: 'Fire Safety',
          inspectionType: 'Fire Extinguisher Check',
          description:
              'Fire Extinguisher Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 107',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'balcony',
      name: 'Balcony',
      iconName: 'balcony',
      items: [
        InspectionItem(
          id: 'balcony-134',
          name:
              'Push railing sideways and vertically — must not move more than 5mm',
          category: 'Civil & Structural',
          inspectionType: 'Balcony & Railing Check',
          description:
              'Balcony & Railing Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 69',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-135',
          name:
              'Inspect balcony ceiling for seepage stains or plaster drop from unit above',
          category: 'Civil & Structural',
          inspectionType: 'Balcony & Railing Check',
          description:
              'Balcony & Railing Check. Equipment needed: Torch, manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 70',
          equipmentNeeded: 'Torch, manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-136',
          name:
              'Check waterproofing lap at wall base — no cracks or membrane edge separation',
          category: 'Civil & Structural',
          inspectionType: 'Balcony & Railing Check',
          description:
              'Balcony & Railing Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 71',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-137',
          name:
              'Inspect storage area / utility cupboard — ventilated, no moisture buildup',
          category: 'Civil & Structural',
          inspectionType: 'Balcony & Railing Check',
          description:
              'Balcony & Railing Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 72',
          equipmentNeeded: 'Manual check, torch',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-138',
          name:
              'Check balcony drain is clear — no plant roots, debris, or grille displacement',
          category: 'Plumbing & Water',
          inspectionType: 'Drain Flow Check',
          description:
              'Drain Flow Check. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 13',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-139',
          name:
              'Check overhead pipe runs and brackets on balcony ceiling for rust or drips',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Torch, manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 21',
          equipmentNeeded: 'Torch, manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-140',
          name:
              'Empty and invert all flowerpot saucers — eliminate mosquito breeding points',
          category: 'Pest Control',
          inspectionType: 'Mosquito Breeding Check',
          description:
              'Mosquito Breeding Check. Equipment needed: Manual check, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 96',
          equipmentNeeded: 'Manual check, gloves',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-141',
          name:
              'Inspect any external security camera — mounting not shifted, cable secure',
          category: 'Security & Access',
          inspectionType: 'Video Doorbell / Camera Check',
          description:
              'Video Doorbell / Camera Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 132',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'balcony-142',
          name:
              'Check balcony door lock, frame, and sliding track — smooth operation',
          category: 'Civil & Structural',
          inspectionType: 'Door & Window Check',
          description:
              'Door & Window Check. Equipment needed: Manual check, silicone spray.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 68',
          equipmentNeeded: 'Manual check, silicone spray',
          severity: 'medium',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'utility-area',
      name: 'Utility Area',
      iconName: 'build',
      items: [
        InspectionItem(
          id: 'utility-area-143',
          name:
              'Inspect utility tap and washing machine hose connections for damp or loose fittings',
          category: 'Plumbing & Water',
          inspectionType: 'Tap & Faucet Check',
          description:
              'Tap & Faucet Check. Equipment needed: Manual check, paper towel.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 4',
          equipmentNeeded: 'Manual check, paper towel',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'utility-area-144',
          name:
              'Inspect washing machine inlet hose and drain hose for splits or kinks',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description: 'Pipe Leakage Scan. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 22',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'utility-area-145',
          name:
              'Confirm utility area is ventilated — no enclosed damp pocket forming',
          category: 'HVAC & Ventilation',
          inspectionType: 'Ventilation Check',
          description: 'Ventilation Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 118',
          equipmentNeeded: 'Manual check',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'utility-area-146',
          name:
              'Check for cockroach activity in utility pipe chases and behind washing machine',
          category: 'Pest Control',
          inspectionType: 'Cockroach Activity Check',
          description:
              'Cockroach Activity Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 89',
          equipmentNeeded: 'Torch, gloves',
          severity: 'high',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'electrical-panel-mcb-room',
      name: 'Electrical Panel / Mcb Room',
      iconName: 'electrical_services',
      items: [
        InspectionItem(
          id: 'electrical-panel-mcb-room-147',
          name: 'Open MCB panel — all breakers in UP position, labels legible',
          category: 'Electrical',
          inspectionType: 'MCB / Circuit Breaker Check',
          description:
              'MCB / Circuit Breaker Check. Equipment needed: Manual check, IR thermometer.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 31',
          equipmentNeeded: 'Manual check, IR thermometer',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-148',
          name:
              'Verify MCB ampere ratings match circuit loads — no bridged breakers',
          category: 'Electrical',
          inspectionType: 'MCB / Circuit Breaker Check',
          description:
              'MCB / Circuit Breaker Check. Equipment needed: Manual check (read label amperage).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 32',
          equipmentNeeded: 'Manual check (read label amperage)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-149',
          name:
              'Test ELCB / RCD trip by pressing TEST button — trips within 30ms',
          category: 'Electrical',
          inspectionType: 'MCB / Circuit Breaker Check',
          description:
              'MCB / Circuit Breaker Check. Equipment needed: Manual check (press TEST button).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 33',
          equipmentNeeded: 'Manual check (press TEST button)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-150',
          name:
              'Check earth strip inside MCB panel — all earth wires terminated firmly',
          category: 'Electrical',
          inspectionType: 'MCB / Circuit Breaker Check',
          description:
              'MCB / Circuit Breaker Check. Equipment needed: Manual check, screwdriver.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 34',
          equipmentNeeded: 'Manual check, screwdriver',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-151',
          name:
              'Test inverter changeover — switch off mains, inverter powers designated circuits',
          category: 'Electrical',
          inspectionType: 'Inverter / UPS Check',
          description: 'Inverter / UPS Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 48',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-152',
          name:
              'Inspect inverter battery — water level (tubular), no acid leak on tray',
          category: 'Electrical',
          inspectionType: 'Inverter / UPS Check',
          description:
              'Inverter / UPS Check. Equipment needed: Manual check, gloves, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 47',
          equipmentNeeded: 'Manual check, gloves, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-153',
          name:
              'Record inverter battery manufacturing date — flag if older than 3 years',
          category: 'Electrical',
          inspectionType: 'Inverter / UPS Check',
          description:
              'Inverter / UPS Check. Equipment needed: Manual check (battery label).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 49',
          equipmentNeeded: 'Manual check (battery label)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-154',
          name: 'Record electricity meter reading — photograph with date stamp',
          category: 'Utility Metering',
          inspectionType: 'Electricity Meter Reading',
          description:
              'Electricity Meter Reading. Equipment needed: Manual check, smartphone camera.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 119',
          equipmentNeeded: 'Manual check, smartphone camera',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-155',
          name: 'Verify meter serial number matches tenant agreement',
          category: 'Utility Metering',
          inspectionType: 'Electricity Meter Reading',
          description:
              'Electricity Meter Reading. Equipment needed: Manual check, tenancy file.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 121',
          equipmentNeeded: 'Manual check, tenancy file',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-156',
          name:
              'Record water meter reading — observe dial with all taps closed (moving = hidden leak)',
          category: 'Utility Metering',
          inspectionType: 'Water Meter Check',
          description:
              'Water Meter Check. Equipment needed: Manual check (observe dial).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 123',
          equipmentNeeded: 'Manual check (observe dial)',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-157',
          name:
              'Record gas meter reading — check isolation valve operates freely',
          category: 'Utility Metering',
          inspectionType: 'Gas Meter Check',
          description:
              'Gas Meter Check. Equipment needed: Manual check, meter reading log.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 125',
          equipmentNeeded: 'Manual check, meter reading log',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'electrical-panel-mcb-room-158',
          name: 'Test gas meter emergency isolation valve — must close fully',
          category: 'Utility Metering',
          inspectionType: 'Gas Meter Check',
          description: 'Gas Meter Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 126',
          equipmentNeeded: 'Manual check',
          severity: 'critical',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'loft-storage',
      name: 'Loft / Storage',
      iconName: 'inventory_2',
      items: [
        InspectionItem(
          id: 'loft-storage-159',
          name:
              'Inspect loft hatch / storage cupboard for dampness, pest signs, structural cracks',
          category: 'Storage & General',
          inspectionType: 'Loft / Storage Check',
          description: 'Loft / Storage Check. Equipment needed: Torch, gloves.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 133',
          equipmentNeeded: 'Torch, gloves',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'loft-storage-160',
          name:
              'Check loft insulation (if applicable) — no compression, water damage, or pest nesting',
          category: 'Storage & General',
          inspectionType: 'Loft / Storage Check',
          description:
              'Loft / Storage Check. Equipment needed: Torch, PPE mask.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 134',
          equipmentNeeded: 'Torch, PPE mask',
          severity: 'medium',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'water-tank-overhead',
      name: 'Water Tank / Overhead',
      iconName: 'water_drop',
      items: [
        InspectionItem(
          id: 'water-tank-overhead-161',
          name:
              'Check OHT ball valve — fully functional, float arm not bent causing overflow',
          category: 'Plumbing & Water',
          inspectionType: 'Water Pressure Test',
          description:
              'Water Pressure Test. Equipment needed: Manual check, torch.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 24',
          equipmentNeeded: 'Manual check, torch',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'water-tank-overhead-162',
          name:
              'Test water pressure at kitchen, master bath, secondary bath — minimum 1.5 bar',
          category: 'Plumbing & Water',
          inspectionType: 'Water Pressure Test',
          description:
              'Water Pressure Test. Equipment needed: Water pressure gauge (attach to tap thread).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 23',
          equipmentNeeded: 'Water pressure gauge (attach to tap thread)',
          severity: 'medium',
          completed: false,
        ),
      ]),
  InspectionAreaTemplate(
      key: 'whole-unit',
      name: 'Whole Unit',
      iconName: 'home_work',
      items: [
        InspectionItem(
          id: 'whole-unit-163',
          name:
              'Confirm resident knows fire exit route and assembly point location',
          category: 'Fire Safety',
          inspectionType: 'Evacuation Awareness Check',
          description:
              'Evacuation Awareness Check. Equipment needed: Verbal check with resident.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 108',
          equipmentNeeded: 'Verbal check with resident',
          severity: 'critical',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-164',
          name: 'Check if fire escape plan is posted inside unit',
          category: 'Fire Safety',
          inspectionType: 'Evacuation Awareness Check',
          description:
              'Evacuation Awareness Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 109',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-165',
          name:
              'Check all ant entry points — seal identified gaps with silicone sealant',
          category: 'Pest Control',
          inspectionType: 'Ant Trail Check',
          description:
              'Ant Trail Check. Equipment needed: Silicone sealant gun.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 94',
          equipmentNeeded: 'Silicone sealant gun',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-166',
          name: 'Inspect all walls along pipe routes for water stain marks',
          category: 'Plumbing & Water',
          inspectionType: 'Pipe Leakage Scan',
          description:
              'Pipe Leakage Scan. Equipment needed: Torch, moisture meter (optional).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 19',
          equipmentNeeded: 'Torch, moisture meter (optional)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-167',
          name:
              'Press all exterior-facing walls at ground level — cold/damp = rising damp',
          category: 'Civil & Structural',
          inspectionType: 'Seepage & Damp Check',
          description:
              'Seepage & Damp Check. Equipment needed: Manual check, moisture meter.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 55',
          equipmentNeeded: 'Manual check, moisture meter',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-168',
          name:
              'Inspect staircase step lighting / sensor lights — PIR triggers correctly',
          category: 'Electrical',
          inspectionType: 'Fan & Light Fixture Check',
          description:
              'Fan & Light Fixture Check. Equipment needed: Manual check (walk past sensor).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 40',
          equipmentNeeded: 'Manual check (walk past sensor)',
          severity: 'medium',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-169',
          name:
              'Check mosquito breeding in balcony corners, AC tray, bathroom buckets',
          category: 'Pest Control',
          inspectionType: 'Mosquito Breeding Check',
          description:
              'Mosquito Breeding Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 95',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-170',
          name:
              'Inspect ground floor door frames and skirting for termite mud tubes',
          category: 'Pest Control',
          inspectionType: 'Termite Check',
          description:
              'Termite Check. Equipment needed: Torch, screwdriver (tap test).',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 100',
          equipmentNeeded: 'Torch, screwdriver (tap test)',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-171',
          name:
              'Tap kitchen cabinet base boards for hollow sound — indicates termite activity',
          category: 'Pest Control',
          inspectionType: 'Termite Check',
          description: 'Termite Check. Equipment needed: Screwdriver handle.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 101',
          equipmentNeeded: 'Screwdriver handle',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-172',
          name: 'Test all socket outlets throughout unit — all rooms',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description:
              'Switch & Socket Check. Equipment needed: Phone/charger.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 29',
          equipmentNeeded: 'Phone/charger',
          severity: 'low',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-173',
          name:
              'Check balcony socket outlet — IP65 weatherproof cover, no corrosion',
          category: 'Electrical',
          inspectionType: 'Switch & Socket Check',
          description: 'Switch & Socket Check. Equipment needed: Manual check.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 30',
          equipmentNeeded: 'Manual check',
          severity: 'high',
          completed: false,
        ),
        InspectionItem(
          id: 'whole-unit-174',
          name:
              'Walk through all rooms — note general paint, scratches, fixtures needing attention',
          category: 'Storage & General',
          inspectionType: 'General Cleanliness Audit',
          description:
              'General Cleanliness Audit. Equipment needed: Inspection report pad.',
          howTo: 'Source: Unit-Flat Inspection — Inside E Row 135',
          equipmentNeeded: 'Inspection report pad',
          severity: 'low',
          completed: false,
        ),
      ]),
];

List<InspectionArea> buildInspectionAreasFromTemplates(
  List<InspectionAreaTemplate> templates,
) {
  return [
    for (final template in templates)
      InspectionArea(
        id: 'area-${template.key}',
        name: template.name,
        icon: template.iconName,
        templateKey: template.key,
        progress: 0,
        status: 'pending',
        issues: inspectionItemsForTemplate(template).length,
        completed: 0,
        items: inspectionItemsForTemplate(template),
      ),
  ];
}

List<InspectionItem> inspectionItemsForTemplate(
    InspectionAreaTemplate template) {
  return [
    ...template.items,
    _wallDampnessCheckFor(template),
  ];
}

List<InspectionArea> ensureRequiredAreaChecks(List<InspectionArea> areas) {
  return areas.map(_ensureRequiredAreaChecks).toList(growable: false);
}

InspectionArea _ensureRequiredAreaChecks(InspectionArea area) {
  final hasDampnessCheck =
      area.items.any((item) => item.id.endsWith('-wall-dampness-check'));
  if (hasDampnessCheck) return area;

  final dampnessCheck = _wallDampnessCheckForArea(
    key: area.templateKey,
    name: area.name,
  );
  final updatedItems = [...area.items, dampnessCheck];
  return area.copyWith(
    issues: updatedItems.length,
    items: updatedItems,
  );
}

InspectionItem _wallDampnessCheckFor(InspectionAreaTemplate template) {
  return _wallDampnessCheckForArea(key: template.key, name: template.name);
}

InspectionItem _wallDampnessCheckForArea({
  required String key,
  required String name,
}) {
  return InspectionItem(
    id: '$key-wall-dampness-check',
    name: 'Check dampness on all walls',
    category: 'Leakage/Seepage',
    inspectionType: 'Wall Dampness Multi-Photo Check',
    description:
        'Inspect every accessible wall in $name for dampness, seepage, bubbling paint, staining, or moisture patches. Add live photos when evidence is needed.',
    howTo: 'Source: KEPR room-wise dampness control requirement',
    equipmentNeeded: 'Device camera, moisture meter if available',
    severity: 'high',
    completed: false,
  );
}

InspectionArea sampleReportChecksAreaArchive() {
  const items = [
    InspectionItem(
      id: 'sample-report-1',
      name:
          'Check for leakage or seepage patches near windows and external walls',
      category: 'Leakage/Seepage',
      inspectionType: 'Moisture Visual Check',
      description:
          'Inspect walls around windows, exterior-facing corners, and sill joints for dampness, discoloration, or active leakage marks.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera, moisture meter if available',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-2',
      name: 'Check ceiling areas above doors and windows for seepage marks',
      category: 'Leakage/Seepage',
      inspectionType: 'Ceiling Dampness Check',
      description:
          'Look for ceiling staining, bubbling, dark patches, or water trail marks above openings and beam junctions.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera, ladder if required',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-3',
      name: 'Verify AC voltage is within the expected 230V to 240V range',
      category: 'Electrical Work',
      inspectionType: 'Voltage Check',
      description:
          'Measure supply voltage at accessible points and record any over-voltage or under-voltage condition.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Multimeter or clamp meter',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-4',
      name: 'Check for current leakage at junction boxes and switchboards',
      category: 'Electrical Work',
      inspectionType: 'Current Leakage Check',
      description:
          'Use a tester or meter to confirm no unsafe current leakage is present at exposed junctions, conduits, or switchboards.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Non-contact tester, multimeter',
      severity: 'critical',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-5',
      name:
          'Verify earthing is available at all switchboards and major sockets',
      category: 'Electrical Work',
      inspectionType: 'Earthing Check',
      description:
          'Confirm earth continuity at switchboards, appliance points, geyser sockets, and AC points.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Socket tester, multimeter',
      severity: 'critical',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-6',
      name: 'Test MCB and ELCB tripping and verify circuit labeling',
      category: 'Electrical Work',
      inspectionType: 'Protection Device Check',
      description:
          'Check MCB/ELCB operation, room-wise marking, and whether labeling matches the actual connected load.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'MCB/ELCB tester or manual test button',
      severity: 'critical',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-7',
      name:
          'Operate all switches and buttons to identify hard or loose operation',
      category: 'Electrical Work',
      inspectionType: 'Switch Operation Check',
      description:
          'Press each accessible switch and note stiffness, loose plates, sparking, or damaged modules.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Manual check',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-8',
      name:
          'Inspect plumbing fixtures for leakage at corners, joints, and traps',
      category: 'Plumbing & Fixtures',
      inspectionType: 'Leakage Check',
      description:
          'Check under-sink areas, bottle traps, shower points, flush tanks, angle valves, and exposed pipe joints for leakage.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera, tissue/wipe, flashlight',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-9',
      name:
          'Check doors for alignment, lock operation, stopper, and frame gaps',
      category: 'Doors',
      inspectionType: 'Door Function Check',
      description:
          'Open, close, latch, and lock each door. Record rubbing, misalignment, missing stopper, damaged hardware, or frame gaps.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Manual check',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-10',
      name:
          'Check windows for alignment, damaged glass, gaps, and hard operation',
      category: 'Windows',
      inspectionType: 'Window Function Check',
      description:
          'Operate all window panels and inspect glass, tracks, locks, sealant, outer frame gaps, and rainwater entry points.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Manual check, device camera',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-11',
      name:
          'Inspect walls and ceiling for cracks, uneven finish, dampness, and hollowness',
      category: 'Walls & Ceiling',
      inspectionType: 'Surface Condition Check',
      description:
          'Check visible wall and ceiling surfaces for hairline cracks, bulges, damp patches, poor plaster finish, and hollow sound.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera, tapping tool if available',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-12',
      name:
          'Check flooring tiles for cracks, hollow sound, lippage, and slope issues',
      category: 'Flooring',
      inspectionType: 'Floor Finish Check',
      description:
          'Inspect tile joints, cracked tiles, uneven levels, hollow tiles, slope toward drains, and skirting finish.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Tapping tool, spirit level if available',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-13',
      name:
          'Inspect painting finish near corners, windows, doors, and repaired patches',
      category: 'Painting',
      inspectionType: 'Paint Finish Check',
      description:
          'Look for roller marks, patchiness, peeling, staining, overspray, cracks near openings, and poor edge finishing.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera',
      severity: 'low',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-14',
      name:
          'Check dado tiles for cracks, hollow sound, grout gaps, and alignment',
      category: 'Dado',
      inspectionType: 'Wall Tile Check',
      description:
          'Inspect kitchen and bathroom wall tiles for cracks, hollow sound, missing grout, chipped edges, and uneven alignment.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Tapping tool, device camera',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-15',
      name:
          'Inspect woodwork shutters, drawers, hinges, laminate edges, and handles',
      category: 'Woodwork',
      inspectionType: 'Carpentry Finish Check',
      description:
          'Operate cabinets and wardrobes. Check alignment, hinge noise, handle fixing, laminate peeling, edge banding, and scratches.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Manual check',
      severity: 'low',
      completed: false,
    ),
    InspectionItem(
      id: 'sample-report-16',
      name:
          'Check granite and marble frames for cracks, chips, gaps, and polish finish',
      category: 'Granite/Marble Frame',
      inspectionType: 'Stone Finish Check',
      description:
          'Inspect stone frames, sills, thresholds, and counters for cracks, chips, joint gaps, stains, and uneven polish.',
      howTo: 'Source: PropCheckup-style sample report category',
      equipmentNeeded: 'Device camera, manual check',
      severity: 'medium',
      completed: false,
    ),
  ];

  return InspectionArea(
    id: 'area-sample-report-checks',
    name: 'Sample Report Checks',
    icon: 'fact_check',
    templateKey: 'sample-report-checks',
    progress: 0,
    status: 'pending',
    issues: items.length,
    completed: 0,
    items: items,
  );
}

InspectionArea latestSafetyChecksAreaArchive() {
  const items = [
    InspectionItem(
      id: 'latest-safety-1',
      name:
          'Verify all captured issue photos are live camera evidence with visible context',
      category: 'Evidence Quality',
      inspectionType: 'Fraud Prevention Check',
      description:
          'Confirm evidence photos clearly show the actual issue, room context, and no gallery/imported images were used.',
      howTo: 'Source: Latest KEPR inspection control requirement',
      equipmentNeeded: 'Device camera',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'latest-safety-2',
      name:
          'Confirm next inspection due date is after the conducted inspection date',
      category: 'Inspection Governance',
      inspectionType: 'Schedule Validation',
      description:
          'Validate that the next inspection date/time is later than the current conducted inspection timestamp.',
      howTo: 'Source: Latest KEPR inspection control requirement',
      equipmentNeeded: 'Inspection app',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'latest-safety-3',
      name:
          'Check that every resident-facing URL opens and belongs to Supabase storage',
      category: 'Resident App Readiness',
      inspectionType: 'URL Validation',
      description:
          'Verify uploaded photo/report links are valid public URLs before submission.',
      howTo: 'Source: Latest KEPR inspection control requirement',
      equipmentNeeded: 'Inspection app',
      severity: 'high',
      completed: false,
    ),
    InspectionItem(
      id: 'latest-safety-4',
      name:
          'Review custom quote items and confirm no matching catalog service exists',
      category: 'Service Quality',
      inspectionType: 'Custom Quote Validation',
      description:
          'Use Custom Quote only when the live service catalog does not contain a suitable service.',
      howTo: 'Source: Latest KEPR inspection control requirement',
      equipmentNeeded: 'Service catalog search',
      severity: 'medium',
      completed: false,
    ),
    InspectionItem(
      id: 'latest-safety-5',
      name:
          'Confirm annotated images highlight the exact defect location for critical issues',
      category: 'Evidence Quality',
      inspectionType: 'Image Annotation Review',
      description:
          'Critical issue images should include tap/draw annotation where it helps identify the issue quickly.',
      howTo: 'Source: Latest KEPR inspection control requirement',
      equipmentNeeded: 'Device camera, annotation tool',
      severity: 'high',
      completed: false,
    ),
  ];

  return InspectionArea(
    id: 'area-latest-safety-checks',
    name: 'Latest Safety Checks',
    icon: 'verified',
    templateKey: 'latest-safety-checks',
    progress: 0,
    status: 'pending',
    issues: items.length,
    completed: 0,
    items: items,
  );
}
