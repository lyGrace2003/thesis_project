import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/main.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isActivated = false; 
  bool _isInitializing  = false;
  String _text = "Listening for commands...";
  String? _lastCommand;

  final String esp32CamUrl = 'http://192.168.1.75:81';  // ESP32-CAM IP and stream port

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("didChangeDependencies called");
    if (isSpeechRecognitionActiveScreen1 == true) {
      _startListening();
    }
  }

  void _checkPermissions() async {
    if (await Permission.microphone.request().isGranted) {
      print('Microphone permission granted');
      Future.delayed(Duration(milliseconds: 500), () {
        _startListening();
      });
    } else {
      print('Microphone permission denied');
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop().then((_) {
        isSpeechRecognitionActiveScreen1 = false;
        isSpeechRecognitionActiveScreen2 = true;
        print("Stop Speech Recognition");
        print("Screen 1 : $isSpeechRecognitionActiveScreen1");
        print("Screen 2 : $isSpeechRecognitionActiveScreen2");
        _navigateToCameraScreen();
      });
      setState(() {});
    } catch (e) {
      print("Stop failure: $e");
    }
  }

  void _startListening() async {
    if (isSpeechRecognitionActiveScreen1 == true && _isActivated == false && 
    _isListening == false && _isInitializing == false) {
      _isInitializing  = true;
      bool available = await _speech.initialize(onStatus: onStatus);
      print("Start Speech recognition");
      try {
        if (available) {
          setState(() {
            _isListening = true;
            _isActivated = false;
            _text = "Listening for commands...";
          });
          _speech.listen(onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              print('Detected word [1]: $_text');

              if (_text.toLowerCase() != _lastCommand) {
                _lastCommand = _text.toLowerCase();
                if (_lastCommand!.contains('activate') && !_isActivated) {
                  print('Activating CameraScreen');
                  _text = '';
                  _flutterTts.speak('Command detected, Initiating Scene description');
                  _isActivated = true;
                  _stopListening();
                }
              }
            });
          });
        } else {
          print('Speech recognition not available.');
          _flutterTts.speak('Speech recognition not available.');
        }
      } catch (e) {
        print('Error initializing speech recognition: $e');
      }finally{
        _isInitializing = false;
      }
    }
  }

  void onStatus(String val) {
    if (isSpeechRecognitionActiveScreen1) {
      print('onStatus [1]: $val');
      if (val == 'done' && !_isActivated) {
        _startListening();
      } else if (val == 'notListening') {
        setState(() {
          _isListening = false; 
        });
      }
    }
  }

  void _navigateToCameraScreen() async {
    try {
      print('Navigating to Cam');
      navigatorKey.currentState?.pushNamed(
        '/camera',
        arguments: esp32CamUrl,
      ).then((_) {
        setState(() {
          _lastCommand = ""; 
          _text = "Listening for commands...";
          _isActivated = false;
        });
      });
    } catch (e) {
      print('Navigation error: $e');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Text(
                "VisionAid",
                style:  mBold.copyWith(color: mPurple, fontSize: SizeConfig.blocksHorizontal! * 14),
              ),
            ),
            SizedBox(height: SizeConfig.blocksVertical! * 4),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30.0),
              padding: const EdgeInsets.only(top: 15.0),
              child: Text(
                _text,
                style: mRegular.copyWith(color: mDarkpurple, fontSize: SizeConfig.blocksHorizontal! * 4.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
