import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focus_flow/flavors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

import '../widgets/dialogs/dev_version_dialog.dart';
import '../widgets/focus_view.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  Key _viewKey = UniqueKey();
  DateTime? _pauseTime;
  static const _inactivityThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkTutorial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTime = DateTime.now();
      FlutterBackgroundService().invoke('sendEvent', {'event': 'ui_paused'});
    } else if (state == AppLifecycleState.resumed) {
      bool shouldReset = false;
      if (_pauseTime != null) {
        final inactiveDuration = DateTime.now().difference(_pauseTime!);
        if (inactiveDuration > _inactivityThreshold) {
          shouldReset = true;
        }
      }

      if (shouldReset) {
        setState(() {
          _viewKey = UniqueKey();
          _pauseTime = null;
        });
      }
      
      // Always sync Live Activity state on resume
      FlutterBackgroundService().invoke('sendEvent', {'event': 'ui_resumed'});
    }
  }

  Future<void> _checkTutorial() async {
    try {
      var box = await Hive.openBox('settings');
      bool seen = box.get('tutorial_seen', defaultValue: false);
      if (!seen) {
        // El showcase se inicia dentro de FocusView o mediante el ShowCaseWidget envolvente.
        // Aquí solo manejamos la lógica de persistencia si fuera necesario antes de empezar.
      }
    } catch (e) {
      debugPrint("Error checking tutorial: $e");
    }
  }

  void _handleTutorialCompletion() async {
    var box = await Hive.openBox('settings');
    await box.put('tutorial_seen', true);

    if (F.appFlavor == Flavor.dev) {
      bool devNoticeSeen = box.get('dev_notice_seen', defaultValue: false);
      if (!devNoticeSeen) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const DevVersionDialog(),
          );
        }
        await box.put('dev_notice_seen', true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: _handleTutorialCompletion,
      onDismiss: (_) => _handleTutorialCompletion(),
      builder: (context) => FocusView(key: _viewKey),
    );
  }
}
