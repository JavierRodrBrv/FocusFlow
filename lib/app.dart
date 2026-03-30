import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/pages/focus_page.dart';

import 'flavors.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _nativeChannel = MethodChannel('com.example.focus_flow/native');

  @override
  void initState() {
    super.initState();
    _initNativeChannel();
  }

  void _initNativeChannel() {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationAction') {
        final action = call.arguments as String;
        debugPrint('[App] Received native action: $action');
        
        switch (action) {
          case 'pause':
            FlutterBackgroundService().invoke('sendEvent', {'event': 'pauseTimer'});
            break;
          case 'resume':
            FlutterBackgroundService().invoke('sendEvent', {'event': 'startTimer'});
            break;
          case 'stop':
            FlutterBackgroundService().invoke('sendEvent', {'event': 'resetTimer'});
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: F.title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Fondo oscuro deep
      ),
      home: _flavorBanner(
        child: const FocusPage(),
        show: F.appFlavor == Flavor.dev,
      ),
    );
  }

  Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withAlpha(150),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 1.0,
          ),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : child;
}
