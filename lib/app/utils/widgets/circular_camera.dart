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
  final CameraLensDirection preferredLens; // back/front
  const CircularCamera({
    super.key,
    this.size = 200,
    this.onPictureTaken,
    this.preferredLens = CameraLensDirection.back,
  });

  @override
  State<CircularCamera> createState() => _CircularCameraState();
}

class _CircularCameraState extends State<CircularCamera> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  CameraDescription? _cameraDescription;
  bool _isTaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFuture = _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Pause/resume camera on app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(); // re-init on resume
    }
  }

  Future<void> _initCamera() async {
    // request camera permission first
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final req = await Permission.camera.request();
      if (!req.isGranted) {
        // user denied: stop init
        return;
      }
    }

    // get available cameras and pick one that matches preferredLens (fallback to first)
    final cameras = await availableCameras();
    CameraDescription? selected;
    for (var cam in cameras) {
      if (cam.lensDirection == widget.preferredLens) {
        selected = cam;
        break;
      }
    }
    selected ??= cameras.isNotEmpty ? cameras.first : null;

    if (selected == null) {
      throw Exception('No camera found on device');
    }

    _cameraDescription = selected;

    _controller = CameraController(
      _cameraDescription!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // initialize
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTaking) return;

    try {
      setState(() => _isTaking = true);
      final xfile = await _controller!.takePicture();

      // move to app directory for easier access (optional)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(xfile.path).copy('${appDir.path}/$fileName');

      widget.onPictureTaken?.call(saved.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture captured')),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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

        if (_controller == null || !_controller!.value.isInitialized) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(child: Text('Camera not available')),
          );
        }

        // Camera preview has its own aspect ratio. We center-crop to make it fill the circle.
        final preview = CameraPreview(_controller!);

        return SizedBox(
          width: size,
          height: size + 70, // extra space for button
          child: Column(
            children: [
              // Circular preview
              ClipOval(
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.black,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final previewAspect = _controller!.value.aspectRatio;
                    // Use a FittedBox to cover the circle (center crop)
                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: constraints.maxHeight * previewAspect,
                        height: constraints.maxHeight,
                        child: preview,
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
                            border: Border.all(color: Colors.black12, width: 4),
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
