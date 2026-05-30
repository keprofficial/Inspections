import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/kepr_button.dart';
import 'checklist_item_screen.dart';

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
  }

  int get completedCount => items.where((item) => item.completed).length;

  int get progress =>
      items.isEmpty ? 0 : ((completedCount / items.length) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.coral,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: _closeWithCurrentArea,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              '${items.length} parameter checks',
              style: AppStyles.labelSm.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '$completedCount/${items.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(items[index], index);
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft saved!')),
                      ),
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
        ],
      ),
    );
  }

  Future<void> _submitSection() async {
    final currentArea = _currentArea();
    setState(() => _isSubmitting = true);
    try {
      final inspectionId = InspectionSession.inspectionId;
      if (inspectionId != null) {
        await SupabaseRepository.instance.submitArea(
          inspectionId: inspectionId,
          area: currentArea,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section submitted!')),
      );
      Navigator.pop(context, currentArea);
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
    Navigator.pop(context, _currentArea());
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppColors.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section Progress',
                style: AppStyles.labelMd.copyWith(color: AppColors.navy),
              ),
              Text(
                '$progress%',
                style: AppStyles.bodyLg.copyWith(
                  color: AppColors.coral,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${items.length - completedCount} items remaining in ${widget.area.name}',
            style: AppStyles.bodySm.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation(AppColors.coral),
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
      },
      child: Opacity(
        opacity: item.completed ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neutral200),
            boxShadow: AppColors.shadowSm,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: item.completed
                        ? AppColors.success
                        : AppColors.neutral300,
                    width: 2,
                  ),
                  color: item.completed ? AppColors.success : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: item.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} - ${severity.toUpperCase()}',
                      style: AppStyles.bodySm.copyWith(
                        color: _severityColor(severity),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.neutral500;
    }
  }
}
