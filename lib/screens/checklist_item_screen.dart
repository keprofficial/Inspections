import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/badge.dart';
import '../widgets/kepr_button.dart';
import 'camera_capture_screen.dart';

class ChecklistItemScreen extends StatefulWidget {
  final InspectionItem item;
  final String areaName;

  const ChecklistItemScreen({
    Key? key,
    required this.item,
    required this.areaName,
  }) : super(key: key);

  @override
  State<ChecklistItemScreen> createState() => _ChecklistItemScreenState();
}

class _ChecklistItemScreenState extends State<ChecklistItemScreen> {
  late String selectedSeverity;
  late TextEditingController notesController;
  late List<String> photoNames;
  bool _isCapturingPhoto = false;
  final int maxChars = 500;

  @override
  void initState() {
    super.initState();
    selectedSeverity = (widget.item.severity ?? 'medium').toLowerCase();
    notesController = TextEditingController(text: widget.item.notes);
    photoNames = [...widget.item.photoPaths];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      setState(() => _isCapturingPhoto = true);

      final result = await Navigator.push<CapturedInspectionPhoto>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraCaptureScreen(itemId: widget.item.id),
        ),
      );

      if (result == null) {
        if (!mounted) return;
        setState(() => _isCapturingPhoto = false);
        return;
      }

      final compressedBytes = _compressPhoto(result.bytes);
      final photoId = await SupabaseRepository.instance.saveInspectionPhoto(
        bytes: compressedBytes,
        fileName: result.fileName,
        itemId: widget.item.id,
        keprId: InspectionSession.keprId,
        societyName: InspectionSession.societyName,
        flatNumber: InspectionSession.flatNumber,
        propertyId: InspectionSession.propertyId,
        inspectionId: InspectionSession.inspectionId,
        areaName: widget.areaName,
      );

      if (!mounted) return;
      setState(() {
        photoNames.add(photoId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live photo captured and saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo capture failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  Uint8List _compressPhoto(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final resized =
        decoded.width > 1280 ? img.copyResize(decoded, width: 1280) : decoded;

    return Uint8List.fromList(img.encodeJpg(resized, quality: 68));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.areaName,
          style: AppStyles.labelMd.copyWith(color: AppColors.navy),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(
                    label: widget.item.category.toUpperCase(),
                    variant: BadgeVariant.info,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.inspectionType.isEmpty
                                  ? 'Inspection Parameter'
                                  : widget.item.inspectionType,
                              style: AppStyles.displayLg.copyWith(
                                fontSize: 28,
                                color: AppColors.navy,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.item.name,
                              style: AppStyles.bodyMd.copyWith(
                                color: AppColors.neutral700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        label: widget.item.id.toUpperCase(),
                        variant: BadgeVariant.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: _isCapturingPhoto
                          ? 'Capturing...'
                          : 'Capture Live Photo',
                      icon: const Icon(Icons.photo_camera, color: Colors.white),
                      isLoading: _isCapturingPhoto,
                      onPressed: _isCapturingPhoto ? null : _capturePhoto,
                    ),
                  ),
                  if (photoNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final photoName in photoNames)
                          Chip(
                            avatar: const Icon(Icons.image, size: 18),
                            label: Text(photoName),
                            onDeleted: () {
                              setState(() => photoNames.remove(photoName));
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Issue Severity',
                    style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildSeverityButton('Low', 'low', Colors.green),
                      _buildSeverityButton('Medium', 'medium', Colors.orange),
                      _buildSeverityButton('High', 'high', AppColors.error),
                      _buildSeverityButton(
                        'Critical',
                        'critical',
                        Colors.red.shade900,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the severity level based on the observed issue',
                    style:
                        AppStyles.bodySm.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.construction,
                    title: 'Equipment Needed',
                    body: widget.item.equipmentNeeded.isEmpty
                        ? 'Manual check'
                        : widget.item.equipmentNeeded,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.lightbulb,
                    title: 'Inspection Guidance',
                    body: widget.item.description,
                  ),
                  if (widget.item.howTo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.fact_check,
                      title: 'Reference',
                      body: widget.item.howTo,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Technician Notes',
                    style: AppStyles.labelMd.copyWith(color: AppColors.navy),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 6,
                    maxLength: maxChars,
                    onChanged: (_) => setState(() {}),
                    decoration: AppStyles.buildInputDecoration(
                      hint:
                          'Describe condition, test results, and required action...',
                    ),
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
                      label: 'Cancel',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeprButton(
                      label: 'Mark Completed',
                      icon: const Icon(Icons.check, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          widget.item.copyWith(
                            completed: true,
                            severity: selectedSeverity,
                            notes: notesController.text,
                            photoPaths: photoNames,
                          ),
                        );
                      },
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

  Widget _buildSeverityButton(String label, String value, Color color) {
    final isSelected = selectedSeverity == value;
    return GestureDetector(
      onTap: () => setState(() => selectedSeverity = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyles.labelSm.copyWith(
              color: isSelected ? Colors.white : AppColors.neutral700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1E40AF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.labelMd.copyWith(
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppStyles.bodySm.copyWith(
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
