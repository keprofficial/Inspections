import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../widgets/kepr_button.dart';

class CapturedInspectionPhoto {
  final Uint8List bytes;
  final String fileName;

  const CapturedInspectionPhoto({
    required this.bytes,
    required this.fileName,
  });
}

class CameraCaptureScreen extends StatefulWidget {
  final String itemId;

  const CameraCaptureScreen({
    Key? key,
    required this.itemId,
  }) : super(key: key);

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

  Future<void> _initializeCamera([int cameraIndex = 0]) async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found on this device.');
      }

      _cameraIndex = cameraIndex.clamp(0, _cameras.length - 1) as int;
      final oldController = _controller;
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await oldController?.dispose();
      await controller.initialize();

      if (!mounted) return;
      setState(() => _isInitializing = false);
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
    await _initializeCamera((_cameraIndex + 1) % _cameras.length);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canPreview = controller != null &&
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
                        : const CircularProgressIndicator(
                            color: AppColors.coral,
                          ),
              ),
            ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
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
