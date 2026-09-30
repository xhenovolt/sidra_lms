import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../courses_tab.dart' show notificationKindLabel;

/// Every setting an administrator can change, defined once: where it
/// appears, what it is, its limits and the words that find it. The database
/// checks every value again (set_org_setting) and records who changed it.
enum SettingType { text, multiline, number, toggle, choice }

enum SettingsSection {
  general(Icons.apartment_outlined),
  access(Icons.lock_outline),
  learners(Icons.schedule),
  teaching(Icons.co_present_outlined),
  notifications(Icons.notifications_outlined),
  security(Icons.shield_outlined),
  payments(Icons.payments_outlined),
  marzpay(Icons.phone_android_outlined),
  storage(Icons.cloud_outlined),
  database(Icons.storage_outlined),
  sync(Icons.sync),
  audit(Icons.history),
  application(Icons.system_update_outlined),
  advanced(Icons.build_outlined);

  const SettingsSection(this.icon);
  final IconData icon;

  String title(AppLocalizations l) => switch (this) {
    general => l.ccGeneral,
    access => l.ccAccess,
    learners => l.policyTitle,
    teaching => l.ccTeaching,
    notifications => l.settingsNotifications,
    security => l.ccSecurity,
    payments => l.settingsPayments,
    marzpay => l.marzTitle,
    storage => l.ccStorage,
    database => l.ccDatabase,
    sync => l.ccSync,
    audit => l.ccAudit,
    application => l.ccApplication,
    advanced => l.ccAdvanced,
  };

  String hint(AppLocalizations l) => switch (this) {
    general => l.ccGeneralHint,
    access => l.ccAccessHint,
    learners => l.policyHint,
    teaching => l.settingsTeachingDefaultsHint,
    notifications => l.settingsNotificationsHint,
    security => l.ccSecurityHint,
    payments => l.ccPaymentsHint,
    marzpay => l.ccMarzpayHint,
    storage => l.ccStorageHint,
    database => l.ccDatabaseHint,
    sync => l.ccSyncHint,
    audit => l.ccAuditHint,
    application => l.settingsAppUpdatesHint,
    advanced => l.ccAdvancedHint,
  };
}

class SettingDef {
  const SettingDef(
    this.key,
    this.section,
    this.type,
    this.label, {
    this.help,
    this.min,
    this.max,
    this.defaultOn = true,
    this.options = const {},
    this.keywords = '',
  });

  final String key;
  final SettingsSection section;
  final SettingType type;
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations)? help;
  final int? min;
  final int? max;

  /// For toggles: the value when never set.
  final bool defaultOn;

  /// For choices: stored value → label.
  final Map<String, String Function(AppLocalizations)> options;

  /// Extra English search words (the label and help are searched too).
  final String keywords;

  bool matches(AppLocalizations l, String q) {
    final text = [
      label(l),
      help?.call(l) ?? '',
      keywords,
      section.title(l),
      key.replaceAll('_', ' '),
    ].join(' ').toLowerCase();
    return q.toLowerCase().split(RegExp(r'\s+')).every(text.contains);
  }
}

const _notifyKinds = [
  'portion_assigned',
  'submission',
  'resubmission',
  'reviewed',
  'correction',
  'lesson_work',
];

/// Every administrator setting.
final settingsRegistry = <SettingDef>[
  // -------------------------------------------------------------- general
  SettingDef(
    'org_name',
    SettingsSection.general,
    SettingType.text,
    (l) => l.settingsOrgName,
    keywords: 'organisation organization name brand',
  ),
  SettingDef(
    'org_name_ar',
    SettingsSection.general,
    SettingType.text,
    (l) => l.settingsOrgNameAr,
    keywords: 'arabic name brand',
  ),
  SettingDef(
    'org_time_zone',
    SettingsSection.general,
    SettingType.text,
    (l) => l.ccTimeZone,
    help: (l) => l.ccTimeZoneHint,
    keywords: 'timezone time zone clock deadlines',
  ),
  SettingDef(
    'support_phone',
    SettingsSection.general,
    SettingType.text,
    (l) => l.settingsSupportPhone,
    keywords: 'contact phone help',
  ),
  SettingDef(
    'support_email',
    SettingsSection.general,
    SettingType.text,
    (l) => l.settingsSupportEmail,
    keywords: 'contact email help',
  ),
  SettingDef(
    'messaging_enabled',
    SettingsSection.general,
    SettingType.toggle,
    (l) => l.ccMessagingOn,
    keywords: 'chat messages whatsapp',
  ),
  SettingDef(
    'messaging_learners',
    SettingsSection.general,
    SettingType.toggle,
    (l) => l.ccMessagingLearners,
    defaultOn: false,
    keywords: 'chat messages learners students',
  ),
  // --------------------------------------------------------------- access
  SettingDef(
    'allow_self_signup',
    SettingsSection.access,
    SettingType.toggle,
    (l) => l.settingsAllowSignup,
    help: (l) => l.settingsAllowSignupHint,
    keywords: 'registration sign up register accounts',
  ),
  SettingDef(
    'min_password_length',
    SettingsSection.access,
    SettingType.number,
    (l) => l.settingsMinPassword,
    min: 6,
    max: 64,
    keywords: 'password policy length security',
  ),
  SettingDef(
    'lockout_attempts',
    SettingsSection.access,
    SettingType.number,
    (l) => l.settingsLockoutAttempts,
    min: 3,
    max: 20,
    keywords: 'password failed login lock brute force',
  ),
  SettingDef(
    'lockout_minutes',
    SettingsSection.access,
    SettingType.number,
    (l) => l.settingsLockoutMinutes,
    min: 1,
    max: 1440,
    keywords: 'password failed login lock',
  ),
  SettingDef(
    'signin_failures_per_minute',
    SettingsSection.access,
    SettingType.number,
    (l) => l.ccSigninBrake,
    help: (l) => l.ccSigninBrakeHint,
    min: 5,
    max: 1000,
    keywords: 'password failed login attack throttle',
  ),
  SettingDef(
    'presence_online_minutes',
    SettingsSection.access,
    SettingType.number,
    (l) => l.ccPresenceMinutes,
    min: 1,
    max: 60,
    keywords: 'online active session device',
  ),
  SettingDef(
    'auth_events_keep_days',
    SettingsSection.access,
    SettingType.number,
    (l) => l.ccAuthKeepDays,
    min: 7,
    max: 3650,
    keywords: 'sign-in history retention privacy',
  ),
  // ------------------------------------------------------------- learners
  SettingDef(
    'policy_enabled',
    SettingsSection.learners,
    SettingType.toggle,
    (l) => l.policyEnabled,
    keywords: 'reminders late overdue',
  ),
  SettingDef(
    'policy_warn_after_hours',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyWarnHours,
    help: (l) => l.policyWarnHoursHint,
    min: 1,
    max: 2000,
    keywords: 'deadline overdue warning reminder',
  ),
  SettingDef(
    'policy_overdue_after_hours',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyOverdueHours,
    min: 1,
    max: 2000,
    keywords: 'deadline overdue teacher',
  ),
  SettingDef(
    'policy_escalate_after_days',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyEscalateDays,
    min: 1,
    max: 365,
    keywords: 'escalation overdue admin',
  ),
  SettingDef(
    'policy_grace_hours',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyGraceHours,
    min: 0,
    max: 720,
    keywords: 'grace deadline',
  ),
  SettingDef(
    'policy_reminder_every_hours',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyReminderHours,
    min: 1,
    max: 2000,
    keywords: 'reminder frequency',
  ),
  SettingDef(
    'policy_count_weekends',
    SettingsSection.learners,
    SettingType.toggle,
    (l) => l.policyCountWeekends,
    help: (l) => l.policyCountWeekendsHint,
    keywords: 'weekend saturday sunday deadline',
  ),
  SettingDef(
    'policy_inactive_after_days',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policyInactiveDays,
    help: (l) => l.policyInactiveDaysHint,
    min: 1,
    max: 365,
    keywords: 'inactivity inactive',
  ),
  SettingDef(
    'policy_auto_suspend',
    SettingsSection.learners,
    SettingType.toggle,
    (l) => l.policyAutoSuspend,
    help: (l) => l.policyAutoSuspendHint,
    defaultOn: false,
    keywords: 'suspension suspend',
  ),
  SettingDef(
    'policy_suspend_after_days',
    SettingsSection.learners,
    SettingType.number,
    (l) => l.policySuspendDays,
    min: 1,
    max: 365,
    keywords: 'suspension suspend',
  ),
  // ------------------------------------------------------------- teaching
  SettingDef(
    'attention_stale_days',
    SettingsSection.teaching,
    SettingType.number,
    (l) => l.settingsStaleDays,
    min: 1,
    max: 60,
    keywords: 'review waiting teacher attention',
  ),
  SettingDef(
    'falling_behind_portions',
    SettingsSection.teaching,
    SettingType.number,
    (l) => l.settingsFallingBehind,
    min: 1,
    max: 60,
    keywords: 'behind portions attention',
  ),
  SettingDef(
    'default_progression',
    SettingsSection.teaching,
    SettingType.choice,
    (l) => l.settingsDefaultRule,
    options: {
      'after_approval': (l) => l.ruleApproval,
      'after_submission': (l) => l.ruleSubmission,
      'teacher_gated': (l) => l.adminProgressionTeacher,
      'sequential': (l) => l.adminProgressionSequential,
      'open': (l) => l.adminProgressionOpen,
    },
    keywords: 'lesson rule unlock progression course default',
  ),
  SettingDef(
    'default_pass_mark',
    SettingsSection.teaching,
    SettingType.number,
    (l) => l.ccDefaultPassMark,
    min: 0,
    max: 100,
    keywords: 'pass mark score course default',
  ),
  // -------------------------------------------------------- notifications
  for (final k in _notifyKinds)
    SettingDef(
      'notify_$k',
      SettingsSection.notifications,
      SettingType.toggle,
      (l) => notificationKindLabel(l, k),
      keywords: 'notification alert phone',
    ),
  // ------------------------------------------------------------- payments
  SettingDef(
    'currency',
    SettingsSection.payments,
    SettingType.text,
    (l) => l.settingsCurrency,
    keywords: 'currency ugx money',
  ),
  SettingDef(
    'marzpay_enabled',
    SettingsSection.payments,
    SettingType.toggle,
    (l) => l.settingsMarzPay,
    help: (l) => l.settingsMarzPayHint,
    keywords: 'mobile money marzpay mtn airtel payment',
  ),
  SettingDef(
    'mobile_money_instructions',
    SettingsSection.payments,
    SettingType.multiline,
    (l) => l.settingsMobileMoney,
    keywords: 'manual payment mobile money instructions',
  ),
  SettingDef(
    'bank_instructions',
    SettingsSection.payments,
    SettingType.multiline,
    (l) => l.settingsBank,
    help: (l) => l.settingsBankHint,
    keywords: 'bank manual payment instructions',
  ),
  SettingDef(
    'payment_unanswered_days',
    SettingsSection.payments,
    SettingType.number,
    (l) => l.policyPaymentDays,
    help: (l) => l.policyPaymentDaysHint,
    min: 1,
    max: 365,
    keywords: 'reconciliation marzpay stuck',
  ),
  // -------------------------------------------------------------- marzpay
  SettingDef(
    'marzpay_tests_enabled',
    SettingsSection.marzpay,
    SettingType.toggle,
    (l) => l.ccMarzTestsOn,
    help: (l) => l.ccMarzTestsOnHint,
    keywords: 'test emergency stop payment',
  ),
  SettingDef(
    'billing_term_days',
    SettingsSection.payments,
    SettingType.number,
    (l) => l.billTermDaysSetting,
    help: (l) => l.billTermDaysSettingHint,
    min: 7,
    max: 366,
    keywords: 'term fee termly billing school',
  ),
  SettingDef(
    'billing_grace_days',
    SettingsSection.payments,
    SettingType.number,
    (l) => l.billGraceSetting,
    help: (l) => l.billGraceSettingHint,
    min: 0,
    max: 90,
    keywords: 'fee overdue grace monthly weekly pause',
  ),
  SettingDef(
    'marzpay_test_max_amount',
    SettingsSection.marzpay,
    SettingType.number,
    (l) => l.ccMarzTestMax,
    min: 500,
    max: 100000,
    keywords: 'test limit amount payment',
  ),
  SettingDef(
    'marzpay_disbursement_tests_enabled',
    SettingsSection.marzpay,
    SettingType.toggle,
    (l) => l.ccMarzDisbursementOn,
    help: (l) => l.ccMarzDisbursementOnHint,
    defaultOn: false,
    keywords: 'disbursement send money payout test',
  ),
  // -------------------------------------------------------------- storage
  SettingDef(
    'upload_max_mb',
    SettingsSection.storage,
    SettingType.number,
    (l) => l.ccUploadMax,
    help: (l) => l.ccUploadMaxHint,
    min: 1,
    max: 500,
    keywords: 'upload file size limit storage cloudinary',
  ),
  // ---------------------------------------------------------- application
  SettingDef(
    'latest_app_version',
    SettingsSection.application,
    SettingType.text,
    (l) => l.settingsLatestVersion,
    keywords: 'version update release',
  ),
  SettingDef(
    'latest_app_build',
    SettingsSection.application,
    SettingType.number,
    (l) => l.settingsLatestBuild,
    min: 1,
    max: 999999,
    keywords: 'version update build',
  ),
  SettingDef(
    'app_download_url',
    SettingsSection.application,
    SettingType.text,
    (l) => l.settingsDownloadUrl,
    keywords: 'download link apk update',
  ),
  SettingDef(
    'min_supported_build',
    SettingsSection.application,
    SettingType.number,
    (l) => l.settingsMinBuild,
    help: (l) => l.settingsMinBuildHint,
    min: 1,
    max: 999999,
    keywords: 'minimum version force update',
  ),
];

/// Tools (screens) the search can also find, per section.
class SettingsTool {
  const SettingsTool(
    this.id,
    this.section,
    this.icon,
    this.label,
    this.keywords,
  );
  final String id;
  final SettingsSection section;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final String keywords;
}

final settingsTools = <SettingsTool>[
  SettingsTool(
    'presence',
    SettingsSection.security,
    Icons.sensors,
    (l) => l.presenceTitle,
    'online devices sessions active',
  ),
  SettingsTool(
    'security_events',
    SettingsSection.security,
    Icons.gpp_maybe_outlined,
    (l) => l.ccSecurityEvents,
    'failed login password attack locked suspicious',
  ),
  SettingsTool(
    'my_devices',
    SettingsSection.security,
    Icons.devices_outlined,
    (l) => l.devicesMine,
    'devices sessions sign out',
  ),
  SettingsTool(
    'holidays',
    SettingsSection.learners,
    Icons.event_busy_outlined,
    (l) => l.holidaysTitle,
    'holiday calendar deadline',
  ),
  SettingsTool(
    'late_work',
    SettingsSection.learners,
    Icons.schedule,
    (l) => l.lateWorkTitle,
    'overdue suspended late reinstate',
  ),
  SettingsTool(
    'issues',
    SettingsSection.teaching,
    Icons.report_problem_outlined,
    (l) => l.issuesTitle,
    'problem report issue extension',
  ),
  SettingsTool(
    'languages',
    SettingsSection.teaching,
    Icons.translate,
    (l) => l.settingsLanguagesTracks,
    'language track',
  ),
  SettingsTool(
    'test_notification',
    SettingsSection.notifications,
    Icons.notification_add_outlined,
    (l) => l.ccSendTestNotification,
    'test notification phone',
  ),
  SettingsTool(
    'payment_trace',
    SettingsSection.payments,
    Icons.manage_search,
    (l) => l.ccPaymentTrace,
    'paid unpaid trace find payment dispute',
  ),
  SettingsTool(
    'marzpay_center',
    SettingsSection.marzpay,
    Icons.science_outlined,
    (l) => l.ccMarzCenter,
    'marzpay test collection disbursement balance bank callback reconciliation',
  ),
  SettingsTool(
    'marzpay_selfcheck',
    SettingsSection.marzpay,
    Icons.fact_check_outlined,
    (l) => l.ccMarzSelfChecks,
    'duplicate idempotency timeout self check integration',
  ),
  SettingsTool(
    'diagnostics',
    SettingsSection.advanced,
    Icons.health_and_safety_outlined,
    (l) => l.ccDiagnostics,
    'diagnostics test health upload storage database',
  ),
  SettingsTool(
    'settings_history',
    SettingsSection.audit,
    Icons.history,
    (l) => l.ccSettingsHistory,
    'who changed audit history setting',
  ),
  SettingsTool(
    'export',
    SettingsSection.audit,
    Icons.file_download_outlined,
    (l) => l.settingsExport,
    'export csv data backup',
  ),
];
