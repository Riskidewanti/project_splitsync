import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'ocr_capture_result_page.dart';

enum _CameraStatus { loading, ready, permissionDenied, unavailable, error }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  _CameraStatus _cameraStatus = _CameraStatus.loading;
  String? _cameraMessage;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isInitializing = false;
  bool _isFlashAvailable = true;

  bool get _isCameraReady {
    final CameraController? controller = _cameraController;
    return _cameraStatus == _CameraStatus.ready &&
        controller != null &&
        controller.value.isInitialized;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isCameraReady && !_isInitializing) {
        _initializeCamera();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _releaseCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    _setCameraStatus(_CameraStatus.loading);

    try {
      await _releaseCamera();

      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) {
        return;
      }

      if (cameras.isEmpty) {
        _setCameraStatus(
          _CameraStatus.unavailable,
          message: 'No camera was found on this device.',
        );
        return;
      }

      final CameraController controller = CameraController(
        _preferredCamera(cameras),
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();
      if (!mounted || _cameraController != controller) {
        await controller.dispose();
        return;
      }

      await controller.lockCaptureOrientation();
      _isFlashAvailable = true;
      await _setFlashMode(FlashMode.off, updateUi: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _cameraStatus = _CameraStatus.ready;
        _cameraMessage = null;
        _isFlashOn = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      _handleCameraException(error);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _setCameraStatus(
        _CameraStatus.error,
        message: 'Unable to initialize camera.',
      );
    } finally {
      _isInitializing = false;
    }
  }

  CameraDescription _preferredCamera(List<CameraDescription> cameras) {
    for (final CameraDescription camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }

    return cameras.first;
  }

  Future<void> _releaseCamera() async {
    final CameraController? controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  void _setCameraStatus(_CameraStatus status, {String? message}) {
    if (!mounted) {
      return;
    }

    if (_cameraStatus == status && _cameraMessage == message) {
      return;
    }

    setState(() {
      _cameraStatus = status;
      _cameraMessage = message;
      if (status != _CameraStatus.ready) {
        _isFlashOn = false;
      }
    });
  }

  void _handleCameraException(CameraException error) {
    final bool isPermissionError = switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' => true,
      _ => false,
    };

    _setCameraStatus(
      isPermissionError ? _CameraStatus.permissionDenied : _CameraStatus.error,
      message: isPermissionError
          ? 'Camera access is required to scan receipts.'
          : 'Unable to initialize camera.',
    );
  }

  Future<void> _setFlashMode(
    FlashMode mode, {
    required bool updateUi,
  }) async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(mode);
      if (!mounted || !updateUi) {
        return;
      }
      setState(() {
        _isFlashOn = mode == FlashMode.torch;
        _isFlashAvailable = true;
      });
    } on CameraException {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFlashOn = false;
        _isFlashAvailable = false;
      });
    }
  }

  Future<void> _captureReceipt() async {
    final CameraController? controller = _cameraController;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await controller.takePicture();

      if (!mounted) {
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

  Future<void> _toggleFlash() async {
    if (!_isCameraReady || !_isFlashAvailable) {
      return;
    }

    await _setFlashMode(
      _isFlashOn ? FlashMode.off : FlashMode.torch,
      updateUi: true,
    );
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
                Positioned.fill(
                  child: _CameraBackground(
                    controller: _cameraController,
                    status: _cameraStatus,
                    message: _cameraMessage,
                    onRetry: _initializeCamera,
                  ),
                ),
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
                    foregroundColor: _isCameraReady && _isFlashAvailable
                        ? Colors.white
                        : Colors.white54,
                    onPressed: _isCameraReady && _isFlashAvailable
                        ? _toggleFlash
                        : null,
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
                      onPressed: _isCapturing || !_isCameraReady
                          ? null
                          : _captureReceipt,
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

class _CameraBackground extends StatelessWidget {
  const _CameraBackground({
    required this.controller,
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final CameraController? controller;
  final _CameraStatus status;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final CameraController? activeController = controller;
    final bool isReady = status == _CameraStatus.ready &&
        activeController != null &&
        activeController.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const _CameraPlaceholder(),
        if (isReady)
          _FadingCameraPreview(controller: activeController)
        else if (status == _CameraStatus.loading)
          const _CameraLoadingView()
        else
          _CameraErrorView(
            status: status,
            message: message,
            onRetry: onRetry,
          ),
      ],
    );
  }
}

class _LiveCameraPreview extends StatelessWidget {
  const _LiveCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _FadingCameraPreview extends StatefulWidget {
  const _FadingCameraPreview({required this.controller});

  final CameraController controller;

  @override
  State<_FadingCameraPreview> createState() => _FadingCameraPreviewState();
}

class _FadingCameraPreviewState extends State<_FadingCameraPreview> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: _LiveCameraPreview(controller: widget.controller),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF3A302A),
            Color(0xFF111111),
            Color(0xFF2A1C14),
          ],
        ),
      ),
      child: CustomPaint(painter: _PlaceholderTexturePainter()),
    );
  }
}

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            dimension: 34,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Preparing Camera...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please wait...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final _CameraStatus status;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isPermissionDenied = status == _CameraStatus.permissionDenied;
    final String title = switch (status) {
      _CameraStatus.permissionDenied => 'Camera access is required',
      _CameraStatus.unavailable => 'Camera unavailable',
      _ => 'Unable to initialize camera',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: onRetry,
              icon: Icon(
                isPermissionDenied ? Icons.camera_alt_outlined : Icons.refresh,
                size: 17,
              ),
              label: Text(
                isPermissionDenied ? 'Try Again' : 'Retry',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
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
  final VoidCallback? onPressed;

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
