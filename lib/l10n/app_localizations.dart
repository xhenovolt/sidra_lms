import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sidra'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Islamic learning by Almuntahha'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyLearning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get navMyLearning;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @learnerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'learner'**
  String get learnerFallbackName;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearning;

  /// No description provided for @enrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'Your courses'**
  String get enrolledCourses;

  /// No description provided for @noEnrolmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey'**
  String get noEnrolmentsTitle;

  /// No description provided for @noEnrolmentsBody.
  ///
  /// In en, this message translates to:
  /// **'You are not enrolled in any course yet. Explore the catalogue to find a course to start.'**
  String get noEnrolmentsBody;

  /// No description provided for @exploreCourses.
  ///
  /// In en, this message translates to:
  /// **'Explore courses'**
  String get exploreCourses;

  /// No description provided for @myLearningEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get myLearningEmptyTitle;

  /// No description provided for @myLearningEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Courses you enrol in will appear here with your progress.'**
  String get myLearningEmptyBody;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue coming soon'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Published courses from Almuntahha will be listed here.'**
  String get exploreEmptyBody;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Download a course to study it without an internet connection.'**
  String get downloadsEmptyBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Teacher & admin console'**
  String get adminConsole;

  /// No description provided for @courseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseTitle;

  /// No description provided for @lessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section is being built.'**
  String get comingSoon;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sidra'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to continue your studies.'**
  String get signInSubtitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get genericError;

  /// No description provided for @offlineError.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline.'**
  String get offlineError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Learn with structure'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In en, this message translates to:
  /// **'Courses prepared by Almuntahha teachers — from Quran reading for beginners to Islamic theology — organised into clear units and lessons.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'Guided by your teacher'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In en, this message translates to:
  /// **'Your teacher reviews your progress and opens each next lesson when you are ready, so you always know what to study next.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Study anywhere'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In en, this message translates to:
  /// **'Download your lessons and keep learning without an internet connection. Your progress syncs when you are back online.'**
  String get onboard3Body;

  /// No description provided for @signInUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not available yet'**
  String get signInUnavailableTitle;

  /// No description provided for @signInUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This build of Sidra has not been connected to its sign-in service. Please install the latest version or contact Almuntahha.'**
  String get signInUnavailableBody;

  /// No description provided for @signInUnavailableDevHint.
  ///
  /// In en, this message translates to:
  /// **'Developer: add these to .env, then run  dart run tool/gen_config.dart'**
  String get signInUnavailableDevHint;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
