import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/screens/camera_capture_screen.dart';

void main() {
  CameraDescription camera(String name, CameraLensDirection direction) {
    return CameraDescription(
      name: name,
      lensDirection: direction,
      sensorOrientation: 0,
    );
  }

  test('prefers the back camera even when the front camera is first', () {
    final cameras = [
      camera('front', CameraLensDirection.front),
      camera('back', CameraLensDirection.back),
    ];

    expect(preferredInspectionCameraIndex(cameras), 1);
  });

  test('falls back to the first camera when no back camera is available', () {
    final cameras = [
      camera('front', CameraLensDirection.front),
      camera('external', CameraLensDirection.external),
    ];

    expect(preferredInspectionCameraIndex(cameras), 0);
  });
}
