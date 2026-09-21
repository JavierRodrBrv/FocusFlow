import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FocusFlow'**
  String get appTitle;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusMode;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanishFlag.
  ///
  /// In en, this message translates to:
  /// **'🇪🇸'**
  String get spanishFlag;

  /// No description provided for @englishFlag.
  ///
  /// In en, this message translates to:
  /// **'🇺🇸'**
  String get englishFlag;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Fatal initialization error'**
  String get initializationError;

  /// No description provided for @minBreak.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min break'**
  String minBreak(int minutes);

  /// No description provided for @timerShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerShowcaseTitle;

  /// No description provided for @timerShowcaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust your focus time. Tap the center to use the precise time selector.'**
  String get timerShowcaseDesc;

  /// No description provided for @controlsShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Controls'**
  String get controlsShowcaseTitle;

  /// No description provided for @controlsShowcaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Start, pause, or reset your session. Use the Immersive Mode button (right) to hide distractions.'**
  String get controlsShowcaseDesc;

  /// No description provided for @settingsAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Settings & Help'**
  String get settingsAndHelp;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// No description provided for @alarmSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If disabled, it will only vibrate when finished.'**
  String get alarmSoundSubtitle;

  /// No description provided for @autoTransition.
  ///
  /// In en, this message translates to:
  /// **'Auto Transition'**
  String get autoTransition;

  /// No description provided for @autoTransitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only works with app open. In background it will be manual.'**
  String get autoTransitionSubtitle;

  /// No description provided for @breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get breaks;

  /// No description provided for @breaksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your automatic breaks'**
  String get breaksSubtitle;

  /// No description provided for @breaksPresetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min preset'**
  String breaksPresetSubtitle(int minutes);

  /// No description provided for @wallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// No description provided for @viewTutorial.
  ///
  /// In en, this message translates to:
  /// **'View Tutorial'**
  String get viewTutorial;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback / Report Bug'**
  String get feedback;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your opinion helps us improve!'**
  String get feedbackSubtitle;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Beta)'**
  String versionInfo(String version);

  /// No description provided for @languageMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Is it a Bug? 🐞'**
  String get bugReport;

  /// No description provided for @featureIdea.
  ///
  /// In en, this message translates to:
  /// **'An Idea? 💡'**
  String get featureIdea;

  /// No description provided for @bugHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the error you found...'**
  String get bugHint;

  /// No description provided for @ideaHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you\'d like to see...'**
  String get ideaHint;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get submitFeedback;

  /// No description provided for @thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks!'**
  String get thanks;

  /// No description provided for @errorSending.
  ///
  /// In en, this message translates to:
  /// **'Error sending: {error}'**
  String errorSending(String error);

  /// No description provided for @solid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get solid;

  /// No description provided for @gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// No description provided for @deletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete preset'**
  String get deletePreset;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @sessionsHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionsHistory;

  /// No description provided for @sessionsHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Review your performance, focused time, and completed cycles.'**
  String get sessionsHistoryDesc;

  /// No description provided for @premiumExperience.
  ///
  /// In en, this message translates to:
  /// **'Premium Experience'**
  String get premiumExperience;

  /// No description provided for @premiumExperienceDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock all ambient sound mixes, remove ads, and access exclusive features for total focus.'**
  String get premiumExperienceDesc;

  /// No description provided for @premiumFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumFeatureTitle;

  /// No description provided for @premiumFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features and remove ads.'**
  String get premiumFeatureDesc;

  /// No description provided for @soundMixerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound Mixer'**
  String get soundMixerTitle;

  /// No description provided for @focusModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusModeTitle;

  /// No description provided for @lockDuringSession.
  ///
  /// In en, this message translates to:
  /// **'Locked during session'**
  String get lockDuringSession;

  /// No description provided for @flipToStart.
  ///
  /// In en, this message translates to:
  /// **'The timer will only start when you put the phone face down.'**
  String get flipToStart;

  /// No description provided for @disableHardcoreWarning.
  ///
  /// In en, this message translates to:
  /// **'To disable this mode, you must reset the session completely.'**
  String get disableHardcoreWarning;

  /// No description provided for @outOfFocus.
  ///
  /// In en, this message translates to:
  /// **'OUT OF FOCUS! Put the phone face down.'**
  String get outOfFocus;

  /// No description provided for @activatedFlipToStart.
  ///
  /// In en, this message translates to:
  /// **'Activated! Flip the phone to start.'**
  String get activatedFlipToStart;

  /// No description provided for @deepFocusActive.
  ///
  /// In en, this message translates to:
  /// **'Deep focus active. Keep it up.'**
  String get deepFocusActive;

  /// No description provided for @beCarefulFlip.
  ///
  /// In en, this message translates to:
  /// **'Be careful! Put the phone face down.'**
  String get beCarefulFlip;

  /// No description provided for @focusModeArmed.
  ///
  /// In en, this message translates to:
  /// **'Focus mode armed. Press Play and flip the phone.'**
  String get focusModeArmed;

  /// No description provided for @sessionCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Completed!'**
  String get sessionCompletedTitle;

  /// No description provided for @timesLifted.
  ///
  /// In en, this message translates to:
  /// **'Times lifted'**
  String get timesLifted;

  /// No description provided for @timeLost.
  ///
  /// In en, this message translates to:
  /// **'Time lost'**
  String get timeLost;

  /// No description provided for @valueYourTime.
  ///
  /// In en, this message translates to:
  /// **'Do you really value your time?'**
  String get valueYourTime;

  /// No description provided for @notMuch.
  ///
  /// In en, this message translates to:
  /// **'Not much'**
  String get notMuch;

  /// No description provided for @yesValue.
  ///
  /// In en, this message translates to:
  /// **'Yes, I value it'**
  String get yesValue;

  /// No description provided for @finishSession.
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get finishSession;

  /// No description provided for @perfPerfect.
  ///
  /// In en, this message translates to:
  /// **'Almost perfect! A small slip, but you made it.'**
  String get perfPerfect;

  /// No description provided for @perfNotBad.
  ///
  /// In en, this message translates to:
  /// **'Not bad, but you need a bit more discipline.'**
  String get perfNotBad;

  /// No description provided for @perfMosquito.
  ///
  /// In en, this message translates to:
  /// **'Need a compass? You have less concentration than a mosquito. Better luck next time!'**
  String get perfMosquito;

  /// No description provided for @perfGood.
  ///
  /// In en, this message translates to:
  /// **'You\'ve stayed focused successfully. Great job!'**
  String get perfGood;

  /// No description provided for @dogPhrase1.
  ///
  /// In en, this message translates to:
  /// **'Ordering a gourmet bone on Amazon... 🍖'**
  String get dogPhrase1;

  /// No description provided for @dogPhrase2.
  ///
  /// In en, this message translates to:
  /// **'Calculating how many sausages I can buy with your distraction... 🌭'**
  String get dogPhrase2;

  /// No description provided for @dogPhrase3.
  ///
  /// In en, this message translates to:
  /// **'Your lack of focus is an opportunity to get a new toy... 🧸'**
  String get dogPhrase3;

  /// No description provided for @dogPhrase4.
  ///
  /// In en, this message translates to:
  /// **'Saving for the \'How to bark at the mailman without waking you up\' course... 📬'**
  String get dogPhrase4;

  /// No description provided for @dogPhrase5.
  ///
  /// In en, this message translates to:
  /// **'Thanks for funding my retirement in the park... 🌳'**
  String get dogPhrase5;

  /// No description provided for @dogPhrase6.
  ///
  /// In en, this message translates to:
  /// **'Your lost time has turned into bacon treats... 🥓'**
  String get dogPhrase6;

  /// No description provided for @dogPhrase7.
  ///
  /// In en, this message translates to:
  /// **'Investing in the \'Unlimited Tennis Balls\' fund... 🎾'**
  String get dogPhrase7;

  /// No description provided for @dogPhrase8.
  ///
  /// In en, this message translates to:
  /// **'Managing the \'Smells of the World\' premium subscription... 🐕'**
  String get dogPhrase8;

  /// No description provided for @dogPhrase9.
  ///
  /// In en, this message translates to:
  /// **'Converting your lost money into a luxury orthopedic bed... 💤'**
  String get dogPhrase9;

  /// No description provided for @dogPhrase10.
  ///
  /// In en, this message translates to:
  /// **'Your distraction pays for this month\'s dog spa sessions... 🧼'**
  String get dogPhrase10;

  /// No description provided for @mixerLabel.
  ///
  /// In en, this message translates to:
  /// **'Ambience'**
  String get mixerLabel;

  /// No description provided for @mixerDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your ideal atmosphere by combining sounds of rain, fire, or brown noise. Adjust levels to your liking to isolate yourself from distractions.'**
  String get mixerDesc;

  /// No description provided for @settingsHelpDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage app preferences to your liking.'**
  String get settingsHelpDesc;

  /// No description provided for @ambienceShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Ambience'**
  String get ambienceShowcaseTitle;

  /// No description provided for @ambienceShowcaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your ideal atmosphere by combining sounds of rain, fire, or brown noise. Adjust levels to your liking to isolate yourself from distractions.'**
  String get ambienceShowcaseDesc;

  /// No description provided for @focusModeShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Focus Mode'**
  String get focusModeShowcaseTitle;

  /// No description provided for @focusModeShowcaseDesc.
  ///
  /// In en, this message translates to:
  /// **'Activate this mode to force yourself to leave the phone face down. If you lift it, the session will pause, helping you avoid temptations.'**
  String get focusModeShowcaseDesc;

  /// No description provided for @timeLostEquivalent.
  ///
  /// In en, this message translates to:
  /// **'That lost time is equivalent to:'**
  String get timeLostEquivalent;

  /// No description provided for @donationQuestion.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t value that money, would you like to donate it to the friend in the photo?'**
  String get donationQuestion;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get noThanks;

  /// No description provided for @sure.
  ///
  /// In en, this message translates to:
  /// **'Sure!'**
  String get sure;

  /// No description provided for @donationFuture.
  ///
  /// In en, this message translates to:
  /// **'If you value our work and want to support the development of FocusFlow, you can buy us a coffee!'**
  String get donationFuture;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Buy a coffee ☕'**
  String get comingSoon;

  /// No description provided for @breaksDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure a default break time. If you do, sessions will start automatically without asking every time.'**
  String get breaksDesc;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @resetSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset session?'**
  String get resetSessionTitle;

  /// No description provided for @resetSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'Current session progress will be lost.'**
  String get resetSessionMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tapToAdjust.
  ///
  /// In en, this message translates to:
  /// **'TAP TO ADJUST'**
  String get tapToAdjust;

  /// No description provided for @minOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minOnly(int minutes);

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @mixerTab.
  ///
  /// In en, this message translates to:
  /// **'Mixer'**
  String get mixerTab;

  /// No description provided for @backgroundSoundTab.
  ///
  /// In en, this message translates to:
  /// **'Background Sound'**
  String get backgroundSoundTab;

  /// No description provided for @rainLabel.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rainLabel;

  /// No description provided for @fireLabel.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fireLabel;

  /// No description provided for @wavesLabel.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get wavesLabel;

  /// No description provided for @premiumLoadMixTitle.
  ///
  /// In en, this message translates to:
  /// **'Load saved mixes'**
  String get premiumLoadMixTitle;

  /// No description provided for @premiumLoadMixDesc.
  ///
  /// In en, this message translates to:
  /// **'Instantly access and load your previously saved custom sound mixes.'**
  String get premiumLoadMixDesc;

  /// No description provided for @mixer.
  ///
  /// In en, this message translates to:
  /// **'Mixer'**
  String get mixer;

  /// No description provided for @backgroundSound.
  ///
  /// In en, this message translates to:
  /// **'Background sound'**
  String get backgroundSound;

  /// No description provided for @rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// No description provided for @waves.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get waves;

  /// No description provided for @mixSaved.
  ///
  /// In en, this message translates to:
  /// **'Mix saved.'**
  String get mixSaved;

  /// No description provided for @saveSoundMixes.
  ///
  /// In en, this message translates to:
  /// **'Save sound mixes'**
  String get saveSoundMixes;

  /// No description provided for @saveSoundMixesDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your ambient sound configurations for later use.'**
  String get saveSoundMixesDesc;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @frogs.
  ///
  /// In en, this message translates to:
  /// **'Frogs'**
  String get frogs;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @park.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get park;

  /// No description provided for @stream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get stream;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get midnight;

  /// No description provided for @noSavedMixes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any saved mixes yet.'**
  String get noSavedMixes;

  /// No description provided for @savedMixesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Mixes'**
  String get savedMixesTitle;

  /// No description provided for @lastMixLabel.
  ///
  /// In en, this message translates to:
  /// **'(Last)'**
  String get lastMixLabel;

  /// No description provided for @getAccess.
  ///
  /// In en, this message translates to:
  /// **'Get Access'**
  String get getAccess;

  /// No description provided for @showingResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Showing results for {date}'**
  String showingResultsFor(String date);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noSessionsForDate.
  ///
  /// In en, this message translates to:
  /// **'No sessions for this date'**
  String get noSessionsForDate;

  /// No description provided for @noSessionsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No sessions registered'**
  String get noSessionsRegistered;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @focusSession.
  ///
  /// In en, this message translates to:
  /// **'Focus Session'**
  String get focusSession;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String durationLabel(String duration);

  /// No description provided for @endFocusCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'End focus cycle?'**
  String get endFocusCycleTitle;

  /// No description provided for @endFocusCycleMessage.
  ///
  /// In en, this message translates to:
  /// **'You are in a session with scheduled breaks. If you reset now, the entire current cycle will be canceled and you will return to the beginning.\n\nAre you sure you want to end?'**
  String get endFocusCycleMessage;

  /// No description provided for @cancelCurrentSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'The current session will be canceled.\n\nAre you sure you want to continue?'**
  String get cancelCurrentSessionMessage;

  /// No description provided for @sessionCycle.
  ///
  /// In en, this message translates to:
  /// **'Session Cycle'**
  String get sessionCycle;

  /// No description provided for @focusCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Focus} other{{count} Focuses}}'**
  String focusCount(num count);

  /// No description provided for @breakCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Break} other{{count} Breaks}}'**
  String breakCount(num count);

  /// No description provided for @totalTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total time: {time}'**
  String totalTimeLabel(String time);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get historyTitle;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumFeature;

  /// No description provided for @unlockFeature.
  ///
  /// In en, this message translates to:
  /// **'Unlock \"{feature}\"'**
  String unlockFeature(String feature);

  /// No description provided for @premiumActivated.
  ///
  /// In en, this message translates to:
  /// **'Premium activated! Functionality unlocked (DEV).'**
  String get premiumActivated;

  /// No description provided for @purchasesSoon.
  ///
  /// In en, this message translates to:
  /// **'Purchases coming soon.'**
  String get purchasesSoon;

  /// No description provided for @priceOnly.
  ///
  /// In en, this message translates to:
  /// **'Only '**
  String get priceOnly;

  /// No description provided for @oneTimePayment.
  ///
  /// In en, this message translates to:
  /// **' / one-time payment'**
  String get oneTimePayment;

  /// No description provided for @lastActivatedLabel.
  ///
  /// In en, this message translates to:
  /// **' (Last)'**
  String get lastActivatedLabel;

  /// No description provided for @mixDetail.
  ///
  /// In en, this message translates to:
  /// **'Rain: {rain}% • Fire: {fire}% • Waves: {waves}%{last}'**
  String mixDetail(int rain, int fire, int waves, String last);

  /// No description provided for @devVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Development Version'**
  String get devVersionTitle;

  /// No description provided for @devVersionDesc.
  ///
  /// In en, this message translates to:
  /// **'You are using a testing version (Dev).\n• Premium features can be simulated.\n• It may contain experimental bugs.\n• Help us improve! Send your ideas or report bugs from the Settings menu (☰ icon).'**
  String get devVersionDesc;

  /// No description provided for @devVersionAction.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get devVersionAction;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day} other{{count} Days}}'**
  String streakDays(num count);

  /// No description provided for @totalFocused.
  ///
  /// In en, this message translates to:
  /// **'Total Focused'**
  String get totalFocused;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @weekRange.
  ///
  /// In en, this message translates to:
  /// **'Week {start} - {end}'**
  String weekRange(String start, String end);

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading statistics:'**
  String get errorLoadingStats;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @breakFinished.
  ///
  /// In en, this message translates to:
  /// **'Break Finished'**
  String get breakFinished;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @plannedDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned duration'**
  String get plannedDurationLabel;

  /// No description provided for @actualDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual duration'**
  String get actualDurationLabel;

  /// No description provided for @focusModeLabel.
  ///
  /// In en, this message translates to:
  /// **'FOCUS Mode'**
  String get focusModeLabel;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @distractionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Distractions'**
  String get distractionsLabel;

  /// No description provided for @distractionsTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String distractionsTimes(num count);

  /// No description provided for @cycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle Summary'**
  String get cycleSummary;

  /// No description provided for @cycleBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cycle breakdown'**
  String get cycleBreakdown;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTime;

  /// No description provided for @breakTime.
  ///
  /// In en, this message translates to:
  /// **'Break time'**
  String get breakTime;

  /// No description provided for @totalDistractions.
  ///
  /// In en, this message translates to:
  /// **'Total distractions'**
  String get totalDistractions;

  /// No description provided for @totalTimeLostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total time lost'**
  String get totalTimeLostLabel;

  /// No description provided for @sessionsGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Session} other{{count} Sessions}}'**
  String sessionsGroupTitle(num count);

  /// No description provided for @canceledStatus.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceledStatus;

  /// No description provided for @addBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Add break?'**
  String get addBreakTitle;

  /// No description provided for @addBreakMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add a break time after this session?'**
  String get addBreakMessage;

  /// No description provided for @hardcoreFlipMessage.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode active: Flip the phone face down to start the timer.'**
  String get hardcoreFlipMessage;

  /// No description provided for @hourSuffixShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourSuffixShort;

  /// No description provided for @minuteSuffixShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteSuffixShort;

  /// No description provided for @secondSuffixShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondSuffixShort;

  /// No description provided for @premiumPrice.
  ///
  /// In en, this message translates to:
  /// **'4.99 \$'**
  String get premiumPrice;

  /// No description provided for @notificationTimerCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Complete!'**
  String get notificationTimerCompleteTitle;

  /// No description provided for @notificationTimerCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Good job. Take a well-deserved break.'**
  String get notificationTimerCompleteBody;

  /// No description provided for @notificationPenaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to focus!'**
  String get notificationPenaltyTitle;

  /// No description provided for @notificationPenaltyBody.
  ///
  /// In en, this message translates to:
  /// **'Please flip your phone face down to continue.'**
  String get notificationPenaltyBody;

  /// No description provided for @notificationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to focus!'**
  String get notificationReminderTitle;

  /// No description provided for @notificationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Open FocusFlow and reach your goals today.'**
  String get notificationReminderBody;

  /// No description provided for @notificationChannelAlertsName.
  ///
  /// In en, this message translates to:
  /// **'FocusFlow Alerts'**
  String get notificationChannelAlertsName;

  /// No description provided for @notificationChannelAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Informative app notifications'**
  String get notificationChannelAlertsDescription;

  /// No description provided for @notificationChannelRemindersName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notificationChannelRemindersName;

  /// No description provided for @notificationChannelRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders to maintain focus'**
  String get notificationChannelRemindersDescription;

  /// No description provided for @notificationRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining time: {time}'**
  String notificationRemainingTime(String time);

  /// No description provided for @phaseFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get phaseFocus;

  /// No description provided for @phaseBreak.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get phaseBreak;

  /// No description provided for @phaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get phaseWaiting;

  /// No description provided for @pomodoroCycleDetails.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Cycle Details'**
  String get pomodoroCycleDetails;

  /// No description provided for @pomodoroCycle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Cycle'**
  String get pomodoroCycle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
