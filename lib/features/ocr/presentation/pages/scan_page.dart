import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_capture_result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isFlashOn = false;
  bool _isCapturing = false;

  Future<void> _captureReceipt() async {
    if (_isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (!mounted || image == null) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return OCRCaptureResultPage(imagePath: image.path);
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = constraints.biggest;
            final double horizontalPadding = size.width * 0.08;
            final double frameWidth = (size.width - horizontalPadding * 2)
                .clamp(260.0, 420.0);
            final double frameHeight = (frameWidth * 1.26).clamp(
              330.0,
              size.height * 0.58,
            );

            return Stack(
              children: <Widget>[
                const Positioned.fill(child: _CameraPlaceholder()),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 20,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 20,
                  child: _CircleIconButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    backgroundColor: Colors.black.withValues(alpha: 0.38),
                    foregroundColor: Colors.white,
                    onPressed: _toggleFlash,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.08),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _ScanFrame(width: frameWidth, height: frameHeight),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          child: Text(
                            'Letakan nota di dalam kotak!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Center(
                    child: _CaptureButton(
                      isLoading: _isCapturing,
                      onPressed: _isCapturing ? null : _captureReceipt,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF3A302A),
            const Color(0xFF111111),
            const Color(0xFF2A1C14),
          ],
        ),
      ),
      child: CustomPaint(painter: _PlaceholderTexturePainter()),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _ScanFramePainter()),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double inset = cornerPaint.strokeWidth / 2;
    final double radius = size.width * 0.035;
    final double armLength = size.width * 0.13;
    final double left = inset;
    final double top = inset;
    final double right = size.width - inset;
    final double bottom = size.height - inset;

    void drawCorner({
      required Offset corner,
      required bool isLeft,
      required bool isTop,
    }) {
      final double startX = isLeft ? corner.dx + radius : corner.dx - radius;
      final double endX = isLeft
          ? corner.dx + armLength
          : corner.dx - armLength;
      final double startY = isTop ? corner.dy + radius : corner.dy - radius;
      final double endY = isTop ? corner.dy + armLength : corner.dy - armLength;

      canvas
        ..drawLine(
          Offset(startX, corner.dy),
          Offset(endX, corner.dy),
          cornerPaint,
        )
        ..drawLine(
          Offset(corner.dx, startY),
          Offset(corner.dx, endY),
          cornerPaint,
        );

      final Rect arcRect = Rect.fromCircle(center: corner, radius: radius);
      final double startAngle = switch ((isLeft, isTop)) {
        (true, true) => 3.14159,
        (false, true) => -1.5708,
        (false, false) => 0,
        (true, false) => 1.5708,
      };

      canvas.drawArc(arcRect, startAngle, 1.5708, false, cornerPaint);
    }

    drawCorner(
      corner: Offset(left + radius, top + radius),
      isLeft: true,
      isTop: true,
    );
    drawCorner(
      corner: Offset(right - radius, top + radius),
      isLeft: false,
      isTop: true,
    );
    drawCorner(
      corner: Offset(right - radius, bottom - radius),
      isLeft: false,
      isTop: false,
    );
    drawCorner(
      corner: Offset(left + radius, bottom - radius),
      isLeft: true,
      isTop: false,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        fixedSize: const Size.square(44),
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'Capture receipt',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            color: Colors.black.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2333F),
                border: Border.all(color: const Color(0xFF9E1720), width: 2),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (double offset = -size.height; offset < size.width; offset += 18) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
