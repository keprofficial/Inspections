import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../widgets/kepr_button.dart';

class CapturedInspectionPhoto {
  final Uint8List bytes;
  final String fileName;

  const CapturedInspectionPhoto({required this.bytes, required this.fileName});
}

int preferredInspectionCameraIndex(List<CameraDescription> cameras) {
  final backCameraIndex = cameras.indexWhere(
    (camera) => camera.lensDirection == CameraLensDirection.back,
  );
  return backCameraIndex == -1 ? 0 : backCameraIndex;
}

class CameraCaptureScreen extends StatefulWidget {
  final String itemId;

  const CameraCaptureScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;

  FlashMode _flashMode = FlashMode.auto;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera([int? cameraIndex]) async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found on this device.');
      }

      _cameraIndex = cameraIndex == null
          ? preferredInspectionCameraIndex(_cameras)
          : cameraIndex.clamp(0, _cameras.length - 1);
      final oldController = _controller;
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await oldController?.dispose();
      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currentZoom = minZoom;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _error =
            'Camera unavailable. Allow camera permission and use localhost or HTTPS.';
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'kepr_${widget.itemId}_$timestamp.jpg';

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedInspectionPhoto(bytes: bytes, fileName: fileName),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing || _isCapturing) return;
    setState(() => _currentZoom = 1.0);
    await _initializeCamera((_cameraIndex + 1) % _cameras.length);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = switch (_flashMode) {
      FlashMode.off   => FlashMode.auto,
      FlashMode.auto  => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
      _               => FlashMode.auto,
    };
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      // Flash not supported on this device/browser — silently ignore.
    }
  }

  Future<void> _onScaleStart(ScaleStartDetails details) async {
    _baseZoom = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    if ((newZoom - _currentZoom).abs() < 0.05) return;
    try {
      await controller.setZoomLevel(newZoom);
      setState(() => _currentZoom = newZoom);
    } catch (_) {}
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.off   => Icons.flash_off,
        FlashMode.torch => Icons.flash_on,
        _               => Icons.flash_auto,
      };

  String get _flashLabel => switch (_flashMode) {
        FlashMode.off   => 'Off',
        FlashMode.torch => 'On',
        _               => 'Auto',
      };

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canPreview =
        controller != null &&
        controller.value.isInitialized &&
        !_isInitializing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Capture Evidence',
          style: AppStyles.labelMd.copyWith(color: Colors.white),
        ),
        actions: [
          if (canPreview)
            IconButton(
              tooltip: 'Flash: $_flashLabel',
              onPressed: _toggleFlash,
              icon: Icon(_flashIcon),
              color: _flashMode == FlashMode.torch
                  ? AppColors.warning
                  : Colors.white,
            ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _cameras.length > 1 ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? _buildErrorState()
                    : canPreview
                    ? _buildPreview(controller)
                    : const CircularProgressIndicator(color: AppColors.coral),
              ),
            ),
            if (canPreview && _maxZoom > _minZoom + 0.5)
              _buildZoomIndicator(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              color: Colors.black,
              child: KeprButton(
                label: _isCapturing ? 'Capturing...' : 'Capture Live Photo',
                icon: const Icon(Icons.photo_camera, color: Colors.white),
                isLoading: _isCapturing,
                enabled: canPreview && !_isCapturing,
                onPressed: canPreview && !_isCapturing ? _capture : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(CameraController controller) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    final percent = (_maxZoom - _minZoom) == 0
        ? 0.0
        : (_currentZoom - _minZoom) / (_maxZoom - _minZoom);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.zoom_out, color: Colors.white54, size: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.coral,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: percent.clamp(0.0, 1.0),
                onChanged: (value) {
                  final zoom = _minZoom + value * (_maxZoom - _minZoom);
                  _controller?.setZoomLevel(zoom);
                  setState(() => _currentZoom = zoom);
                },
              ),
            ),
          ),
          const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            '${_currentZoom.toStringAsFixed(1)}x',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, color: Colors.white70, size: 44),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          KeprButton(
            label: 'Try Again',
            variant: ButtonVariant.secondary,
            onPressed: _initializeCamera,
          ),
        ],
      ),
    );
  }
}
