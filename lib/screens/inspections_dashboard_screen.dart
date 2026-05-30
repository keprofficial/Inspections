import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../data/inspection_checklist_data.dart';
import '../models/models.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/badge.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/kepr_button.dart';
import '../widgets/kepr_header.dart';
import 'inspection_area_screen.dart';
import 'profile_screen.dart';

class InspectionsDashboardScreen extends StatefulWidget {
  const InspectionsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InspectionsDashboardScreen> createState() =>
      _InspectionsDashboardScreenState();
}

class _InspectionsDashboardScreenState
    extends State<InspectionsDashboardScreen> {
  BottomNavTab activeTab = BottomNavTab.inspections;
  late final TextEditingController searchController;
  late List<InspectionArea> areas;
  bool _isGeneratingReport = false;

  int get completedItems => areas.fold(
        0,
        (sum, area) => sum + area.items.where((item) => item.completed).length,
      );

  int get totalItems => areas.fold(0, (sum, area) => sum + area.items.length);

  int get overallProgress =>
      totalItems == 0 ? 0 : ((completedItems / totalItems) * 100).round();

  int get pendingItems => totalItems - completedItems;

  List<InspectionArea> get filteredAreas {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return areas;
    return areas
        .where(
          (area) =>
              area.name.toLowerCase().contains(query) ||
              area.items.any(
                (item) =>
                    item.name.toLowerCase().contains(query) ||
                    item.category.toLowerCase().contains(query),
              ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()
      ..addListener(() => setState(() {}));
    areas = buildDefaultInspectionAreas();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (activeTab == BottomNavTab.profile) {
      return ProfileScreen(
        onTabChange: (tab) => setState(() => activeTab = tab),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: const KeprHeader(
        title: 'Kepr',
        subtitle: '402',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(),
                  const SizedBox(height: 20),
                  _buildSearchRow(),
                  const SizedBox(height: 20),
                  _buildAreasHeader(),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, index) {
                      return _buildAreaCard(filteredAreas[index]);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Add Area',
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _showAddAreaSheet,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Generate Report',
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      isLoading: _isGeneratingReport,
                      onPressed: _generateReport,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeTab: activeTab,
              onTabChange: (tab) => setState(() => activeTab = tab),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    final propertyId = InspectionSession.propertyId;
    final inspectionId = InspectionSession.inspectionId;
    if (propertyId == null || inspectionId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated locally. Login is bypassed for now.'),
        ),
      );
      return;
    }

    setState(() => _isGeneratingReport = true);
    try {
      final reportId = await SupabaseRepository.instance.submitReport(
        propertyId: propertyId,
        inspectionId: inspectionId,
        areas: areas,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report generated: $reportId')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Widget _buildProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: overallProgress / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$overallProgress%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'DONE',
                      style: AppStyles.labelSm.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Villa 402 - Annual Audit',
                  style: AppStyles.headlineMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dynamic checklist from KEPR Excel',
                  style: AppStyles.bodySm.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(
                      label: '$completedItems Completed',
                      variant: BadgeVariant.success,
                    ),
                    AppBadge(
                      label: '${areas.length} Areas',
                      variant: BadgeVariant.warning,
                    ),
                    AppBadge(
                      label: '$pendingItems Pending',
                      variant: BadgeVariant.error,
                    ),
                    AppBadge(
                      label: '$totalItems Checks',
                      variant: BadgeVariant.default_,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: AppStyles.buildInputDecoration(
              hint: 'Search areas or parameters...',
              prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAddAreaSheet,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.add, color: AppColors.navy),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreasHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'INSPECTION AREAS (${filteredAreas.length})',
            style: AppStyles.labelSm.copyWith(
              color: AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAddAreaSheet,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add area'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.coral,
            textStyle: AppStyles.labelMd,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard(InspectionArea area) {
    final completedCount = area.items.where((item) => item.completed).length;
    final pendingCount = area.items.length - completedCount;
    final progress = area.items.isEmpty
        ? 0
        : ((completedCount / area.items.length) * 100).round();
    final isUrgent = area.items
        .any((item) => (item.severity ?? '').toLowerCase() == 'critical');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? const Color(0xFFdc2626) : AppColors.neutral200,
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: AppColors.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final updatedArea = await Navigator.push<InspectionArea>(
              context,
              MaterialPageRoute(
                builder: (context) => InspectionAreaScreen(area: area),
              ),
            );
            if (updatedArea == null) return;
            setState(() {
              final index =
                  areas.indexWhere((candidate) => candidate.id == area.id);
              if (index != -1) areas[index] = updatedArea;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _iconFor(area.icon),
                  color: AppColors.coral,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.name,
                        style:
                            AppStyles.labelMd.copyWith(color: AppColors.navy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrgent
                            ? 'Critical checks included'
                            : '$pendingCount Pending - ${area.items.length} checks',
                        style: AppStyles.bodySm.copyWith(
                          color:
                              isUrgent ? AppColors.error : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$progress%',
                      style: AppStyles.labelMd.copyWith(
                        color: progress == 100
                            ? const Color(0xFF10B981)
                            : AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (progress == 100)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 20,
                      )
                    else
                      SizedBox(
                        width: 50,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: AppColors.neutral200,
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.coral),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.neutral400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'kitchen':
        return Icons.kitchen;
      case 'bed':
        return Icons.bed;
      case 'bathroom':
        return Icons.bathroom;
      case 'weekend':
        return Icons.weekend;
      case 'balcony':
        return Icons.balcony;
      case 'door_front_door':
        return Icons.door_front_door;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'water_drop':
        return Icons.water_drop;
      case 'build':
        return Icons.build;
      default:
        return Icons.home_work;
    }
  }

  void _showAddAreaSheet() {
    final nameController = TextEditingController();
    InspectionAreaTemplate selectedTemplate = inspectionAreaTemplates.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add inspection area',
                        style: AppStyles.headlineMd.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Area type',
                    style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<InspectionAreaTemplate>(
                    value: selectedTemplate,
                    isExpanded: true,
                    decoration: AppStyles.buildInputDecoration(),
                    items: [
                      for (final template in inspectionAreaTemplates)
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
                  const SizedBox(height: 16),
                  Text(
                    'Display name',
                    style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: AppStyles.buildInputDecoration(
                      hint: 'e.g. Bedroom 3, Hall, Extra Balcony',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Add Area',
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        final displayName = nameController.text.trim().isEmpty
                            ? selectedTemplate.name
                            : nameController.text.trim();
                        final newArea = InspectionArea(
                          id: 'area-${selectedTemplate.key}-${DateTime.now().millisecondsSinceEpoch}',
                          name: displayName,
                          icon: selectedTemplate.iconName,
                          templateKey: selectedTemplate.key,
                          progress: 0,
                          status: 'pending',
                          issues: selectedTemplate.items.length,
                          completed: 0,
                          items: selectedTemplate.items,
                        );
                        setState(() {
                          areas = [...areas, newArea];
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
