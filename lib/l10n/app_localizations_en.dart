// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FocusFlow';

  @override
  String get focusMode => 'Focus';

  @override
  String get shortBreak => 'Short Break';

  @override
  String get longBreak => 'Long Break';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get skip => 'Skip';

  @override
  String get reset => 'Reset';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get spanishFlag => '🇪🇸';

  @override
  String get englishFlag => '🇺🇸';

  @override
  String get initializationError => 'Fatal initialization error';

  @override
  String minBreak(int minutes) {
    return '$minutes min break';
  }

  @override
  String get timerShowcaseTitle => 'Timer';

  @override
  String get timerShowcaseDesc =>
      'Adjust your focus time. Tap the center to use the precise time selector.';

  @override
  String get controlsShowcaseTitle => 'Session Controls';

  @override
  String get controlsShowcaseDesc =>
      'Start, pause, or reset your session. Use the Immersive Mode button (right) to hide distractions.';

  @override
  String get settingsAndHelp => 'Settings & Help';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get alarmSoundSubtitle =>
      'If disabled, it will only vibrate when finished.';

  @override
  String get autoTransition => 'Auto Transition';

  @override
  String get autoTransitionSubtitle =>
      'Only works with app open. In background it will be manual.';

  @override
  String get breaks => 'Breaks';

  @override
  String get breaksSubtitle => 'Configure your automatic breaks';

  @override
  String breaksPresetSubtitle(int minutes) {
    return '$minutes min preset';
  }

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get viewTutorial => 'View Tutorial';

  @override
  String get feedback => 'Send Feedback / Report Bug';

  @override
  String get feedbackSubtitle => 'Your opinion helps us improve!';

  @override
  String versionInfo(String version) {
    return 'Version $version (Beta)';
  }

  @override
  String get languageMenuTitle => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get bugReport => 'Is it a Bug? 🐞';

  @override
  String get featureIdea => 'An Idea? 💡';

  @override
  String get bugHint => 'Describe the error you found...';

  @override
  String get ideaHint => 'Tell us what you\'d like to see...';

  @override
  String get submitFeedback => 'Send Feedback';

  @override
  String get thanks => 'Thanks!';

  @override
  String errorSending(String error) {
    return 'Error sending: $error';
  }

  @override
  String get solid => 'Solid';

  @override
  String get gradient => 'Gradient';

  @override
  String get deletePreset => 'Delete preset';

  @override
  String get accept => 'Accept';

  @override
  String get sessionsHistory => 'Session History';

  @override
  String get sessionsHistoryDesc =>
      'Review your performance, focused time, and completed cycles.';

  @override
  String get premiumExperience => 'Premium Experience';

  @override
  String get premiumExperienceDesc =>
      'Unlock all ambient sound mixes, remove ads, and access exclusive features for total focus.';

  @override
  String get premiumFeatureTitle => 'Premium';

  @override
  String get premiumFeatureDesc => 'Unlock all features and remove ads.';

  @override
  String get soundMixerTitle => 'Sound Mixer';

  @override
  String get focusModeTitle => 'Focus Mode';

  @override
  String get lockDuringSession => 'Locked during session';

  @override
  String get flipToStart =>
      'The timer will only start when you put the phone face down.';

  @override
  String get disableHardcoreWarning =>
      'To disable this mode, you must reset the session completely.';

  @override
  String get outOfFocus => 'OUT OF FOCUS! Put the phone face down.';

  @override
  String get activatedFlipToStart => 'Activated! Flip the phone to start.';

  @override
  String get deepFocusActive => 'Deep focus active. Keep it up.';

  @override
  String get beCarefulFlip => 'Be careful! Put the phone face down.';

  @override
  String get focusModeArmed =>
      'Focus mode armed. Press Play and flip the phone.';

  @override
  String get sessionCompletedTitle => 'Session Completed!';

  @override
  String get timesLifted => 'Times lifted';

  @override
  String get timeLost => 'Time lost';

  @override
  String get valueYourTime => 'Do you really value your time?';

  @override
  String get notMuch => 'Not much';

  @override
  String get yesValue => 'Yes, I value it';

  @override
  String get finishSession => 'Finish session';

  @override
  String get perfPerfect => 'Almost perfect! A small slip, but you made it.';

  @override
  String get perfNotBad => 'Not bad, but you need a bit more discipline.';

  @override
  String get perfMosquito =>
      'Need a compass? You have less concentration than a mosquito. Better luck next time!';

  @override
  String get perfGood => 'You\'ve stayed focused successfully. Great job!';

  @override
  String get dogPhrase1 => 'Ordering a gourmet bone on Amazon... 🍖';

  @override
  String get dogPhrase2 =>
      'Calculating how many sausages I can buy with your distraction... 🌭';

  @override
  String get dogPhrase3 =>
      'Your lack of focus is an opportunity to get a new toy... 🧸';

  @override
  String get dogPhrase4 =>
      'Saving for the \'How to bark at the mailman without waking you up\' course... 📬';

  @override
  String get dogPhrase5 => 'Thanks for funding my retirement in the park... 🌳';

  @override
  String get dogPhrase6 => 'Your lost time has turned into bacon treats... 🥓';

  @override
  String get dogPhrase7 =>
      'Investing in the \'Unlimited Tennis Balls\' fund... 🎾';

  @override
  String get dogPhrase8 =>
      'Managing the \'Smells of the World\' premium subscription... 🐕';

  @override
  String get dogPhrase9 =>
      'Converting your lost money into a luxury orthopedic bed... 💤';

  @override
  String get dogPhrase10 =>
      'Your distraction pays for this month\'s dog spa sessions... 🧼';

  @override
  String get mixerLabel => 'Ambience';

  @override
  String get mixerDesc =>
      'Create your ideal atmosphere by combining sounds of rain, fire, or brown noise. Adjust levels to your liking to isolate yourself from distractions.';

  @override
  String get settingsHelpDesc => 'Manage app preferences to your liking.';

  @override
  String get ambienceShowcaseTitle => 'Custom Ambience';

  @override
  String get ambienceShowcaseDesc =>
      'Create your ideal atmosphere by combining sounds of rain, fire, or brown noise. Adjust levels to your liking to isolate yourself from distractions.';

  @override
  String get focusModeShowcaseTitle => 'Deep Focus Mode';

  @override
  String get focusModeShowcaseDesc =>
      'Activate this mode to force yourself to leave the phone face down. If you lift it, the session will pause, helping you avoid temptations.';

  @override
  String get timeLostEquivalent => 'That lost time is equivalent to:';

  @override
  String get donationQuestion =>
      'If you don\'t value that money, would you like to donate it to the friend in the photo?';

  @override
  String get noThanks => 'No, thanks';

  @override
  String get sure => 'Sure!';

  @override
  String get donationFuture =>
      'If you value our work and want to support the development of FocusFlow, you can buy us a coffee!';

  @override
  String get comingSoon => 'Buy a coffee ☕';

  @override
  String get breaksDesc =>
      'Configure a default break time. If you do, sessions will start automatically without asking every time.';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get resetSessionTitle => 'Reset session?';

  @override
  String get resetSessionMessage => 'Current session progress will be lost.';

  @override
  String get cancel => 'Cancel';

  @override
  String get tapToAdjust => 'TAP TO ADJUST';

  @override
  String minOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get ready => 'Ready';

  @override
  String get mixerTab => 'Mixer';

  @override
  String get backgroundSoundTab => 'Background Sound';

  @override
  String get rainLabel => 'Rain';

  @override
  String get fireLabel => 'Fire';

  @override
  String get wavesLabel => 'Waves';

  @override
  String get premiumLoadMixTitle => 'Load saved mixes';

  @override
  String get premiumLoadMixDesc =>
      'Instantly access and load your previously saved custom sound mixes.';

  @override
  String get mixer => 'Mixer';

  @override
  String get backgroundSound => 'Background sound';

  @override
  String get rain => 'Rain';

  @override
  String get fire => 'Fire';

  @override
  String get waves => 'Waves';

  @override
  String get mixSaved => 'Mix saved.';

  @override
  String get saveSoundMixes => 'Save sound mixes';

  @override
  String get saveSoundMixesDesc =>
      'Save your ambient sound configurations for later use.';

  @override
  String get none => 'None';

  @override
  String get frogs => 'Frogs';

  @override
  String get library => 'Library';

  @override
  String get park => 'Park';

  @override
  String get stream => 'Stream';

  @override
  String get midnight => 'Midnight';

  @override
  String get noSavedMixes => 'You don\'t have any saved mixes yet.';

  @override
  String get savedMixesTitle => 'Saved Mixes';

  @override
  String get lastMixLabel => '(Last)';

  @override
  String get getAccess => 'Get Access';

  @override
  String showingResultsFor(String date) {
    return 'Showing results for $date';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noSessionsForDate => 'No sessions for this date';

  @override
  String get noSessionsRegistered => 'No sessions registered';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get focusSession => 'Focus Session';

  @override
  String get breakLabel => 'Break';

  @override
  String durationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get endFocusCycleTitle => 'End focus cycle?';

  @override
  String get endFocusCycleMessage =>
      'You are in a session with scheduled breaks. If you reset now, the entire current cycle will be canceled and you will return to the beginning.\n\nAre you sure you want to end?';

  @override
  String get cancelCurrentSessionMessage =>
      'The current session will be canceled.\n\nAre you sure you want to continue?';

  @override
  String get sessionCycle => 'Session Cycle';

  @override
  String focusCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Focuses',
      one: '1 Focus',
    );
    return '$_temp0';
  }

  @override
  String breakCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Breaks',
      one: '1 Break',
    );
    return '$_temp0';
  }

  @override
  String totalTimeLabel(String time) {
    return 'Total time: $time';
  }

  @override
  String get historyTitle => 'Session History';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String unlockFeature(String feature) {
    return 'Unlock \"$feature\"';
  }

  @override
  String get premiumActivated =>
      'Premium activated! Functionality unlocked (DEV).';

  @override
  String get purchasesSoon => 'Purchases coming soon.';

  @override
  String get priceOnly => 'Only ';

  @override
  String get oneTimePayment => ' / one-time payment';

  @override
  String get lastActivatedLabel => ' (Last)';

  @override
  String mixDetail(int rain, int fire, int waves, String last) {
    return 'Rain: $rain% • Fire: $fire% • Waves: $waves%$last';
  }

  @override
  String get devVersionTitle => 'Development Version';

  @override
  String get devVersionDesc =>
      'You are using a testing version (Dev).\n• Premium features can be simulated.\n• It may contain experimental bugs.\n• Help us improve! Send your ideas or report bugs from the Settings menu (☰ icon).';

  @override
  String get devVersionAction => 'I understand';

  @override
  String get statistics => 'Statistics';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String streakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String get totalFocused => 'Total Focused';

  @override
  String get thisWeek => 'This Week';

  @override
  String weekRange(String start, String end) {
    return 'Week $start - $end';
  }

  @override
  String get errorLoadingStats => 'Error loading statistics:';

  @override
  String get close => 'Close';

  @override
  String get breakFinished => 'Break Finished';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get plannedDurationLabel => 'Planned duration';

  @override
  String get actualDurationLabel => 'Actual duration';

  @override
  String get focusModeLabel => 'FOCUS Mode';

  @override
  String get activated => 'Activated';

  @override
  String get disabled => 'Disabled';

  @override
  String get distractionsLabel => 'Distractions';

  @override
  String distractionsTimes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get cycleSummary => 'Cycle Summary';

  @override
  String get cycleBreakdown => 'Cycle breakdown';

  @override
  String get focusTime => 'Focus time';

  @override
  String get breakTime => 'Break time';

  @override
  String get totalDistractions => 'Total distractions';

  @override
  String get totalTimeLostLabel => 'Total time lost';

  @override
  String sessionsGroupTitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sessions',
      one: '1 Session',
    );
    return '$_temp0';
  }

  @override
  String get canceledStatus => 'Canceled';

  @override
  String get addBreakTitle => 'Add break?';

  @override
  String get addBreakMessage =>
      'Do you want to add a break time after this session?';

  @override
  String get hardcoreFlipMessage =>
      'Focus Mode active: Flip the phone face down to start the timer.';

  @override
  String get hourSuffixShort => 'h';

  @override
  String get minuteSuffixShort => 'm';

  @override
  String get secondSuffixShort => 's';

  @override
  String get premiumPrice => '4.99 \$';

  @override
  String get notificationTimerCompleteTitle => 'Time Complete!';

  @override
  String get notificationTimerCompleteBody =>
      'Good job. Take a well-deserved break.';

  @override
  String get notificationPenaltyTitle => 'Back to focus!';

  @override
  String get notificationPenaltyBody =>
      'Please flip your phone face down to continue.';

  @override
  String get notificationReminderTitle => 'Time to focus!';

  @override
  String get notificationReminderBody =>
      'Open FocusFlow and reach your goals today.';

  @override
  String get notificationChannelAlertsName => 'FocusFlow Alerts';

  @override
  String get notificationChannelAlertsDescription =>
      'Informative app notifications';

  @override
  String get notificationChannelRemindersName => 'Reminders';

  @override
  String get notificationChannelRemindersDescription =>
      'Reminders to maintain focus';

  @override
  String notificationRemainingTime(String time) {
    return 'Remaining time: $time';
  }

  @override
  String get phaseFocus => 'Focus';

  @override
  String get phaseBreak => 'Break';

  @override
  String get phaseWaiting => 'Preparation';

  @override
  String get pomodoroCycleDetails => 'Pomodoro Cycle Details';

  @override
  String get pomodoroCycle => 'Pomodoro Cycle';
}
