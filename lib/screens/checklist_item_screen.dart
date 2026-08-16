import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../constants/severity.dart';
import '../models/models.dart';
import '../services/inspection_session.dart';
import '../services/supabase_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/kepr_button.dart';
import '../widgets/severity_pill.dart';
import 'camera_capture_screen.dart';
import 'image_annotation_screen.dart';

/// What the item screen hands back to the checklist.
class ChecklistItemResult {
  final InspectionItem item;

  /// Set when the inspector chose "Save & next" — the id of the check to open.
  final String? openNextItemId;

  const ChecklistItemResult({required this.item, this.openNextItemId});
}

/// One captured photo and whether it actually reached Supabase Storage.
///
/// The old screen showed a truncated storage filename in a Chip, which told
/// the inspector nothing, and hid upload failures until final submit.
class _CapturedPhoto {
  final String? base64;
  String? uploadedName;
  bool isRetrying = false;

  _CapturedPhoto({this.base64, this.uploadedName});

  bool get isUploaded => (uploadedName ?? '').isNotEmpty;

  Uint8List? get bytes {
    final data = base64;
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}

class ChecklistItemScreen extends StatefulWidget {
  final InspectionItem item;
  final String areaName;

  /// Used to offer "Save & next" without a round trip to the area list.
  final List<InspectionItem> areaItems;

  const ChecklistItemScreen({
    Key? key,
    required this.item,
    required this.areaName,
    this.areaItems = const [],
  }) : super(key: key);

  @override
  State<ChecklistItemScreen> createState() => _ChecklistItemScreenState();
}

class _ChecklistItemScreenState extends State<ChecklistItemScreen> {
  late String selectedSeverity;
  late TextEditingController notesController;
  late TextEditingController serviceSearchController;
  late ScrollController pageScrollController;
  late FocusNode notesFocusNode;

  final List<_CapturedPhoto> _photos = [];

  List<ServiceMatch> serviceMatches = const [];
  ServiceMatch? selectedService;
  List<ServiceMatch> selectedServices = const [];
  bool _isLoadingServices = false;
  bool _isCapturingPhoto = false;
  bool _showServiceOptions = false;
  bool _guidanceExpanded = false;
  int _serviceSearchToken = 0;
  final int maxChars = 500;

  @override
  void initState() {
    super.initState();
    // Preserves the previous default so an untouched template check still
    // carries its seeded severity.
    selectedSeverity = (widget.item.severity ?? 'medium').toLowerCase();
    notesController = TextEditingController(text: widget.item.notes)
      ..addListener(() => setState(() {}));
    pageScrollController = ScrollController();
    notesFocusNode = FocusNode();
    _restorePhotos();

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

  /// Pairs stored local evidence with stored upload names. Lengths can differ
  /// when an upload failed, so extras on either side are kept, not dropped.
  void _restorePhotos() {
    final evidence = widget.item.photoEvidenceBase64;
    final uploaded = widget.item.photoPaths;
    final count =
        evidence.length > uploaded.length ? evidence.length : uploaded.length;
    for (var i = 0; i < count; i++) {
      _photos.add(
        _CapturedPhoto(
          base64: i < evidence.length ? evidence[i] : null,
          uploadedName: i < uploaded.length ? uploaded[i] : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    serviceSearchController.dispose();
    pageScrollController.dispose();
    notesFocusNode.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- severity

  Severity get _severity =>
      Severity.fromValue(selectedSeverity) ?? Severity.medium;

  bool get _needsServiceEstimate => _severity.hasServiceEstimate;

  List<String> get _uploadedNames => _photos
      .where((photo) => photo.isUploaded)
      .map((photo) => photo.uploadedName!)
      .toList(growable: false);

  List<String> get _localEvidence => _photos
      .where((photo) => (photo.base64 ?? '').isNotEmpty)
      .map((photo) => photo.base64!)
      .toList(growable: false);

  bool get _hasMissingRequiredPhotos =>
      _severity.requiresPhoto && _uploadedNames.isEmpty;

  bool get _isMissingRequiredNotes =>
      _severity.requiresNotes && notesController.text.trim().isEmpty;

  bool get _isCriticalWithoutService =>
      _severity.requiresService && selectedServices.isEmpty;

  bool get _canMarkCompleted => !_hasMissingRequiredPhotos;

  double get _selectedServicesTotal => selectedServices.fold<double>(
        0,
        (sum, service) => sum + service.estimatedCost,
      );

  List<String> get _selectedMaterialCodes => selectedServices
      .expand((service) => service.materialCodes)
      .toSet()
      .toList();

  String? get _selectedServiceCodes {
    if (selectedServices.isEmpty) return null;
    return selectedServices.map((service) => service.serviceCode).join(', ');
  }

  /// The next check in this area that is not yet completed.
  InspectionItem? get _nextIncompleteItem {
    final items = widget.areaItems;
    if (items.isEmpty) return null;
    final index = items.indexWhere((item) => item.id == widget.item.id);
    if (index == -1) return null;
    for (var i = index + 1; i < items.length; i++) {
      if (!items[i].completed) return items[i];
    }
    return null;
  }

  // ------------------------------------------------------------- services

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
    if (matches.isEmpty) return null;
    final existingCode = widget.item.serviceCode;
    if (existingCode != null) {
      for (final match in matches) {
        if (match.serviceCode == existingCode) return match;
      }
    }
    return matches.first;
  }

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
        final text = '${service.name} ${service.serviceCode} '
                '${service.description ?? ''}'
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
              'Consultation service is missing in DB. Add it under General '
              'services first.',
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

  // --------------------------------------------------------------- photos

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
        if (mounted) setState(() => _isCapturingPhoto = false);
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
        if (mounted) setState(() => _isCapturingPhoto = false);
        return;
      }

      final compressedBytes = _compressPhoto(annotatedBytes);
      final photo = _CapturedPhoto(base64: base64Encode(compressedBytes));
      if (!mounted) return;
      setState(() => _photos.add(photo));

      await _uploadPhoto(photo, compressedBytes, result.fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo capture failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  Future<void> _uploadPhoto(
    _CapturedPhoto photo,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final photoId = await SupabaseRepository.instance.saveInspectionPhoto(
        bytes: bytes,
        fileName: fileName,
        itemId: widget.item.id,
        itemName: widget.item.name,
        keprId: InspectionSession.keprId,
        societyName: InspectionSession.societyName,
        flatNumber: InspectionSession.flatNumber,
        propertyId: InspectionSession.propertyId,
        inspectionId: InspectionSession.inspectionId,
        areaName: widget.areaName,
      );
      if (!mounted) return;
      setState(() => photo.uploadedName = photoId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo saved on this device but not uploaded. Tap retry on the '
            'thumbnail. $error',
          ),
        ),
      );
    }
  }

  Future<void> _retryUpload(_CapturedPhoto photo) async {
    final bytes = photo.bytes;
    if (bytes == null) return;
    setState(() => photo.isRetrying = true);
    await _uploadPhoto(
      photo,
      bytes,
      '${widget.item.id}-retry-'
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    if (mounted) setState(() => photo.isRetrying = false);
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

  // --------------------------------------------------------------- popups

  void _showServicesNotAddedPopup() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Services not added'),
        content: const Text(
          'Critical issues must have at least one service selected. Select a '
          'catalog service or add Consultation from the General service '
          'catalog.',
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
          'High and critical issues must include technician notes before '
          'marking complete.',
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
          'High and critical issues must include at least one live photo '
          'before marking complete.',
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

  // ----------------------------------------------------------------- save

  InspectionItem _buildUpdatedItem() {
    return widget.item.copyWith(
      completed: true,
      severity: selectedSeverity,
      notes: notesController.text,
      photoPaths: _uploadedNames,
      photoEvidenceBase64: _localEvidence,
      serviceCode: _needsServiceEstimate ? _selectedServiceCodes : null,
      estimatedCost: _needsServiceEstimate ? _selectedServicesTotal : null,
      materialCodes: _needsServiceEstimate ? _selectedMaterialCodes : const [],
      selectedServices: _needsServiceEstimate
          ? selectedServices
              .map((service) => service.toSelected())
              .toList(growable: false)
          : const [],
    );
  }

  bool _blockedByRequirements() {
    if (_hasMissingRequiredPhotos) {
      _showPhotoRequiredPopup();
      return true;
    }
    if (_isMissingRequiredNotes) {
      _showTechnicianNotesRequiredPopup();
      return true;
    }
    if (_isCriticalWithoutService) {
      _showServicesNotAddedPopup();
      return true;
    }
    return false;
  }

  void _save({bool openNext = false}) {
    if (_blockedByRequirements()) return;
    Navigator.pop(
      context,
      ChecklistItemResult(
        item: _buildUpdatedItem(),
        openNextItemId: openNext ? _nextIncompleteItem?.id : null,
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final position = _positionLabel();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.areaName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.labelMd.copyWith(color: AppColors.navy),
            ),
            Text(
              widget.item.category.isEmpty
                  ? 'Inspection check'
                  : widget.item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.labelSm.copyWith(color: AppColors.neutral600),
            ),
          ],
        ),
        actions: [
          if (position != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  position,
                  style: AppStyles.labelSm.copyWith(
                    color: AppColors.neutral700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListView(
              controller: pageScrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  widget.item.inspectionType.isEmpty
                      ? 'Inspection parameter'
                      : widget.item.inspectionType,
                  style: AppStyles.headlineMd.copyWith(
                    fontSize: 20,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.item.name,
                  style: AppStyles.bodyMd.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildVerdictZone(),
                if (_severity.isIssue) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildEvidenceZone(),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildGuidanceZone(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  String? _positionLabel() {
    final items = widget.areaItems;
    if (items.isEmpty) return null;
    final index = items.indexWhere((item) => item.id == widget.item.id);
    if (index == -1) return null;
    return '${index + 1} of ${items.length}';
  }

  /// Zone 1 — the verdict. Always above the fold, and "No issue" comes first
  /// at full width because it is by far the most common answer.
  Widget _buildVerdictZone() {
    return AppCard(
      elevation: AppElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What did you find?',
            style: AppStyles.labelMd.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SeverityChoice(
            severity: Severity.noIssue,
            prominent: true,
            selected: _severity == Severity.noIssue,
            onTap: () => _selectSeverity(Severity.noIssue),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _severityChoice(Severity.low)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _severityChoice(Severity.medium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _severityChoice(Severity.high)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _severityChoice(Severity.critical)),
            ],
          ),
          if (_severity.requiresPhoto || _severity.requiresService) ...[
            const SizedBox(height: AppSpacing.md),
            _buildRequirementHint(),
          ],
        ],
      ),
    );
  }

  Widget _severityChoice(Severity severity) {
    return SeverityChoice(
      severity: severity,
      selected: _severity == severity,
      onTap: () => _selectSeverity(severity),
    );
  }

  void _selectSeverity(Severity severity) {
    final wasEstimate = _needsServiceEstimate;
    setState(() => selectedSeverity = severity.value);
    if (!wasEstimate && _needsServiceEstimate) {
      _loadRelatedServices();
    }
  }

  /// Requirements are stated the moment a severity is chosen, not discovered
  /// through a dialog after the user presses the wrong button.
  Widget _buildRequirementHint() {
    final needs = <String>[];
    if (_severity.requiresPhoto) needs.add('a photo');
    if (_severity.requiresNotes) needs.add('technician notes');
    if (_severity.requiresService) needs.add('a service');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _severity.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: _severity.color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 17, color: _severity.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${_severity.label} findings need ${_joinWithAnd(needs)} '
              'before you can mark this complete.',
              style: AppStyles.labelSm.copyWith(color: AppColors.neutral700),
            ),
          ),
        ],
      ),
    );
  }

  String _joinWithAnd(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} '
        'and ${parts.last}';
  }

  /// Zone 2 — evidence. Only appears once the finding is an actual issue.
  Widget _buildEvidenceZone() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Evidence',
                  style: AppStyles.labelMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SeverityPill(severity: _severity, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KeprButton(
            label: _isCapturingPhoto ? 'Capturing…' : 'Capture live photo',
            height: AppSizes.minTapTarget,
            icon: const Icon(Icons.photo_camera, color: Colors.white),
            isLoading: _isCapturingPhoto,
            onPressed: _isCapturingPhoto ? null : _capturePhoto,
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildPhotoGrid(),
          ],
          if (_severity.requiresPhoto && _uploadedNames.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'At least one uploaded live photo is required for '
              '${_severity.label.toLowerCase()} findings.',
              style: AppStyles.labelSm.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Technician notes',
                  style: AppStyles.labelMd.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_severity.requiresNotes)
                Text(
                  'Required',
                  style: AppStyles.labelSm.copyWith(
                    color: _isMissingRequiredNotes
                        ? AppColors.error
                        : AppColors.neutral600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: notesController,
            focusNode: notesFocusNode,
            maxLines: 5,
            maxLength: maxChars,
            style: AppStyles.bodyMd.copyWith(
              color: AppColors.navy,
              height: 1.4,
            ),
            cursorColor: AppColors.coral,
            decoration: AppStyles.buildInputDecoration(
              hint: 'Describe condition, test results, and required action…',
              errorText: _isMissingRequiredNotes ? null : null,
            ),
          ),
          if (_needsServiceEstimate) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildServiceEstimateCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final photo in _photos) _buildPhotoThumb(photo),
      ],
    );
  }

  Widget _buildPhotoThumb(_CapturedPhoto photo) {
    final bytes = photo.bytes;
    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: photo.isUploaded
                        ? AppColors.success
                        : AppColors.warning,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: bytes == null
                    ? const Icon(
                        Icons.image_outlined,
                        color: AppColors.neutral400,
                      )
                    : Image.memory(bytes, fit: BoxFit.cover),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _photos.remove(photo)),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (photo.isUploaded)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_done,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 2),
                Text(
                  'Uploaded',
                  style: AppStyles.labelSm.copyWith(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else if (photo.isRetrying)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            InkWell(
              onTap: () => _retryUpload(photo),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, size: 12, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    'Retry',
                    style: AppStyles.labelSm.copyWith(
                      fontSize: 10,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Zone 3 — reference material, collapsed by default so it stops pushing
  /// the notes field below the fold.
  Widget _buildGuidanceZone() {
    final hasReference = widget.item.howTo.isNotEmpty;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _guidanceExpanded = !_guidanceExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'How to inspect this',
                      style: AppStyles.labelMd.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _guidanceExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_guidanceExpanded) ...[
            const Divider(height: 1, color: AppColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _guidanceRow(
                    Icons.construction,
                    'Equipment needed',
                    widget.item.equipmentNeeded.isEmpty
                        ? 'Manual check'
                        : widget.item.equipmentNeeded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _guidanceRow(
                    Icons.lightbulb_outline,
                    'Inspection guidance',
                    widget.item.description,
                  ),
                  if (hasReference) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _guidanceRow(
                      Icons.fact_check_outlined,
                      'Reference',
                      widget.item.howTo,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guidanceRow(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.neutral500),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.labelSm.copyWith(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body.isEmpty ? '—' : body,
                style: AppStyles.bodySm.copyWith(color: AppColors.neutral700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Stays pinned above the keyboard rather than disappearing when the notes
  /// field takes focus, which is exactly when the user wants to save.
  Widget _buildActionBar() {
    final hasNext = _nextIncompleteItem != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.neutral200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: KeprButton(
                label: 'Cancel',
                height: AppSizes.minTapTarget,
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: KeprButton(
                label: hasNext ? 'Save & next' : 'Save check',
                height: AppSizes.minTapTarget,
                icon: const Icon(Icons.check, color: Colors.white, size: 19),
                enabled: _canMarkCompleted,
                onPressed: () => _save(openNext: hasNext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------- service estimate

  Widget _buildServiceEstimateCard() {
    final visibleMatches = serviceMatches;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.home_repair_service,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Related services',
                  style: AppStyles.labelMd.copyWith(
                    color: const Color(0xFF78350F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isLoadingServices
                ? 'Searching service catalog…'
                : selectedServices.isEmpty
                    ? _severity.requiresService
                        ? 'Critical issue: service selection is compulsory.'
                        : 'Select one or more services to attach to this issue.'
                    : '${selectedServices.length} services selected - Rs '
                        '${_selectedServicesTotal.toStringAsFixed(0)}',
            style: AppStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
          ),
          if (selectedServices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final service in selectedServices)
                  Chip(
                    label: Text(
                      '${service.serviceCode} - Rs '
                      '${service.estimatedCost.toStringAsFixed(0)}',
                    ),
                    onDeleted: () => _toggleService(service),
                  ),
              ],
            ),
          ],
          if (!_isLoadingServices &&
              _showServiceOptions &&
              visibleMatches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
                    onTap: () => _toggleService(match),
                  );
                },
              ),
            ),
          ],
          if (!_isLoadingServices &&
              _showServiceOptions &&
              visibleMatches.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'No matching services found. Add Consultation from the '
                'General service catalog.',
                style: AppStyles.bodySm.copyWith(
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            KeprButton(
              label: 'Add Consultation',
              width: double.infinity,
              height: AppSizes.minTapTarget,
              variant: ButtonVariant.secondary,
              icon: const Icon(Icons.support_agent),
              onPressed: _addConsultationService,
            ),
          ],
          if (_selectedMaterialCodes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Materials ${_selectedMaterialCodes.join(', ')}',
              style: AppStyles.bodySm.copyWith(
                color: const Color(0xFF92400E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
