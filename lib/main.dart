import 'package:flutter/material.dart';
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/bootstrap.dart';
import 'package:focus_flow/features/focus_mode/presentation/pages/focus_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  await bootstrap();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const FocusPage(),
    );
  }
}
