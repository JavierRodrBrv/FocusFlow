
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/data/models/premium_status.dart';
import 'package:focus_flow/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/presentation/pages/home_page.dart';

Future<void> main() async {
  print('[main] Initializing application...');
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads
  print('[main] Initializing Google Mobile Ads...');
  await MobileAds.instance.initialize();
  print('[main] Google Mobile Ads Initialized.');

  // Initialize Hive
  print('[main] Initializing Hive...');
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(PremiumStatusAdapter());
  print('[main] Hive Initialized.');

  // Configure Dependency Injection
  print('[main] Configuring Dependency Injection...');
  await configureDependencies();
  print('[main] Dependency Injection Configured.');

  print('[main] Running app...');
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FocusBloc>()..add(InitializeApp()),
      child: MaterialApp(
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
        home: const HomePage(),
      ),
    );
  }
}
