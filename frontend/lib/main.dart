import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = "Press the button to simulate shake or shake the device to start listening";
  
   late ShakeDetector _shakeDetector;

  final String esp32CamUrl = 'http://192.168.1.75:81';  // Your ESP32-CAM IP and stream port

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _checkPermissions();

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _startListening();
      },
    );
  }

  void _checkPermissions() async {
    if (await Permission.microphone.request().isGranted) {
      print('Microphone permission granted');
    } else {
      print('Microphone permission denied');
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
            print('Detected words: $_text');

            if (_text.toLowerCase().contains('activate')) {
              print('Activating CameraScreen');
              _flutterTts.speak('Command detected, Activating Scene description');
              _navigateToCameraScreen();  // Use the context from the build method
            }
          });
        });
      }
    }
  }

  void _simulateShake() {
    _startListening();
  }

  void _navigateToCameraScreen() {
    try {
      navigatorKey.currentState?.pushNamed(
        '/camera',
        arguments: esp32CamUrl,
      );
    } catch (e) {
      print('Navigation error: $e');
    }
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Text("VisionAid", style: mBold.copyWith(color: mPurple, fontSize: SizeConfig.blocksHorizontal!*14),),
                ),
                SizedBox(height: SizeConfig.blocksVertical!*4),
                Container(
                  margin: const EdgeInsets.only(left: 35.0, right: 30.0),
                  padding: const EdgeInsets.only(top:15.0),
                  child: Text(
                    _text,
                    style: mRegular.copyWith(color: mDarkpurple, fontSize: SizeConfig.blocksHorizontal!*4.5 ),
                  ),
                ),
                SizedBox(height: SizeConfig.blocksVertical!*4),
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
        ),
        '/camera': (context) => CameraScreen(),
      },
    );
  }
}
