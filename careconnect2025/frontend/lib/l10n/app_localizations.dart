import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ne'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh')
  ];

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @yourShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Your shortcuts'**
  String get yourShortcuts;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @invoiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Invoice Assistant'**
  String get invoiceAssistant;

  /// No description provided for @evv.
  ///
  /// In en, this message translates to:
  /// **'EVV'**
  String get evv;

  /// No description provided for @calendarAssistant.
  ///
  /// In en, this message translates to:
  /// **'Calendar Assistant'**
  String get calendarAssistant;

  /// No description provided for @medicationManagement.
  ///
  /// In en, this message translates to:
  /// **'Medication Management'**
  String get medicationManagement;

  /// No description provided for @socialFeed.
  ///
  /// In en, this message translates to:
  /// **'Social Feed'**
  String get socialFeed;

  /// No description provided for @gamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get gamification;

  /// No description provided for @wearables.
  ///
  /// In en, this message translates to:
  /// **'Wearables'**
  String get wearables;

  /// No description provided for @fileManagement.
  ///
  /// In en, this message translates to:
  /// **'File Management'**
  String get fileManagement;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @fallDetection.
  ///
  /// In en, this message translates to:
  /// **'Fall Detection'**
  String get fallDetection;

  /// No description provided for @informedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Informed Delivery'**
  String get informedDelivery;

  /// No description provided for @smartDevices.
  ///
  /// In en, this message translates to:
  /// **'Smart Devices'**
  String get smartDevices;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get pleaseLogIn;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to access the menu'**
  String get loginRequiredMessage;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @customizeShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Customize Shortcuts'**
  String get customizeShortcuts;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fallbackUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get fallbackUser;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @shortcut_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get shortcut_dashboard;

  /// No description provided for @shortcut_invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get shortcut_invoices;

  /// No description provided for @shortcut_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get shortcut_calendar;

  /// No description provided for @shortcut_feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get shortcut_feed;

  /// No description provided for @shortcut_meds.
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get shortcut_meds;

  /// No description provided for @shortcut_evv.
  ///
  /// In en, this message translates to:
  /// **'EVV'**
  String get shortcut_evv;

  /// No description provided for @shortcut_wearables.
  ///
  /// In en, this message translates to:
  /// **'Wearables'**
  String get shortcut_wearables;

  /// No description provided for @shortcut_files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get shortcut_files;

  /// No description provided for @shortcut_gamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get shortcut_gamification;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get navSymptoms;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navPatientList.
  ///
  /// In en, this message translates to:
  /// **'Patient List'**
  String get navPatientList;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @notetakerAssistant.
  ///
  /// In en, this message translates to:
  /// **'Notetaker Assistant'**
  String get notetakerAssistant;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsLoadingNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading notification settings...'**
  String get settingsLoadingNotificationSettings;

  /// No description provided for @settingsUnableToLoadNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notification settings'**
  String get settingsUnableToLoadNotificationSettings;

  /// No description provided for @settingsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get settingsRefresh;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsToggleThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle between light and dark theme'**
  String get settingsToggleThemeDesc;

  /// No description provided for @settingsNotifEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get settingsNotifEmergency;

  /// No description provided for @settingsNotifEmergencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Critical health alerts and emergencies'**
  String get settingsNotifEmergencyDesc;

  /// No description provided for @settingsNotifVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call Notifications'**
  String get settingsNotifVideoCall;

  /// No description provided for @settingsNotifVideoCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Incoming video call alerts'**
  String get settingsNotifVideoCallDesc;

  /// No description provided for @settingsNotifAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio Call Notifications'**
  String get settingsNotifAudioCall;

  /// No description provided for @settingsNotifAudioCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Incoming audio call alerts'**
  String get settingsNotifAudioCallDesc;

  /// No description provided for @settingsNotifSignificantVitals.
  ///
  /// In en, this message translates to:
  /// **'Significant Vitals'**
  String get settingsNotifSignificantVitals;

  /// No description provided for @settingsNotifSignificantVitalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Important changes in vital signs'**
  String get settingsNotifSignificantVitalsDesc;

  /// No description provided for @settingsNotifSMS.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get settingsNotifSMS;

  /// No description provided for @settingsNotifSMSDesc.
  ///
  /// In en, this message translates to:
  /// **'Text message alerts to your phone'**
  String get settingsNotifSMSDesc;

  /// No description provided for @settingsNotifGamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification'**
  String get settingsNotifGamification;

  /// No description provided for @settingsNotifGamificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Achievement and progress notifications'**
  String get settingsNotifGamificationDesc;

  /// No description provided for @settingsSnackUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification settings updated'**
  String get settingsSnackUpdated;

  /// No description provided for @settingsSnackUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings'**
  String get settingsSnackUpdateFailed;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// No description provided for @settingsAIAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get settingsAIAssistant;

  /// No description provided for @settingsAIConfiguration.
  ///
  /// In en, this message translates to:
  /// **'AI Configuration'**
  String get settingsAIConfiguration;

  /// No description provided for @settingsAIConfigurationDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize your AI assistant settings'**
  String get settingsAIConfigurationDesc;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settingsManageSubscription;

  /// No description provided for @settingsManageSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'View or update your subscription plan'**
  String get settingsManageSubscriptionDesc;

  /// No description provided for @settingsNotetakerAssistant.
  ///
  /// In en, this message translates to:
  /// **'Notetaker Assistant'**
  String get settingsNotetakerAssistant;

  /// No description provided for @settingsNotetakerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Notetaker Configuration'**
  String get settingsNotetakerConfiguration;

  /// No description provided for @settingsNotetakerConfigurationDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize your Notetaker assistant settings'**
  String get settingsNotetakerConfigurationDesc;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove temporary files and cache data'**
  String get settingsClearCacheShortDesc;

  /// No description provided for @settingsClearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'This will clear all temporary files and cache data. The app may take longer to load content initially after clearing cache.'**
  String get settingsClearCacheDesc;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsSignOutDesc;

  /// No description provided for @settingsSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirmMessage;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountShortDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get settingsDeleteAccountShortDesc;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsDeleteAccountRequested.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requested. Please contact support.'**
  String get settingsDeleteAccountRequested;

  /// No description provided for @settingsDeleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountAction;

  /// No description provided for @welcomeInitializingHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Initializing your healthcare experience...'**
  String get welcomeInitializingHealthcare;

  /// No description provided for @welcomeReadyToConnect.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect your care!'**
  String get welcomeReadyToConnect;

  /// No description provided for @welcomeBackendNotHealthyWarning.
  ///
  /// In en, this message translates to:
  /// **'Backend service is not healthy. The application has limited capabilities.'**
  String get welcomeBackendNotHealthyWarning;

  /// No description provided for @welcomeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeContinue;

  /// No description provided for @welcomeComplianceBadgeHipaa.
  ///
  /// In en, this message translates to:
  /// **'🔒 HIPAA Compliant'**
  String get welcomeComplianceBadgeHipaa;

  /// No description provided for @welcomeComplianceBadgeWcag.
  ///
  /// In en, this message translates to:
  /// **'♿ WCAG AA'**
  String get welcomeComplianceBadgeWcag;

  /// No description provided for @welcomeComplianceBadgeSecure.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Secure'**
  String get welcomeComplianceBadgeSecure;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting Care, Empowering Health'**
  String get welcome_subtitle;

  /// No description provided for @welcome_description.
  ///
  /// In en, this message translates to:
  /// **'Your healthcare companion for'**
  String get welcome_description;

  /// No description provided for @welcome_tagline.
  ///
  /// In en, this message translates to:
  /// **'Better Care • Better Outcomes • Better Life'**
  String get welcome_tagline;

  /// No description provided for @login_tagline.
  ///
  /// In en, this message translates to:
  /// **'Connect with care, track with confidence'**
  String get login_tagline;

  /// No description provided for @login_signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get login_signInTitle;

  /// No description provided for @login_signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access CareConnect'**
  String get login_signInSubtitle;

  /// No description provided for @login_usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get login_usernameLabel;

  /// No description provided for @login_usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get login_usernameHint;

  /// No description provided for @login_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_passwordLabel;

  /// No description provided for @login_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get login_passwordHint;

  /// No description provided for @login_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_forgotPassword;

  /// No description provided for @login_signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login_signInCta;

  /// No description provided for @login_noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get login_noAccountPrompt;

  /// No description provided for @login_createAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get login_createAccountCta;

  /// No description provided for @login_badgeSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get login_badgeSecure;

  /// No description provided for @login_badgeHipaa.
  ///
  /// In en, this message translates to:
  /// **'HIPAA Compliant'**
  String get login_badgeHipaa;

  /// No description provided for @login_badgeAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get login_badgeAccessible;

  /// No description provided for @login_e2eEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get login_e2eEncrypted;

  /// No description provided for @login_wcagAACompliant.
  ///
  /// In en, this message translates to:
  /// **'WCAG AA compliant'**
  String get login_wcagAACompliant;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'ar', 'bn', 'en', 'es', 'fa', 'fr', 'hi', 'ja', 'ne', 'pt', 'ru', 'ur', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'ar': return AppLocalizationsAr();
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fa': return AppLocalizationsFa();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'ja': return AppLocalizationsJa();
    case 'ne': return AppLocalizationsNe();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'ur': return AppLocalizationsUr();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
