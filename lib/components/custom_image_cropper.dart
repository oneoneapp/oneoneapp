import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomImageCropper extends StatefulWidget {
  final File imageFile;
  final Function(File) onCropComplete;

  const CustomImageCropper({
    super.key,
    required this.imageFile,
    required this.onCropComplete,
  });

  @override
  State<CustomImageCropper> createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  late Size _imageSize;
  late Size _screenSize;
  bool _isImageLoaded = false;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImageDimensions() async {
    final image = Image.file(widget.imageFile);
    final completer = await image.image.resolve(const ImageConfiguration());
    completer.addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        _isImageLoaded = true;
      });
      _centerImage();
    }));
  }

  void _centerImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final screenSize = MediaQuery.of(context).size;
      _screenSize = screenSize;
      
      // Calculate the scale to fit the image properly with some initial zoom
      final scaleX = screenSize.width / _imageSize.width;
      final scaleY = screenSize.height / _imageSize.height;
      final scale = (scaleX > scaleY ? scaleX : scaleY) * 1.2; // Start with 20% more zoom
      
      // Center the image
      final scaledWidth = _imageSize.width * scale;
      final scaledHeight = _imageSize.height * scale;
      final offsetX = (screenSize.width - scaledWidth) / 2;
      final offsetY = (screenSize.height - scaledHeight) / 2;
      
      _transformationController.value = Matrix4.identity()
        ..translate(offsetX, offsetY)
        ..scale(scale);
    });
  }

  Future<void> _cropImage() async {
    setState(() {
      _isCropping = true;
    });

    try {
      // Capture the visible area
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Create a temporary file for the cropped image
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      widget.onCropComplete(tempFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCropping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image viewer with zoom and pan
            if (_isImageLoaded)
              Center(
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: ClipRect(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.1,
                        maxScale: 10.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(100),
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Overlay with crop frame
            if (_isImageLoaded)
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(150),
                  ),
                ),
              ),

            // Dimmed overlay
            if (_isImageLoaded)
              IgnorePointer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(150),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.transparent,
                            spreadRadius: 0,
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(150),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Top controls
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Text(
                    'Crop Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _centerImage,
                    icon: const Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pinch to zoom, drag to position. The circular area will be your profile picture.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCropping ? null : _cropImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: _isCropping
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
}