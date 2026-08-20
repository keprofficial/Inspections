import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/inspection_icons.dart';
import '../models/models.dart';
import '../services/inspection_draft_storage.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/kepr_button.dart';
import 'checklist_item_screen.dart';

class InspectionAreaScreenResult {
  final InspectionArea area;
  final bool finalizeIndividualReport;

  const InspectionAreaScreenResult({
    required this.area,
    this.finalizeIndividualReport = false,
  });
}

class InspectionAreaScreen extends StatefulWidget {
  final InspectionArea area;

  const InspectionAreaScreen({
    Key? key,
    required this.area,
  }) : super(key: key);

  @override
  State<InspectionAreaScreen> createState() => _InspectionAreaScreenState();
}

class _InspectionAreaScreenState extends State<InspectionAreaScreen> {
  late List<InspectionItem> items;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    items = [...widget.area.items];
    InspectionDraftStorage.setActiveAreaPage(widget.area.id);
  }

  int get completedCount => items.where((item) => item.completed).length;

  int get progress =>
      items.isEmpty ? 0 : ((completedCount / items.length) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Builder(
          builder: (context) {
            final areaColor = iconColorFor(widget.area.icon);
            final darkColor =
                Color.lerp(areaColor, Colors.black, 0.35) ?? areaColor;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [areaColor, darkColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon:
                      const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _closeWithCurrentArea,
                ),
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        iconDataFor(widget.area.icon),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.area.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length} checks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Text(
                        '$completedCount/${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index], index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.neutral200)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: KeprButton(
                  label: 'SAVE DRAFT',
                  variant: ButtonVariant.secondary,
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KeprButton(
                  label: 'SUBMIT SECTION',
                  isLoading: _isSubmitting,
                  onPressed: _submitSection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSection() async {
    final currentArea = _currentArea();
    setState(() => _isSubmitting = true);
    try {
      await _persistCurrentArea(currentArea);
      final inspectionId = InspectionSession.inspectionId;
      if (inspectionId != null) {
        await SupabaseRepository.instance.submitArea(
          inspectionId: inspectionId,
          area: currentArea,
        );
      }
      await InspectionDraftStorage.setActiveInspectionPage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section submitted!')),
      );
      Navigator.pop(
        context,
        InspectionAreaScreenResult(
          area: currentArea,
          finalizeIndividualReport: InspectionSession.isIndividualInspection,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit section: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _closeWithCurrentArea() {
    _persistCurrentArea(_currentArea());
    InspectionDraftStorage.setActiveInspectionPage();
    Navigator.pop(
      context,
      InspectionAreaScreenResult(area: _currentArea()),
    );
  }

  Future<void> _saveDraft() async {
    await _persistCurrentArea(_currentArea());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }

  Future<void> _persistCurrentArea(InspectionArea area) async {
    await InspectionDraftStorage.saveSession();
    await InspectionDraftStorage.saveArea(area);
    final areas = await InspectionDraftStorage.loadAreas();
    if (areas == null || areas.isEmpty) return;
    await SupabaseRepository.instance.saveInspectionDraft(areas: areas);
  }

  InspectionArea _currentArea() {
    return widget.area.copyWith(
      items: items,
      progress: progress,
      completed: completedCount,
      issues: items.length - completedCount,
      status: progress == 100 ? 'completed' : 'in-progress',
    );
  }

  Widget _buildProgressCard() {
    final areaColor = iconColorFor(widget.area.icon);
    final remaining = items.length - completedCount;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowMd,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          areaIconBox(widget.area.icon, size: 56, iconSize: 28, radius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.area.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining == 0
                      ? 'All checks complete!'
                      : '$remaining of ${items.length} checks remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: remaining == 0
                        ? AppColors.success
                        : AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.neutral100,
                    valueColor: AlwaysStoppedAnimation(
                      progress == 100 ? AppColors.success : areaColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$progress%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: progress == 100 ? AppColors.success : areaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InspectionItem item, int index) {
    final severity = (item.severity ?? 'medium').toLowerCase();

    return GestureDetector(
      onTap: () async {
        final updatedItem = await Navigator.push<InspectionItem>(
          context,
          MaterialPageRoute(
            builder: (context) => ChecklistItemScreen(
              item: item,
              areaName: widget.area.name,
            ),
          ),
        );
        if (updatedItem == null) return;
        setState(() {
          items[index] = updatedItem;
        });
        await _persistCurrentArea(_currentArea());
      },
      child: Opacity(
        opacity: item.completed ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Severity left strip
                Container(
                  width: 5,
                  color: item.completed
                      ? AppColors.success
                      : _severityColor(severity),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        // Severity icon badge
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (item.completed
                                    ? AppColors.success
                                    : _severityColor(severity))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.completed
                                ? Icons.check_circle_rounded
                                : severityIcon(severity),
                            color: item.completed
                                ? AppColors.success
                                : _severityColor(severity),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _severityColor(severity)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      severity.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _severityColor(severity),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.neutral500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if ((item.serviceCode ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Rs ${item.estimatedCost?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.neutral300,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _severityColor(String s) => severityColor(s);
}
