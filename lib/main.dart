import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Imports de tu proyecto (asegúrate que las rutas sean correctas)
import 'package:focus_flow/app/injection.dart';
import 'package:focus_flow/data/models/premium_status.dart';
import 'package:focus_flow/presentation/bloc/focus_bloc.dart';
import 'package:focus_flow/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hive & Dependencias
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(PremiumStatusAdapter());
  await configureDependencies();

  // 2. CONFIGURACIÓN DE DEPURACIÓN (LA CLAVE)
  // Esto fuerza a que salga la ventana sí o sí mientras desarrollas
  ConsentDebugSettings debugSettings = ConsentDebugSettings(
    debugGeography: DebugGeography.debugGeographyEea, // <--- FUERZA EUROPA
    // testIdentifiers: ['TU_HASH_ID_DE_LA_CONSOLA'], // Ver nota abajo si no sale
  );

  final params = ConsentRequestParameters(
    consentDebugSettings: debugSettings,
  );

  // 3. RESET (IMPORTANTE: Solo para desarrollo)
  // Borra la memoria de "ya he aceptado" para que te vuelva a preguntar.
  // COMENTA ESTA LÍNEA CUANDO YA TE HAYA SALIDO UNA VEZ.
  await ConsentInformation.instance.reset();

  print('[main] Solicitando actualización de consentimiento...');
  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
        () async {
      // ÉXITO AL CONECTAR
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        print('[main] Formulario disponible. Cargando...');
        _loadConsentForm();
      } else {
        print('[main] No hace falta formulario (¿Fuera de EU?). Iniciando Ads.');
        _initializeAds();
      }
    },
        (FormError error) {
      // ERROR DE CONEXIÓN O CONFIGURACIÓN
      print('[main] Error ConsentInfo: ${error.message} (Code: ${error.errorCode})');
      _initializeAds(); // Intentamos cargar anuncios aunque falle el consentimiento
    },
  );

  runApp(const App());
}

void _loadConsentForm() {
  ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
      var status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        consentForm.show(
              (FormError? formError) {
            print('[main] Formulario cerrado o error: ${formError?.message}');
            _loadConsentForm(); // Recargar para ver si cambió el estatus
          },
        );
      } else {
        print('[main] Consentimiento completado. Iniciando Ads.');
        _initializeAds();
      }
    },
        (formError) {
      print('[main] Error cargando ventana: ${formError.message}');
      _initializeAds();
    },
  );
}

void _initializeAds() async {
  print('[main] INICIALIZANDO ADMOB...');
  await MobileAds.instance.initialize();
  print('[main] ✅ SDK Inicializado. Esperando al Banner...');
}

class App extends StatelessWidget {
  const App({super.key});
  // ... (El resto de tu clase App igual que antes) ...
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
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}