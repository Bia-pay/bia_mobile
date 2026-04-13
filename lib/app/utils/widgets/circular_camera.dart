// lib/widgets/circular_camera.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Callback when picture is taken: returns the file path
typedef OnPictureTaken = void Function(String path);

class CircularCamera extends StatefulWidget {
  final double size;
  final OnPictureTaken? onPictureTaken;
  final CameraLensDirection preferredLens;
  const CircularCamera({
    super.key,
    this.size = 200,
    this.onPictureTaken,
    this.preferredLens = CameraLensDirection.back,
  });

  @override
  State<CircularCamera> createState() => _CircularCameraState();
}

class _CircularCameraState extends State<CircularCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;

  /// The single shared future for the current init cycle.
  /// Assigned once in initState; re-assigned only after a full dispose+null.
  Future<void>? _initializeFuture;

  /// Guard: true while _initCamera() is running. Prevents concurrent calls.
  bool _isInitializing = false;

  bool _isTaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start one, and only one, initialization.
    _initializeFuture = _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  /// Safely disposes the controller and nulls the reference so a subsequent
  /// _initCamera() call knows it must create a fresh instance.
  void _disposeController() {
    final ctrl = _controller;
    _controller = null;
    ctrl?.dispose();
  }

  // ── Lifecycle: pause/resume camera ───────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Pause camera — full dispose so the hardware is released.
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      // Only re-init if we don't already have a controller AND no init is running.
      if (_controller == null && !_isInitializing) {
        final future = _initCamera();
        if (mounted) {
          setState(() => _initializeFuture = future);
        }
      }
    }
  }

  // ── Camera initialization (guarded) ──────────────────────────────────────
  Future<void> _initCamera() async {
    // Prevent concurrent initialization calls.
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 1. Request camera permission.
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final req = await Permission.camera.request();
        if (!req.isGranted) return; // user denied
      }

      // 2. Select the preferred camera.
      final cameras = await availableCameras();
      CameraDescription? selected;
      for (final cam in cameras) {
        if (cam.lensDirection == widget.preferredLens) {
          selected = cam;
          break;
        }
      }
      selected ??= cameras.isNotEmpty ? cameras.first : null;

      if (selected == null) {
        throw Exception('No camera found on device');
      }

      // 3. Dispose any lingering controller before creating a new one.
      //    (Shouldn't happen due to the guard, but defensive cleanup.)
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // 4. Create and initialize.
      final ctrl = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();

      // 5. Only assign if still mounted (widget might have been disposed while
      //    we were awaiting).
      if (mounted) {
        _controller = ctrl;
        setState(() {});
      } else {
        // Widget gone — release immediately to avoid leaks.
        ctrl.dispose();
      }
    } catch (e) {
      debugPrint('⚠️ CircularCamera init error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // ── Take picture ─────────────────────────────────────────────────────────
  Future<void> _takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isTaking) return;

    try {
      if (mounted) setState(() => _isTaking = true);
      final xfile = await ctrl.takePicture();

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(xfile.path).copy('${appDir.path}/$fileName');

      widget.onPictureTaken?.call(saved.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picture captured')),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final size = widget.size;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final ctrl = _controller;
        if (ctrl == null || !ctrl.value.isInitialized) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(child: Text('Camera not available')),
          );
        }

        final previewAspect = ctrl.value.aspectRatio;

        return SizedBox(
          width: size,
          height: size + 70,
          child: Column(
            children: [
              // Circular preview — center-cropped to fill the oval.
              ClipOval(
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.black,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: constraints.maxHeight * previewAspect,
                        height: constraints.maxHeight,
                        child: CameraPreview(ctrl),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 14),

              // Snap button
              SizedBox(
                width: 64,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    backgroundColor: _isTaking ? Colors.grey : Colors.white,
                    elevation: 6,
                  ),
                  onPressed: _isTaking ? null : _takePicture,
                  child: _isTaking
                      ? const CircularProgressIndicator()
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.black12, width: 4),
                            color: Colors.redAccent,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
