import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/main.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late String streamUrl;
  late AudioPlayer _audioPlayer;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  bool _isUsingEsp32Cam = true;

  late stt.SpeechToText _s;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isActivated = false;
  bool _cameraActivationFailed = false;

  int _retryCount = 0;
  final int _maxRetries = 3;
  String _text = "";

  @override
  void initState() {
    super.initState();
    _s = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    streamUrl = ModalRoute.of(context)?.settings.arguments as String;

    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    }
    if (isSpeechRecognitionActiveScreen2 == true) {
      _initSpeech();
    }
  }

  void _checkPermissions() async {
    if (await Permission.microphone.request().isGranted) {
      print('Microphone permission granted');
      Future.delayed(Duration(milliseconds: 500), () {
          _initSpeech();
        });
    } else {
      print('Microphone permission denied');
    }
  }

  void _initSpeech() async {
    bool available = await _s.initialize(onStatus: onStatus);
    if (available) {
      _startListening(available);
    } else {
      print('Speech recognition not available.');
      _flutterTts.speak('Speech recognition not available.');
    }
    setState(() {});
  }

  Future<void> _initializeMobileCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _cameraController.initialize();
    } catch (e) {
      _playFailureSound();
      print('Mobile camera initialization failed: $e');
    }
  }

  void _toggleCamera() {
    setState(() {
      _isUsingEsp32Cam = !_isUsingEsp32Cam;
    });

    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    } else {
      if (streamUrl.isEmpty) {
        _playFailureSound();
        print('ESP32-CAM stream failed to activate');
      }
    }
  }

  void _stopListening() async {
    try {
      await _s.stop().then((_) {
        isSpeechRecognitionActiveScreen2 = false;
        isSpeechRecognitionActiveScreen1 = true;
        print("Stop Speech Recognition in CameraScreen");
        print("Screen 1 : $isSpeechRecognitionActiveScreen1");
        print("Screen 2 : $isSpeechRecognitionActiveScreen2");
        _stopCameraAndGoBack();
      });
      setState(() {});
    } catch (e) {
      print("Stop failure: $e");
    }
  }

  void onError(SpeechRecognitionError error) {
  print('Error during speech recognition: ${error.errorMsg}');
}


  void _startListening(bool available) async {
    if (isSpeechRecognitionActiveScreen2 == true && _isActivated == false && isSpeechRecognitionActiveScreen1 == false) {
      print("Start Speech recognition");
      try {
        if (available) {
          setState(() {
            _isListening = true;
            _text = "";
          });
          _s.listen(onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              print('Detected words [2]: $_text');

              if (_text.toLowerCase().contains('capture') && !_isActivated) {
                print('Frame captured');
                _startListening(available);

                _flutterTts.speak('Frame captured');
              } else if (_text.toLowerCase().contains('stop') && !_isActivated) {
                _text = '';
                print('Returning to landing page');
                _flutterTts.speak('Returning to the landing page');
                _isActivated = true;
                _stopListening();
              }
            });
          },
          );
        }
      } catch (e) {
        print('Error initializing speech recognition: $e');
      }
    }
  }

  void onStatus(String val) {
    if(isSpeechRecognitionActiveScreen2 == true){
      print('onStatus [2]: $val');
      if (val == 'done' && _isActivated == true) {
          _startListening(true);
      } else if (val == 'notListening') {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _playFailureSound() async {
    if (!_cameraActivationFailed) {
      _cameraActivationFailed = true;
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      print("Camera activation failed");
      await _flutterTts.speak('Camera activation failed, returning to landing page');

      _stopListening();
    }
  }

  void _stopCameraAndGoBack()async{
    try {
      print("Navigating to landing page");
      await _s.stop();  
      Navigator.of(context).pushReplacementNamed('/').then((_) {
        setState(() {
          _isActivated = false; 
          _text = "";
          _cameraActivationFailed = false;
        });
      });
    } catch (e) {
      print('Navigation error: $e');
    }
  }


  @override
  void dispose() {
    if (!_isUsingEsp32Cam) {
      _cameraController.dispose();
    }
    _s.stop();
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
                border: Border.all(color: mPurple, width: 4),
              ),
              child: ClipRect(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isUsingEsp32Cam
                      ? Mjpeg(
                          isLive: true,
                          stream: "$streamUrl/stream",
                          error: (context, error, stack) {
                            _playFailureSound();
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
            SizedBox(height: 20),
            Text(
              _text,
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}