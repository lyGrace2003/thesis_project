import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  double _shakeThreshold = 12.0; // Adjust the threshold as necessary
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  final String esp32CamUrl = 'http://192.168.1.75:81';  // Your ESP32-CAM IP and stream port

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _checkPermissions();
    _startShakeDetection();
  }

  void _checkPermissions() async {
    if (await Permission.microphone.request().isGranted) {
      print('Microphone permission granted');
    } else {
      print('Microphone permission denied');
    }
  }

  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double shakeStrength = (event.x.abs() + event.y.abs() + event.z.abs());
      if (shakeStrength > _shakeThreshold) {
        _flutterTts.speak('Shake detected, starting speech recognition');
        _startListening();
      }
    });
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
    _accelerometerSubscription.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    initialRoute: '/',
    routes: {
      '/': (context) => Scaffold(
        appBar: AppBar(title: Text('VisionAID')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 25.0),
                child: Text(
                  _text,
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              SizedBox(height: 20),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => _simulateShake(), 
                  child: Text('Simulate Shake'),
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
