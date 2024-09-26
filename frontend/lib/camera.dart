import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';  // Import the flutter_mjpeg package
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late String streamUrl;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  
  bool _isUsingEsp32Cam = true; // Track whether using ESP32-CAM or mobile camera
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Retrieve the ESP32-CAM stream URL passed via arguments
    streamUrl = ModalRoute.of(context)?.settings.arguments as String;
    
    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    }
  }

  Future<void> _initializeMobileCamera() async {
    // Get the available cameras
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0], // Use the first camera
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  void _toggleCamera() {
    setState(() {
      _isUsingEsp32Cam = !_isUsingEsp32Cam;
    });
    
    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    }
  }

  @override
  void dispose() {
    if (!_isUsingEsp32Cam) {
      _cameraController.dispose(); // Dispose the camera controller when using mobile camera
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32-CAM & Mobile Camera"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isUsingEsp32Cam ? Icons.camera : Icons.videocam),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _isUsingEsp32Cam
            ? Mjpeg(
                isLive: true,
                stream: "$streamUrl/stream", // MJPEG stream URL for ESP32-CAM
                error: (context, error, stack) {
                  return Text('Stream Error: $error');
                },
              )
            : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_cameraController);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
      ),
    );
  }
}
