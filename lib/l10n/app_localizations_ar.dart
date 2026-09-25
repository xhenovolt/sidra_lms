// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'سدرة';

  @override
  String get appTagline => 'تعليم إسلامي من المنتهى';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMyLearning => 'تعلّمي';

  @override
  String get navExplore => 'استكشاف';

  @override
  String get navDownloads => 'التنزيلات';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String greetingMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String greetingEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String get learnerFallbackName => 'طالب العلم';

  @override
  String get continueLearning => 'متابعة التعلّم';

  @override
  String get enrolledCourses => 'دوراتك';

  @override
  String get noEnrolmentsTitle => 'ابدأ رحلتك';

  @override
  String get noEnrolmentsBody =>
      'لم تسجّل في أي دورة بعد. استكشف الدورات لتبدأ.';

  @override
  String get exploreCourses => 'استكشف الدورات';

  @override
  String get myLearningEmptyTitle => 'لا شيء هنا بعد';

  @override
  String get myLearningEmptyBody =>
      'ستظهر هنا الدورات التي سجّلت فيها مع تقدّمك.';

  @override
  String get exploreTitle => 'استكشاف';

  @override
  String get exploreEmptyTitle => 'الدورات قريبًا';

  @override
  String get exploreEmptyBody => 'ستُعرض هنا الدورات المنشورة من المنتهى.';

  @override
  String get downloadsTitle => 'التنزيلات';

  @override
  String get downloadsEmptyTitle => 'لا توجد تنزيلات';

  @override
  String get downloadsEmptyBody => 'نزّل دورة لتدرسها دون اتصال بالإنترنت.';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get adminConsole => 'لوحة المعلّم والإدارة';

  @override
  String get courseTitle => 'الدورة';

  @override
  String get lessonTitle => 'الدرس';

  @override
  String get comingSoon => 'هذا القسم قيد الإنشاء.';

  @override
  String get signInTitle => 'مرحبًا بك في سدرة';

  @override
  String get signInSubtitle => 'سجّل الدخول أو أنشئ حسابًا لمتابعة دراستك.';

  @override
  String get retry => 'حاول مجددًا';

  @override
  String get genericError => 'حدث خطأ ما.';

  @override
  String get offlineError => 'يبدو أنك غير متصل.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get skip => 'تخطٍّ';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get onboard1Title => 'تعلّم بمنهجية';

  @override
  String get onboard1Body =>
      'دورات أعدّها معلّمو المنتهى — من تعليم قراءة القرآن للمبتدئين إلى العقيدة الإسلامية — مرتّبة في وحدات ودروس واضحة.';

  @override
  String get onboard2Title => 'بإشراف معلّمك';

  @override
  String get onboard2Body =>
      'يراجع معلّمك تقدّمك ويفتح لك الدرس التالي عندما تكون مستعدًا، فتعرف دائمًا ما تدرسه بعد ذلك.';

  @override
  String get onboard3Title => 'ادرس في أي مكان';

  @override
  String get onboard3Body =>
      'نزّل دروسك وتابع التعلّم دون اتصال بالإنترنت. يُزامَن تقدّمك عند عودة الاتصال.';

  @override
  String get signInUnavailableTitle => 'تسجيل الدخول غير متاح بعد';

  @override
  String get signInUnavailableBody =>
      'لم يُربط هذا الإصدار من سدرة بخدمة تسجيل الدخول. يرجى تثبيت أحدث إصدار أو التواصل مع المنتهى.';

  @override
  String get signInUnavailableDevHint =>
      'للمطوّر: أضف هذه القيم إلى ‎.env ثم شغّل  dart run tool/gen_config.dart';

  @override
  String get accessFree => 'مجاني';

  @override
  String get accessPaid => 'مدفوع';

  @override
  String get accessRestricted => 'بدعوة';

  @override
  String get difficultyBeginner => 'مبتدئ';

  @override
  String get difficultyIntermediate => 'متوسط';

  @override
  String get difficultyAdvanced => 'متقدم';

  @override
  String lessonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count درس',
      many: '$count درسًا',
      few: '$count دروس',
      two: 'درسان',
      one: 'درس واحد',
      zero: 'لا دروس بعد',
    );
    return '$_temp0';
  }

  @override
  String hoursShort(String hours) {
    return '$hours س';
  }

  @override
  String percentComplete(int percent) {
    return 'أُنجز $percent٪';
  }

  @override
  String get startCourse => 'ابدأ هذه الدورة';

  @override
  String get continueAction => 'متابعة';

  @override
  String get enrolling => 'جارٍ التسجيل…';

  @override
  String get accessRequiredTitle => 'التسجيل عبر المنتهى';

  @override
  String get accessRequiredBody =>
      'يفتح فريق المنتهى هذه الدورة للطلاب. تواصل مع معلّمك أو مع المنتهى للانضمام.';

  @override
  String get courseOutline => 'محتوى الدورة';

  @override
  String get learningObjectives => 'ماذا ستتعلّم';

  @override
  String get prerequisitesTitle => 'قبل أن تبدأ';

  @override
  String get booksTitle => 'الكتب';

  @override
  String get lockedLessonTitle => 'بانتظار معلّمك';

  @override
  String get lockedLessonBody =>
      'يفتح معلّمك هذا الدرس بعد مراجعة تقدّمك في الدرس السابق.';

  @override
  String get notEnrolledLessonBody => 'سجّل في هذه الدورة لفتح دروسها.';

  @override
  String get markComplete => 'أنهيتُ هذا الدرس';

  @override
  String get completedLabel => 'مكتمل';

  @override
  String get previousLesson => 'السابق';

  @override
  String get nextLesson => 'التالي';

  @override
  String get awaitingTeacherTitle => 'أحسنت!';

  @override
  String get awaitingTeacherBody =>
      'أنهيتَ كل ما هو متاح لك. سيراجع معلّمك عملك ويفتح لك الدرس التالي.';

  @override
  String get savedOnDevice => 'محفوظ على هذا الجهاز · سيُزامَن عند الاتصال';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرات بانتظار المزامنة',
      one: 'تغيير واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم تُقبل $count تغييرات',
      one: 'لم يُقبل تغيير واحد',
    );
    return '$_temp0';
  }

  @override
  String get offlineShowingSaved => 'غير متصل · يُعرض المحتوى المحفوظ';

  @override
  String get courseUnavailable => 'هذه الدورة غير متاحة.';

  @override
  String get lessonEmpty => 'لا يحتوي هذا الدرس على محتوى بعد.';

  @override
  String get continueWhereLeft => 'تابع من حيث توقفت';

  @override
  String get nextUp => 'التالي';

  @override
  String get teacherConsole => 'لوحة المعلّم';

  @override
  String get roleLearner => 'طالب';

  @override
  String get roleTeacher => 'معلّم';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get downloadCourse => 'تنزيل للاستخدام دون اتصال';

  @override
  String get downloadedLabel => 'متاح دون اتصال';

  @override
  String get removeDownload => 'حذف التنزيل';

  @override
  String downloadingProgress(int percent) {
    return 'جارٍ التنزيل… $percent٪';
  }

  @override
  String get downloadFailed =>
      'توقف التنزيل. تحقّق من الاتصال ومساحة التخزين ثم حاول مجددًا.';

  @override
  String get storageFull => 'لا توجد مساحة تخزين كافية على جهازك.';

  @override
  String sizeMb(String mb) {
    return '$mb م.ب';
  }

  @override
  String get quizTitle => 'اختبار';

  @override
  String get submitAnswers => 'إرسال الإجابات';

  @override
  String get quizPassed => 'ناجح';

  @override
  String get quizNotPassed => 'لم تنجح بعد';

  @override
  String quizScore(String score, String max) {
    return 'الدرجة: $score / $max';
  }

  @override
  String get quizAwaitingTeacher => 'أُرسلت. سيصحّح معلّمك الإجابات المكتوبة.';

  @override
  String get quizOfflineNote =>
      'صُحّح على هذا الجهاز، وسيُعتمد عند عودة الاتصال.';

  @override
  String get quizNeedsConnection => 'يحتاج هذا الاختبار إلى اتصال بالإنترنت.';

  @override
  String get yourAnswer => 'إجابتك';

  @override
  String get recitationInClass => 'اتلُ هذا على معلّمك في الحلقة.';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get done => 'تم';

  @override
  String get enrolFailed => 'تعذّر التسجيل. حاول مجددًا.';

  @override
  String get teacherFeedback => 'ملاحظات المعلّم';
}
