import 'package:flutter/material.dart';
import 'package:focus_flow/features/focus_mode/presentation/pages/focus_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:focus_flow/l10n/app_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/features/focus_mode/presentation/models/focus_state.dart';

import 'flavors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FlutterBackgroundService().on('update'),
      builder: (context, snapshot) {
        String languageCode = 'es'; // Default
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final state = FocusState.fromJson(snapshot.data!);
            languageCode = state.languageCode ?? 'es';
          } catch (e) {
            // Ignore
          }
        }

        return MaterialApp(
          title: F.title,
          debugShowCheckedModeBanner: false,
          locale: Locale(languageCode),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Fondo oscuro deep
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: _flavorBanner(
            child: const FocusPage(),
            show: F.appFlavor == Flavor.dev,
          ),
        );
      },
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
