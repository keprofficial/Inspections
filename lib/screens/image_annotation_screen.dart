import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../constants/app_styles.dart';
import '../constants/colors.dart';
import '../widgets/kepr_button.dart';

enum _AnnotationTool { draw, circle }

class ImageAnnotationScreen extends StatefulWidget {
  final Uint8List bytes;

  const ImageAnnotationScreen({
    Key? key,
    required this.bytes,
  }) : super(key: key);

  @override
  State<ImageAnnotationScreen> createState() => _ImageAnnotationScreenState();
}

class _ImageAnnotationScreenState extends State<ImageAnnotationScreen> {
  final GlobalKey _captureKey = GlobalKey();
  final List<_AnnotationMark> _marks = [];
  _AnnotationTool _tool = _AnnotationTool.circle;
  List<Offset>? _activeStroke;
  Offset? _circleStart;
  Offset? _circleEnd;
  bool _isSaving = false;

  bool get _hasMarks =>
      _marks.isNotEmpty || _activeStroke != null || _circleStart != null;

  void _startAnnotation(Offset point) {
    setState(() {
      if (_tool == _AnnotationTool.draw) {
        _activeStroke = [point];
      } else {
        _circleStart = point;
        _circleEnd = point;
      }
    });
  }

  void _updateAnnotation(Offset point) {
    setState(() {
      if (_tool == _AnnotationTool.draw) {
        final stroke = _activeStroke;
        if (stroke == null) {
          _activeStroke = [point];
        } else {
          stroke.add(point);
        }
      } else {
        _circleEnd = point;
      }
    });
  }

  void _finishAnnotation() {
    setState(() {
      if (_tool == _AnnotationTool.draw) {
        final stroke = _activeStroke;
        if (stroke != null && stroke.isNotEmpty) {
          _marks.add(_AnnotationMark.stroke(List<Offset>.from(stroke)));
        }
        _activeStroke = null;
      } else {
        final start = _circleStart;
        final end = _circleEnd ?? start;
        if (start != null && end != null) {
          _marks.add(_AnnotationMark.circle(_rectFromPoints(start, end)));
        }
        _circleStart = null;
        _circleEnd = null;
      }
    });
  }

  void _undo() {
    if (_activeStroke != null || _circleStart != null) {
      setState(() {
        _activeStroke = null;
        _circleStart = null;
        _circleEnd = null;
      });
      return;
    }
    if (_marks.isEmpty) return;
    setState(() => _marks.removeLast());
  }

  void _clear() {
    setState(() {
      _marks.clear();
      _activeStroke = null;
      _circleStart = null;
      _circleEnd = null;
    });
  }

  Rect _rectFromPoints(Offset a, Offset b) {
    final left = math.min(a.dx, b.dx);
    final top = math.min(a.dy, b.dy);
    final width = (a.dx - b.dx).abs();
    final height = (a.dy - b.dy).abs();
    final size = math.max(math.max(width, height), 34.0);
    return Rect.fromLTWH(left, top, size, size);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Annotation canvas unavailable.');
      final image = await boundary.toImage(pixelRatio: 1.6);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('Could not export annotation.');
      if (!mounted) return;
      Navigator.pop(context, data.buffer.asUint8List());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save annotation: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Annotate Issue',
          style: AppStyles.labelMd.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _hasMarks ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Clear marks',
            onPressed: _hasMarks ? _clear : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: _buildToolBar(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) =>
                            _startAnnotation(details.localPosition),
                        onPanUpdate: (details) =>
                            _updateAnnotation(details.localPosition),
                        onPanEnd: (_) => _finishAnnotation(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.black),
                            Image.memory(widget.bytes, fit: BoxFit.contain),
                            CustomPaint(
                              painter: _AnnotationPainter(
                                marks: _marks,
                                activeStroke: _activeStroke,
                                activeCircle:
                                    _circleStart == null || _circleEnd == null
                                        ? null
                                        : _rectFromPoints(
                                            _circleStart!,
                                            _circleEnd!,
                                          ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: KeprButton(
                      label: 'Skip',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context, widget.bytes),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeprButton(
                      label: _isSaving ? 'Saving...' : 'Use Photo',
                      icon: const Icon(Icons.check, color: Colors.white),
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          _toolButton(
            tool: _AnnotationTool.circle,
            icon: Icons.radio_button_unchecked,
            label: 'Circle',
          ),
          const SizedBox(width: 6),
          _toolButton(
            tool: _AnnotationTool.draw,
            icon: Icons.draw,
            label: 'Draw',
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required _AnnotationTool tool,
    required IconData icon,
    required String label,
  }) {
    final selected = _tool == tool;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _tool = tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppStyles.labelSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotationMark {
  final List<Offset>? stroke;
  final Rect? circle;

  const _AnnotationMark.stroke(this.stroke) : circle = null;

  const _AnnotationMark.circle(this.circle) : stroke = null;
}

class _AnnotationPainter extends CustomPainter {
  final List<_AnnotationMark> marks;
  final List<Offset>? activeStroke;
  final Rect? activeCircle;

  const _AnnotationPainter({
    required this.marks,
    required this.activeStroke,
    required this.activeCircle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.error
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final mark in marks) {
      final stroke = mark.stroke;
      final circle = mark.circle;
      if (stroke != null) {
        _drawStroke(canvas, paint, stroke);
      } else if (circle != null) {
        canvas.drawOval(circle, paint);
      }
    }

    if (activeStroke != null) {
      _drawStroke(canvas, paint, activeStroke!);
    }
    if (activeCircle != null) {
      canvas.drawOval(activeCircle!, paint);
    }
  }

  void _drawStroke(Canvas canvas, Paint paint, List<Offset> stroke) {
    if (stroke.length == 1) {
      canvas.drawCircle(stroke.first, 7, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      return;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (final point in stroke.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return oldDelegate.marks != marks ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.activeCircle != activeCircle;
  }
}
