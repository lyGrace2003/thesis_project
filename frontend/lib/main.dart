import 'package:flutter/material.dart';
import 'package:frontend/camera_page.dart';
import 'package:frontend/home_page.dart';

//Global Variabes
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isSpeechRecognitionActiveScreen1 = true;
bool isSpeechRecognitionActiveScreen2 = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(),
        '/camera': (context) => CameraScreen(),
      },
    );
  }
}
