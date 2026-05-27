// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FocusFlow';

  @override
  String get focusMode => 'Enfoque';

  @override
  String get shortBreak => 'Descanso Corto';

  @override
  String get longBreak => 'Descanso Largo';

  @override
  String get start => 'Empezar';

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Continuar';

  @override
  String get skip => 'Saltar';

  @override
  String get reset => 'Reiniciar';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get initializationError => 'Error fatal de inicialización';

  @override
  String minBreak(int minutes) {
    return '$minutes min descanso';
  }

  @override
  String get timerShowcaseTitle => 'Temporizador';

  @override
  String get timerShowcaseDesc =>
      'Ajusta tu tiempo de enfoque. Pulsa el centro para usar el selector preciso de tiempo.';

  @override
  String get controlsShowcaseTitle => 'Controles de Sesión';

  @override
  String get controlsShowcaseDesc =>
      'Inicia, pausa o reinicia tu sesión. Usa el botón de Modo Inmersivo (derecha) para ocultar distracciones.';

  @override
  String get settingsAndHelp => 'Ajustes y Ayuda';

  @override
  String get alarmSound => 'Sonido de Alarma';

  @override
  String get alarmSoundSubtitle =>
      'Si se desactiva, solo vibrará al finalizar.';

  @override
  String get autoTransition => 'Transición Automática';

  @override
  String get autoTransitionSubtitle =>
      'Solo funciona con la app abierta. En segundo plano será manual.';

  @override
  String get breaks => 'Descansos';

  @override
  String get breaksSubtitle => 'Configura tus descansos automáticos';

  @override
  String breaksPresetSubtitle(int minutes) {
    return '$minutes min preestablecidos';
  }

  @override
  String get wallpaper => 'Fondo de Pantalla';

  @override
  String get viewTutorial => 'Ver Tutorial';

  @override
  String get feedback => 'Enviar Feedback / Reportar Bug';

  @override
  String get feedbackSubtitle => '¡Tu opinión nos ayuda a mejorar!';

  @override
  String versionInfo(String version) {
    return 'Versión $version (Beta)';
  }

  @override
  String get languageMenuTitle => 'Idioma';

  @override
  String get selectLanguage => 'Selecciona tu idioma preferido';

  @override
  String get save => 'Guardar';

  @override
  String get back => 'Atrás';

  @override
  String get bugReport => '¿Es un Bug? 🐞';

  @override
  String get featureIdea => '¿Una Idea? 💡';

  @override
  String get bugHint => 'Describe el error que encontraste...';

  @override
  String get ideaHint => 'Cuéntanos qué te gustaría ver...';

  @override
  String get submitFeedback => 'Enviar Feedback';

  @override
  String get thanks => '¡Gracias!';

  @override
  String errorSending(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get solid => 'Sólido';

  @override
  String get gradient => 'Gradiente';

  @override
  String get deletePreset => 'Eliminar preajuste';

  @override
  String get accept => 'Aceptar';

  @override
  String get sessionsHistory => 'Historial de Sesiones';

  @override
  String get sessionsHistoryDesc =>
      'Revisa tu rendimiento, tiempo enfocado y ciclos completados.';

  @override
  String get premiumExperience => 'Experiencia Premium';

  @override
  String get premiumExperienceDesc =>
      'Desbloquea todas las mezclas de sonido ambiental, elimina los anuncios y accede a funciones exclusivas para un enfoque total.';

  @override
  String get premiumFeatureTitle => 'Premium';

  @override
  String get premiumFeatureDesc =>
      'Desbloquea todas las funciones y elimina los anuncios.';

  @override
  String get soundMixerTitle => 'Mezclador de Sonido';

  @override
  String get focusModeTitle => 'Modo Foco';

  @override
  String get lockDuringSession => 'Bloqueado durante la sesión';

  @override
  String get flipToStart =>
      'El temporizador solo iniciará cuando pongas el móvil boca abajo.';

  @override
  String get disableHardcoreWarning =>
      'Para desactivar este modo, debes reiniciar la sesión por completo.';

  @override
  String get outOfFocus => '¡FUERA DE FOCO! Pon el móvil boca abajo.';

  @override
  String get activatedFlipToStart =>
      '¡Activado! Voltea el móvil para comenzar.';

  @override
  String get deepFocusActive => 'Foco profundo activo. Sigue así.';

  @override
  String get beCarefulFlip => '¡Cuidado! Pon el móvil boca abajo.';

  @override
  String get focusModeArmed =>
      'Modo Focus armado. Pulsa Play y voltea el móvil.';

  @override
  String get sessionCompletedTitle => '¡Sesión Completada!';

  @override
  String get timesLifted => 'Veces levantado';

  @override
  String get timeLost => 'Tiempo perdido';

  @override
  String get valueYourTime => '¿Realmente valoras tu tiempo?';

  @override
  String get notMuch => 'No mucho';

  @override
  String get yesValue => 'Sí, lo valoro';

  @override
  String get finishSession => 'Terminar sesión';

  @override
  String get perfPerfect =>
      '¡Casi perfecto! Un pequeño desliz, pero lo has logrado.';

  @override
  String get perfNotBad =>
      'No ha estado mal, pero necesitas un poco más de disciplina.';

  @override
  String get perfMosquito =>
      '¿Necesitas una brújula? Tienes menos concentración que un mosquito. ¡A la próxima mejor!';

  @override
  String get perfGood => 'Has mantenido el foco con éxito. ¡Gran trabajo!';

  @override
  String get dogPhrase1 =>
      'Haciendo pedido por Amazon de un hueso gourmet... 🍖';

  @override
  String get dogPhrase2 =>
      'Calculando cuántas salchichas puede comprar con tu distracción... 🌭';

  @override
  String get dogPhrase3 =>
      'Tu falta de foco es su oportunidad de conseguir un juguete nuevo... 🧸';

  @override
  String get dogPhrase4 =>
      'Ahorrando para el curso de \'Cómo ladrarle al cartero sin despertarte\'... 📬';

  @override
  String get dogPhrase5 =>
      'Gracias por financiar su jubilación en el parque... 🌳';

  @override
  String get dogPhrase6 =>
      'Tu tiempo perdido se ha convertido en premios de bacon... 🥓';

  @override
  String get dogPhrase7 =>
      'Invirtiendo en el fondo de inversión \'Pelotas de Tenis Ilimitadas\'... 🎾';

  @override
  String get dogPhrase8 =>
      'Gestionando la suscripción premium de \'Olores del Mundo\'... 🐕';

  @override
  String get dogPhrase9 =>
      'Convertiremos tu dinero perdido en una cama ortopédica de lujo... 💤';

  @override
  String get dogPhrase10 =>
      'Tu distracción paga las sesiones de spa canino de este mes... 🧼';

  @override
  String get mixerLabel => 'Ambiente';

  @override
  String get mixerDesc =>
      'Crea tu atmósfera ideal combinando sonidos de lluvia, fuego o ruido marrón. Ajusta los niveles a tu gusto para aislarte de distracciones.';

  @override
  String get settingsHelpDesc =>
      'Gestiona las preferencias de la app a tu gusto.';

  @override
  String get ambienceShowcaseTitle => 'Ambiente Personalizado';

  @override
  String get ambienceShowcaseDesc =>
      'Crea tu atmósfera ideal combinando sonidos de lluvia, fuego o ruido marrón. Ajusta los niveles a tu gusto para aislarte de distracciones.';

  @override
  String get focusModeShowcaseTitle => 'Modo Foco Profundo';

  @override
  String get focusModeShowcaseDesc =>
      'Activa este modo para obligarte a dejar el móvil boca abajo. Si lo levantas, la sesión se pausará, ayudándote a evitar tentaciones.';

  @override
  String get timeLostEquivalent => 'Ese tiempo perdido equivale a:';

  @override
  String get donationQuestion =>
      'Si no valoras ese dinero, ¿te gustaría donárselo al amigo de la foto?';

  @override
  String get noThanks => 'No, gracias';

  @override
  String get sure => '¡Claro!';

  @override
  String get donationFuture =>
      'Si valoras nuestro trabajo y quieres apoyar el desarrollo de FocusFlow, ¡puedes invitarnos a un café!';

  @override
  String get comingSoon => 'Invitar a un café ☕';

  @override
  String get breaksDesc =>
      'Configura un tiempo de descanso predeterminado. Si lo haces, las sesiones comenzarán automáticamente sin preguntar cada vez.';

  @override
  String get sendFeedback => 'Enviar Feedback';

  @override
  String get resetSessionTitle => '¿Reiniciar sesión?';

  @override
  String get resetSessionMessage =>
      'Se perderá el progreso de la sesión actual.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tapToAdjust => 'TOCA PARA AJUSTAR';

  @override
  String minOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get ready => 'Listo';

  @override
  String get mixerTab => 'Mezclador';

  @override
  String get backgroundSoundTab => 'Sonido de fondo';

  @override
  String get rainLabel => 'Lluvia';

  @override
  String get fireLabel => 'Fuego';

  @override
  String get wavesLabel => 'Olas';

  @override
  String get premiumLoadMixTitle => 'Cargar mezclas guardadas';

  @override
  String get premiumLoadMixDesc =>
      'Accede y carga al instante tus mezclas de sonido personalizadas que has guardado previamente.';

  @override
  String get mixer => 'Mezclador';

  @override
  String get backgroundSound => 'Sonido de fondo';

  @override
  String get rain => 'Lluvia';

  @override
  String get fire => 'Fuego';

  @override
  String get waves => 'Olas';

  @override
  String get mixSaved => 'Mix guardado.';

  @override
  String get saveSoundMixes => 'Guardar mezclas de sonido';

  @override
  String get saveSoundMixesDesc =>
      'Guarda tus configuraciones de sonido ambientale para usarlas más tarde.';

  @override
  String get none => 'Ninguno';

  @override
  String get frogs => 'Ranas';

  @override
  String get library => 'Biblioteca';

  @override
  String get park => 'Parque';

  @override
  String get stream => 'Arroyo';

  @override
  String get midnight => 'Media noche';

  @override
  String get noSavedMixes => 'No tienes mezclas guardadas aún.';

  @override
  String get savedMixesTitle => 'Mezclas Guardadas';

  @override
  String get lastMixLabel => '(Última)';

  @override
  String get getAccess => 'Obtener';

  @override
  String showingResultsFor(String date) {
    return 'Mostrando resultados del $date';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get noSessionsForDate => 'No hay sesiones para esta fecha';

  @override
  String get noSessionsRegistered => 'No hay sesiones registradas';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get focusSession => 'Sesión de Enfoque';

  @override
  String get breakLabel => 'Descanso';

  @override
  String durationLabel(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get endFocusCycleTitle => '¿Terminar ciclo de foco?';

  @override
  String get endFocusCycleMessage =>
      'Estás en una sesión con descansos programados. Si reinicias ahora, se cancelará todo el ciclo actual y volverás al inicio.\n\n¿Estás seguro de que quieres terminar?';

  @override
  String get cancelCurrentSessionMessage =>
      'La sesión actual se cancelará.\n\n¿Estás seguro de que quieres continuar?';

  @override
  String get sessionCycle => 'Ciclo de Sesiones';

  @override
  String focusCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Enfoques',
      one: '1 Enfoque',
    );
    return '$_temp0';
  }

  @override
  String breakCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Descansos',
      one: '1 Descanso',
    );
    return '$_temp0';
  }

  @override
  String totalTimeLabel(String time) {
    return 'Tiempo total: $time';
  }

  @override
  String get historyTitle => 'Historial de Sesiones';

  @override
  String get premiumFeature => 'Función Premium';

  @override
  String unlockFeature(String feature) {
    return 'Desbloquea \"$feature\"';
  }

  @override
  String get premiumActivated =>
      '¡Premium activado! Funcionalidad desbloqueada (DEV).';

  @override
  String get purchasesSoon => 'Compras próximamente.';

  @override
  String get priceOnly => 'Solo ';

  @override
  String get oneTimePayment => ' / pago único';

  @override
  String get lastActivatedLabel => ' (Última)';

  @override
  String mixDetail(int rain, int fire, int waves, String last) {
    return 'Lluvia: $rain% • Fuego: $fire% • Olas: $waves%$last';
  }

  @override
  String get devVersionTitle => 'Versión de Desarrollo';

  @override
  String get devVersionDesc =>
      'Estás utilizando una versión de prueba (Dev).\n• Las funciones Premium se pueden simular.\n• Puede contener errores experimentales.\n• ¡Ayúdanos a mejorar! Envía tus ideas o reporta fallos desde el menú de Ajustes (icono ☰).';

  @override
  String get devVersionAction => 'Entendido';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get currentStreak => 'Racha Actual';

  @override
  String streakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Días',
      one: '1 Día',
    );
    return '$_temp0';
  }

  @override
  String get totalFocused => 'Total Enfocado';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String weekRange(String start, String end) {
    return 'Semana $start - $end';
  }

  @override
  String get errorLoadingStats => 'Error cargando estadísticas:';

  @override
  String get close => 'Cerrar';

  @override
  String get breakFinished => 'Descanso Finalizado';

  @override
  String get startTimeLabel => 'Hora de inicio';

  @override
  String get plannedDurationLabel => 'Duración planeada';

  @override
  String get actualDurationLabel => 'Duración real';

  @override
  String get focusModeLabel => 'Modo FOCUS';

  @override
  String get activated => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get distractionsLabel => 'Distracciones';

  @override
  String distractionsTimes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String get cycleSummary => 'Resumen del Ciclo';

  @override
  String get cycleBreakdown => 'Desglose del ciclo';

  @override
  String get focusTime => 'Tiempo de foco';

  @override
  String get breakTime => 'Tiempo de descanso';

  @override
  String get totalDistractions => 'Distracciones totales';

  @override
  String get totalTimeLostLabel => 'Tiempo perdido total';

  @override
  String sessionsGroupTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sesiones',
      one: '1 Sesión',
    );
    return '$_temp0';
  }

  @override
  String get canceledStatus => 'Cancelado';

  @override
  String get addBreakTitle => '¿Añadir descanso?';

  @override
  String get addBreakMessage =>
      '¿Quieres añadir un tiempo de descanso después de esta sesión?';

  @override
  String get hardcoreFlipMessage =>
      'Modo Focus activo: Voltea el móvil boca abajo para que el tiempo empiece a correr.';

  @override
  String get hourSuffixShort => 'h';

  @override
  String get minuteSuffixShort => 'm';

  @override
  String get secondSuffixShort => 's';

  @override
  String get premiumPrice => '4,99 €';

  @override
  String get notificationTimerCompleteTitle => '¡Tiempo completado!';

  @override
  String get notificationTimerCompleteBody =>
      'Buen trabajo. Tómate un merecido descanso.';

  @override
  String get notificationPenaltyTitle => '¡Vuelve a tu foco!';

  @override
  String get notificationPenaltyBody =>
      'Por favor, voltea tu teléfono boca abajo para continuar.';

  @override
  String get notificationReminderTitle => '¡Es hora de enfocarse!';

  @override
  String get notificationReminderBody =>
      'Abre FocusFlow y alcanza tus metas de hoy.';

  @override
  String get notificationChannelAlertsName => 'Alertas de FocusFlow';

  @override
  String get notificationChannelAlertsDescription =>
      'Notificaciones informativas de la aplicación';

  @override
  String get notificationChannelRemindersName => 'Recordatorios';

  @override
  String get notificationChannelRemindersDescription =>
      'Recordatorios para mantener el enfoque';

  @override
  String notificationRemainingTime(String time) {
    return 'Tiempo restante: $time';
  }

  @override
  String get phaseFocus => 'Enfoque';

  @override
  String get phaseBreak => 'Descanso';

  @override
  String get phaseWaiting => 'Preparación';
}
