import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';  // Import the flutter_mjpeg package
import 'package:camera/camera.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:shake/shake.dart'; // Import the shake package
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late String streamUrl;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  
  bool _isUsingEsp32Cam = true; // Track whether using ESP32-CAM or mobile camera

  late ShakeDetector _shakeDetector; // Declare the ShakeDetector
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Retrieve the ESP32-CAM stream URL passed via arguments
    streamUrl = ModalRoute.of(context)?.settings.arguments as String;
    
    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    }
    
    // Initialize speech recognizer and shake detector
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeShakeDetector();
  }

  void _initializeShakeDetector() {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _startListening();
      },
    );
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

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          String text = result.recognizedWords;
          print('Detected words: $text');

          if (text.toLowerCase().contains('activate')) {
            // Perform your activation task here
            print('Activating task...');
            _flutterTts.speak('Activating task');

          } else if (text.toLowerCase().contains('stop')) {

            print('Stopping ESP32-CAM and returning to landing page');
            
            _flutterTts.speak('Stopping ESP32-CAM and returning to the landing page');
            _stopCameraAndGoBack();
          }
        });
      }
    }
  }

  void _simulateShake() {
    _startListening();
  }

  void _stopCameraAndGoBack() {
    // Stop the camera and navigate back to the landing page
    // You can add your logic here to stop the ESP32-CAM
    Navigator.of(context).pushNamed('/');
  }

  @override
  void dispose() {
    if (!_isUsingEsp32Cam) {
      _cameraController.dispose(); // Dispose the camera controller when using mobile camera
    }
    _shakeDetector.stopListening(); // Stop the shake detector
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ESP32-CAM Feed",
          style: mBold.copyWith(color: mPurple, fontSize: SizeConfig.blocksHorizontal! * 4),
        ),
        actions: [
          IconButton(
            icon: Icon(_isUsingEsp32Cam ? Icons.camera : Icons.videocam),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: mPurple, width: 4), // Purple border
              ),
              child: ClipRect( 
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Set your desired aspect ratio
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
                              return const Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                ),
              ),
            ),
            Builder(
                  builder: (context) => Container(
                    width: 180,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _simulateShake(), 
                      child: Text('Simulate Shake', style: mMedium.copyWith(color: const Color.fromARGB(255, 107, 11, 152), fontSize: SizeConfig.blocksHorizontal!*3),),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
