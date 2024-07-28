import 'package:crop_diseases/model.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveInput extends StatefulWidget {
  final Classifier classifier;
  const LiveInput({required this.classifier, super.key});

  @override
  State<LiveInput> createState() => _LiveInputState();
}

class _LiveInputState extends State<LiveInput> {
  late CameraController _cameraController;
  bool _isWorking = false;
  DetectionClasses _detected = DetectionClasses.Apple___Apple_scab;
  bool _isInitialized = false;
  void trySetState(Function f) {
    if (mounted) setState(() => f());
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    trySetState(() => _isWorking = true);
    final convertedImage = ImageUtils.convertYUV420ToImage(cameraImage);
    DetectionClasses result = await widget.classifier.predict(convertedImage);
    trySetState(() {
      _detected = result;
      _isWorking = false;
    });
  }

  // camera and model setup
  Future<void> _initialize() async {
    final cameras = await availableCameras();
    // Create a CameraController object
    _cameraController = CameraController(
      cameras[0], // Choose the first camera in the list
      ResolutionPreset.low, // Choose a resolution preset
      fps: 2,
      enableAudio: false,
    );

    // Initialize the CameraController and start the camera preview
    await _cameraController.initialize();
    // Listen for image frames
    await _cameraController.startImageStream((image) {
      // Make predictions only if not busy
      if (!_isWorking) _processCameraImage(image);
    });
  }

  @override
  void initState() {
    _initialize().then((value) => setState(() => _isInitialized = true));
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? Stack(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height,
                width: MediaQuery.sizeOf(context).width,
                child: CameraPreview(_cameraController),
              ),
              Positioned(
                bottom: 18.0,
                left: 15,
                child: Text(
                  textAlign: TextAlign.center,
                  "Detection: $_detected",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}
