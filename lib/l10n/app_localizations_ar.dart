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
}
