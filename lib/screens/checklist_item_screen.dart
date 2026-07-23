import 'dart:convert';
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
import 'image_annotation_screen.dart';

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
  late TextEditingController serviceSearchController;
  late List<String> photoNames;
  late List<String> photoEvidenceBase64;
  List<ServiceMatch> serviceMatches = const [];
  ServiceMatch? selectedService;
  List<ServiceMatch> selectedServices = const [];
  bool _isLoadingServices = false;
  bool _isCapturingPhoto = false;
  bool _showServiceOptions = false;
  int _serviceSearchToken = 0;
  final int maxChars = 500;

  @override
  void initState() {
    super.initState();
    selectedSeverity = (widget.item.severity ?? 'medium').toLowerCase();
    notesController = TextEditingController(text: widget.item.notes);
    photoNames = [...widget.item.photoPaths];
    photoEvidenceBase64 = [...widget.item.photoEvidenceBase64];
    selectedServices = widget.item.selectedServices
        .map(ServiceMatch.fromSelected)
        .toList(growable: false);
    if (selectedServices.isNotEmpty) {
      selectedService = selectedServices.first;
    }
    serviceMatches = selectedService == null ? const [] : [selectedService!];
    serviceSearchController = TextEditingController(
      text: widget.item.serviceCode ?? '',
    );
    _loadRelatedServices();
  }

  @override
  void dispose() {
    notesController.dispose();
    serviceSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadRelatedServices({String? query}) async {
    if (!_needsServiceEstimate) return;
    final token = ++_serviceSearchToken;
    setState(() => _isLoadingServices = true);
    try {
      final matches = query == null
          ? await SupabaseRepository.instance
              .searchServicesForInspectionItem(widget.item)
          : await SupabaseRepository.instance.searchServices(
              query: query,
              limit: 20,
            );
      if (!mounted || token != _serviceSearchToken) return;
      setState(() {
        serviceMatches = matches;
        if (selectedService == null ||
            !matches.any(
              (match) => match.serviceCode == selectedService!.serviceCode,
            )) {
          selectedService = _pickInitialService(matches);
        }
      });
    } finally {
      if (mounted && token == _serviceSearchToken) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  ServiceMatch? _pickInitialService(List<ServiceMatch> matches) {
    if (matches.isEmpty) {
      return null;
    }
    final existingCode = widget.item.serviceCode;
    if (existingCode != null) {
      for (final match in matches) {
        if (match.serviceCode == existingCode) return match;
      }
    }
    return matches.first;
  }

  double get _selectedServicesTotal => selectedServices.fold<double>(
        0,
        (sum, service) => sum + service.estimatedCost,
      );

  List<String> get _selectedMaterialCodes {
    return selectedServices
        .expand((service) => service.materialCodes)
        .toSet()
        .toList();
  }

  String? get _selectedServiceCodes {
    if (selectedServices.isEmpty) return null;
    return selectedServices.map((service) => service.serviceCode).join(', ');
  }

  bool get _requiresPhotoEvidence =>
      selectedSeverity == 'high' || selectedSeverity == 'critical';

  bool get _hasMissingRequiredPhotos =>
      _requiresPhotoEvidence && photoNames.isEmpty;

  bool get _canMarkCompleted => !_hasMissingRequiredPhotos;

  bool get _isCriticalWithoutService =>
      selectedSeverity == 'critical' && selectedServices.isEmpty;

  bool get _requiresTechnicianNotes =>
      selectedSeverity == 'high' || selectedSeverity == 'critical';

  bool get _isMissingRequiredNotes =>
      _requiresTechnicianNotes && notesController.text.trim().isEmpty;

  void _toggleService(ServiceMatch service) {
    setState(() {
      final exists = selectedServices.any(
        (selected) => selected.serviceCode == service.serviceCode,
      );
      if (exists) {
        selectedServices = selectedServices
            .where((selected) => selected.serviceCode != service.serviceCode)
            .toList(growable: false);
      } else {
        selectedServices = [...selectedServices, service];
      }
      selectedService = selectedServices.isEmpty ? null : selectedServices.last;
      serviceSearchController.clear();
      _showServiceOptions = true;
    });
  }

  Future<void> _addConsultationService() async {
    setState(() => _isLoadingServices = true);
    try {
      final matches = await SupabaseRepository.instance.searchServices(
        query: 'consultation general',
        limit: 30,
      );
      ServiceMatch? consultation;
      for (final service in matches) {
        final text =
            '${service.name} ${service.serviceCode} ${service.description ?? ''}'
                .toLowerCase();
        if (text.contains('consult') || text.contains('general')) {
          consultation = service;
          break;
        }
      }
      if (!mounted) return;
      if (consultation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Consultation service is missing in DB. Add it under General services first.',
            ),
          ),
        );
        return;
      }
      final selectedConsultation = consultation;
      setState(() {
        selectedServices = [
          ...selectedServices.where(
            (service) =>
                service.serviceCode != selectedConsultation.serviceCode,
          ),
          selectedConsultation,
        ];
        selectedService = selectedConsultation;
        serviceSearchController.text = selectedConsultation.name;
        _showServiceOptions = false;
      });
    } finally {
      if (mounted) setState(() => _isLoadingServices = false);
    }
  }

  void _showServicesNotAddedPopup() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Services not added'),
        content: const Text(
          'Critical issues must have at least one service selected. Select a catalog service or add Consultation from the General service catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addConsultationService();
            },
            child: const Text('Add Consultation'),
          ),
        ],
      ),
    );
  }

  void _showTechnicianNotesRequiredPopup() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Technician notes required'),
        content: const Text(
          'High and critical issues must include technician notes before marking complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPhotoRequiredPopup() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo required'),
        content: const Text(
          'High and critical issues must include at least one live photo before marking complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

      if (!mounted) return;
      final annotatedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageAnnotationScreen(bytes: result.bytes),
        ),
      );
      if (annotatedBytes == null) {
        if (!mounted) return;
        setState(() => _isCapturingPhoto = false);
        return;
      }

      final compressedBytes = _compressPhoto(annotatedBytes);
      final localEvidence = base64Encode(compressedBytes);
      String? photoId;
      Object? uploadError;
      try {
        photoId = await SupabaseRepository.instance.saveInspectionPhoto(
          bytes: compressedBytes,
          fileName: result.fileName,
          itemId: widget.item.id,
          itemName: widget.item.name,
          keprId: InspectionSession.keprId,
          societyName: InspectionSession.societyName,
          flatNumber: InspectionSession.flatNumber,
          propertyId: InspectionSession.propertyId,
          inspectionId: InspectionSession.inspectionId,
          areaName: widget.areaName,
        );
      } catch (error) {
        uploadError = error;
      }

      if (!mounted) return;
      setState(() {
        photoEvidenceBase64.add(localEvidence);
        if (photoId != null) {
          photoNames.add(photoId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadError == null
                ? 'Live photo uploaded to Supabase and saved'
                : 'Photo saved locally only. It will appear in PDF, but final submit needs Supabase upload. $uploadError',
          ),
        ),
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

    var width = decoded.width > 960 ? 960 : decoded.width;
    var quality = 62;
    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(
        decoded.width > width ? img.copyResize(decoded, width: width) : decoded,
        quality: quality,
      ),
    );

    while (encoded.length > 50 * 1024 && (quality > 34 || width > 560)) {
      if (quality > 34) {
        quality -= 8;
      } else {
        width = (width * 0.82).round().clamp(420, width).toInt();
      }
      final resized = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;
      encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return encoded;
  }

  String _photoLabel(String value) {
    final uri = Uri.tryParse(value);
    final segment =
        uri == null || uri.pathSegments.isEmpty ? value : uri.pathSegments.last;
    return segment.length <= 28 ? segment : '${segment.substring(0, 25)}...';
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
                      const SizedBox.shrink(),
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
                            label: Text(_photoLabel(photoName)),
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
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: _buildSeverityButton(
                      'No Issues',
                      'no_issue',
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the severity level based on the observed issue',
                    style:
                        AppStyles.bodySm.copyWith(color: AppColors.neutral500),
                  ),
                  if (_requiresPhotoEvidence && photoNames.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'At least 1 live photo is required for high and critical issues.',
                      style: AppStyles.bodySm.copyWith(color: AppColors.error),
                    ),
                  ],
                  if (_needsServiceEstimate) ...[
                    const SizedBox(height: 16),
                    _buildServiceEstimateCard(),
                  ],
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
                  if (_requiresTechnicianNotes) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Required for high and critical issues.',
                      style: AppStyles.bodySm.copyWith(
                        color: _isMissingRequiredNotes
                            ? AppColors.error
                            : AppColors.neutral500,
                      ),
                    ),
                  ],
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
                      enabled: _canMarkCompleted,
                      onPressed: () {
                        if (_hasMissingRequiredPhotos) {
                          _showPhotoRequiredPopup();
                          return;
                        }
                        if (_isMissingRequiredNotes) {
                          _showTechnicianNotesRequiredPopup();
                          return;
                        }
                        if (_isCriticalWithoutService) {
                          _showServicesNotAddedPopup();
                          return;
                        }
                        Navigator.pop(
                          context,
                          widget.item.copyWith(
                            completed: true,
                            severity: selectedSeverity,
                            notes: notesController.text,
                            photoPaths: photoNames,
                            photoEvidenceBase64: photoEvidenceBase64,
                            serviceCode: _needsServiceEstimate
                                ? _selectedServiceCodes
                                : null,
                            estimatedCost: _needsServiceEstimate
                                ? _selectedServicesTotal
                                : null,
                            materialCodes: _needsServiceEstimate
                                ? _selectedMaterialCodes
                                : const [],
                            selectedServices: _needsServiceEstimate
                                ? selectedServices
                                    .map((service) => service.toSelected())
                                    .toList(growable: false)
                                : const [],
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

  bool get _needsServiceEstimate =>
      selectedSeverity == 'high' || selectedSeverity == 'critical';

  Widget _buildServiceEstimateCard() {
    final visibleMatches = serviceMatches;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.home_repair_service,
            color: Color(0xFF92400E),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Related services',
                  style: AppStyles.labelMd.copyWith(
                    color: const Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: serviceSearchController,
                  onTap: () {
                    setState(() => _showServiceOptions = true);
                    if (serviceMatches.length <= 1) {
                      _loadRelatedServices(query: serviceSearchController.text);
                    }
                  },
                  onChanged: (value) {
                    setState(() {
                      _showServiceOptions = true;
                      if (selectedService != null &&
                          value.trim() != selectedService!.name &&
                          value.trim() != selectedService!.serviceCode) {
                        selectedService = null;
                      }
                    });
                    _loadRelatedServices(query: value);
                  },
                  decoration: AppStyles.buildInputDecoration(
                    hint: 'Search service name or code',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: serviceSearchController.text.isEmpty
                        ? const Icon(Icons.expand_more)
                        : IconButton(
                            tooltip: 'Clear service',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                selectedService = null;
                                serviceSearchController.clear();
                                _showServiceOptions = true;
                              });
                              _loadRelatedServices(query: '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoadingServices
                      ? 'Searching service catalog...'
                      : selectedServices.isEmpty
                          ? selectedSeverity == 'critical'
                              ? 'Critical issue: service selection is compulsory.'
                              : 'Select one or more services to attach to this issue.'
                          : '${selectedServices.length} services selected - Rs ${_selectedServicesTotal.toStringAsFixed(0)}',
                  style: AppStyles.bodySm.copyWith(
                    color: const Color(0xFF92400E),
                  ),
                ),
                if (selectedServices.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final service in selectedServices)
                        Chip(
                          label: Text(
                            '${service.serviceCode} - Rs ${service.estimatedCost.toStringAsFixed(0)}',
                          ),
                          onDeleted: () => _toggleService(service),
                        ),
                    ],
                  ),
                ],
                if (!_isLoadingServices &&
                    _showServiceOptions &&
                    visibleMatches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: visibleMatches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final match = visibleMatches[index];
                        final isSelected = selectedServices.any(
                          (service) => service.serviceCode == match.serviceCode,
                        );
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          leading: Icon(
                            isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: const Color(0xFF92400E),
                          ),
                          title: Text(
                            '${match.name} (${match.serviceCode})',
                            style: AppStyles.bodySm.copyWith(
                              color: const Color(0xFF78350F),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: match.description == null
                              ? null
                              : Text(
                                  match.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: Text(
                            'Rs ${match.estimatedCost.toStringAsFixed(0)}',
                            style: AppStyles.labelSm.copyWith(
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          onTap: () {
                            _toggleService(match);
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (!_isLoadingServices &&
                    _showServiceOptions &&
                    visibleMatches.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      'No matching services found. Add Consultation from the General service catalog.',
                      style: AppStyles.bodySm.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: KeprButton(
                      label: 'Add Consultation',
                      variant: ButtonVariant.secondary,
                      icon: const Icon(Icons.support_agent),
                      onPressed: _addConsultationService,
                    ),
                  ),
                ],
                if (_selectedMaterialCodes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Materials ${_selectedMaterialCodes.join(', ')}',
                    style: AppStyles.bodySm.copyWith(
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityButton(String label, String value, Color color) {
    final isSelected = selectedSeverity == value;
    return GestureDetector(
      onTap: () {
        final wasEstimate = _needsServiceEstimate;
        setState(() => selectedSeverity = value);
        if (!wasEstimate && _needsServiceEstimate) {
          _loadRelatedServices();
        }
      },
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
