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
  String appTagline(String org) {
    return 'تعليم إسلامي من $org';
  }

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
  String exploreEmptyBody(String org) {
    return 'ستُعرض هنا الدورات المنشورة من $org.';
  }

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
  String get signInSubtitle =>
      'سجّل الدخول برقم هاتفك أو بريدك أو اسم المستخدم لمتابعة دراستك.';

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
  String onboard1Body(String org) {
    return 'دورات أعدّها معلّمو $org — من تعليم قراءة القرآن للمبتدئين إلى العقيدة الإسلامية — مرتّبة في وحدات ودروس واضحة.';
  }

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
  String signInUnavailableBody(String org) {
    return 'لم يُربط هذا الإصدار من سدرة بخدمة تسجيل الدخول. يرجى تثبيت أحدث إصدار أو التواصل مع $org.';
  }

  @override
  String get signInUnavailableDevHint =>
      'للمطوّر: شغّل  dart run tool/db.dart app-role  ثم  dart run tool/gen_config.dart';

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
  String accessRequiredTitle(String org) {
    return 'التسجيل عبر $org';
  }

  @override
  String accessRequiredBody(String org) {
    return 'يفتح فريق $org هذه الدورة للطلاب. تواصل مع معلّمك أو مع $org للانضمام.';
  }

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

  @override
  String get adminAccess => 'من يمكنه الانضمام';

  @override
  String get adminAdd => 'إضافة';

  @override
  String get adminAddContent => 'إضافة محتوى';

  @override
  String get adminAddLesson => 'إضافة درس';

  @override
  String get adminAddLevel => 'إضافة مستوى';

  @override
  String get adminAddOption => 'إضافة خيار';

  @override
  String get adminAddQuestion => 'إضافة سؤال';

  @override
  String get adminAddSection => 'إضافة قسم';

  @override
  String get adminAddSubsection => 'إضافة جزء بداخله';

  @override
  String get adminAddUnit => 'إضافة وحدة';

  @override
  String get adminAllLearners => 'جميع الطلاب';

  @override
  String get adminArabicText => 'النص العربي';

  @override
  String get adminAssignTeacher => 'تعيين معلّمًا لدورة';

  @override
  String get adminAuthor => 'المؤلف';

  @override
  String get adminAwaitingReview => 'بانتظار مراجعتك';

  @override
  String get adminBlockAttachment => 'ملف';

  @override
  String get adminBlockAudio => 'صوت';

  @override
  String get adminBlockCallout => 'مربع تنبيه';

  @override
  String get adminBlockDivider => 'فاصل';

  @override
  String get adminBlockHeading => 'عنوان';

  @override
  String get adminBlockImage => 'صورة';

  @override
  String get adminBlockQuiz => 'اختبار';

  @override
  String get adminBlockQuran => 'نص قرآني';

  @override
  String get adminBlockReference => 'مرجع';

  @override
  String get adminBlockText => 'نص';

  @override
  String get adminBlockTranslation => 'ترجمة';

  @override
  String get adminBlockTransliteration => 'نقحرة';

  @override
  String get adminBlockVideo => 'فيديو';

  @override
  String get adminBook => 'الكتاب';

  @override
  String get adminCancel => 'إلغاء';

  @override
  String get adminCaption => 'وصف الصورة';

  @override
  String get adminChangeRoleTitle => 'تغيير الدور؟';

  @override
  String get adminChapter => 'الفصل';

  @override
  String get adminChooseFile => 'اختر ملفًا من هذا الجهاز';

  @override
  String get adminCitation => 'التوثيق';

  @override
  String get adminConfirm => 'تأكيد';

  @override
  String get adminContent => 'المحتوى';

  @override
  String get adminCopyright => 'ملاحظات حقوق النشر والاستخدام';

  @override
  String get adminCourseTitle => 'اسم الدورة';

  @override
  String get adminCover => 'صورة الغلاف';

  @override
  String get adminCreate => 'إنشاء';

  @override
  String get adminCurrency => 'العملة';

  @override
  String get adminCurrentLesson => 'الدرس الحالي';

  @override
  String get adminCustomStructure => 'مستويات خاصة بي';

  @override
  String get adminDelete => 'حذف';

  @override
  String get adminDeleteBlockBody => 'سيُحذف هذا المحتوى من الدرس.';

  @override
  String get adminDeleteLessonBody => 'سيُحذف الدرس ومحتواه وتقدّم الطلاب فيه.';

  @override
  String get adminDeleteNodeBody =>
      'سيُحذف هذا الجزء وكل ما بداخله بما فيه الدروس.';

  @override
  String get adminDeleteQuestionBody => 'سيُحذف هذا السؤال من الاختبار.';

  @override
  String get adminDeleteTitle => 'حذف؟';

  @override
  String get adminDeleteUnitBody => 'ستُحذف الوحدة وكل ما بداخلها.';

  @override
  String get adminDescription => 'الوصف';

  @override
  String get adminDifficulty => 'المستوى';

  @override
  String get adminDraft => 'مسودة';

  @override
  String get adminEdit => 'تعديل';

  @override
  String get adminEditCourse => 'تعديل بيانات الدورة';

  @override
  String get adminEditQuestions => 'تعديل الأسئلة';

  @override
  String get adminEdition => 'الطبعة';

  @override
  String get adminEmptyLessonBody =>
      'اضغط «إضافة محتوى» لكتابة نص أو إضافة آيات أو صور أو صوت أو اختبار.';

  @override
  String get adminEmptyLessonTitle => 'هذا الدرس فارغ';

  @override
  String get adminEstimatedHours => 'عدد الساعات التقريبي';

  @override
  String get adminExplanation => 'شرح يظهر بعد الإجابة';

  @override
  String get adminFalse => 'خطأ';

  @override
  String get adminFileUploaded => 'تم رفع الملف';

  @override
  String get adminFromBook => 'من كتاب';

  @override
  String get adminGradedQuiz => 'اختبار مُقيَّم';

  @override
  String get adminGradedQuizHint =>
      'يُحتسب للطالب. يحتاج إلى الإنترنت وتبقى الإجابات مخفية.';

  @override
  String get adminGrantCourse => 'منح الوصول إلى دورة';

  @override
  String get adminHidden => 'مخفية عن الطلاب';

  @override
  String get adminLanguage => 'اللغة';

  @override
  String get adminLevel => 'المستوى';

  @override
  String get adminLevelHint => 'مثل: سورة، صفحة، فصل';

  @override
  String get adminLink => 'رابط';

  @override
  String get adminLinkBook => 'ربط كتاب';

  @override
  String get adminMakeRole => 'اجعله';

  @override
  String get adminMaxAttempts => 'عدد المحاولات';

  @override
  String get adminMinutes => 'الدقائق اللازمة';

  @override
  String get adminMoveDown => 'تحريك للأسفل';

  @override
  String get adminMoveUp => 'تحريك للأعلى';

  @override
  String get adminNeedsConnection => 'يحتاج هذا إلى اتصال بالإنترنت.';

  @override
  String get adminNeedsRevision => 'يحتاج مراجعة';

  @override
  String get adminNewBook => 'كتاب جديد';

  @override
  String get adminNewCourse => 'دورة جديدة';

  @override
  String get adminNoBook => 'ليس من كتاب';

  @override
  String get adminNoBooksBody =>
      'أضف الكتب التي تُدرَّس منها دوراتك ثم اختر طريقة تنظيم كل كتاب.';

  @override
  String get adminNoBooksTitle => 'لا توجد كتب بعد';

  @override
  String get adminNoBooksToLink => 'كل الكتب مرتبطة. أضف كتبًا من تبويب الكتب.';

  @override
  String get adminNoCoursesBody => 'أنشئ أول دورة لبدء بناء المنهج.';

  @override
  String get adminNoCoursesTitle => 'لا توجد دورات بعد';

  @override
  String get adminNoLearnersBody => 'سيظهر هنا الطلاب المسجّلون في دوراتك.';

  @override
  String get adminNoLearnersTitle => 'لا يوجد طلاب بعد';

  @override
  String get adminNoQuestions => 'لا أسئلة بعد. اضغط «إضافة سؤال».';

  @override
  String get adminNoStructure => 'لم يُحدَّد التنظيم';

  @override
  String get adminNoUnit => 'بدون وحدة';

  @override
  String get adminNotAllowed => 'ليس لديك صلاحية لهذا.';

  @override
  String get adminOnePerLine => 'عنصر في كل سطر';

  @override
  String get adminOpenNextLesson => 'افتح الدرس التالي لهذا الطالب';

  @override
  String get adminOption => 'خيار';

  @override
  String get adminOptionsHint => 'ضع علامة على الإجابة الصحيحة:';

  @override
  String get adminOutlineHint =>
      'أضف أقسامًا (مثل سورة أو صفحة أو فصل) ودروسًا بداخلها.';

  @override
  String get adminPageFrom => 'من صفحة';

  @override
  String get adminPageTo => 'إلى صفحة';

  @override
  String get adminPassMark => 'درجة النجاح';

  @override
  String get adminPassed => 'ناجح';

  @override
  String get adminPickCorrect => 'اختر إجابة صحيحة واحدة على الأقل.';

  @override
  String get adminPracticeQuizHint =>
      'للتدريب. يعمل دون اتصال ويرى الطلاب الإجابات الصحيحة.';

  @override
  String get adminPreview => 'معاينة';

  @override
  String get adminPreviewAsLearner => 'عرضها كما يراها الطالب';

  @override
  String get adminPreviewLesson => 'معاينة مجانية';

  @override
  String get adminPreviewLessonHint => 'يستطيع كل طالب مسجّل فتحه دون انتظار';

  @override
  String get adminPrice => 'السعر';

  @override
  String get adminProgression => 'طريقة تقدّم الطلاب';

  @override
  String get adminProgressionOpen => 'كل الدروس مفتوحة';

  @override
  String get adminProgressionSequential => 'يُفتح الدرس التالي بعد الإنهاء';

  @override
  String get adminProgressionTeacher => 'المعلّم يفتح كل درس تالٍ';

  @override
  String get adminPublish => 'نشر';

  @override
  String get adminPublishCourse => 'منشورة';

  @override
  String get adminPublished => 'منشور';

  @override
  String get adminQMultiple => 'اختيار متعدد';

  @override
  String get adminQRecitation => 'تلاوة (تُقيَّم في الحلقة)';

  @override
  String get adminQShort => 'إجابة مكتوبة';

  @override
  String get adminQSingle => 'اختيار واحد';

  @override
  String get adminQTrueFalse => 'صح أو خطأ';

  @override
  String get adminQuestion => 'السؤال';

  @override
  String get adminQuestionType => 'نوع السؤال';

  @override
  String get adminReferenceLabel => 'المرجع الظاهر للطلاب';

  @override
  String get adminReferenceLabelHint => 'مثل: الفاتحة ١–٣، ص ١٢';

  @override
  String get adminRequired => 'مطلوب';

  @override
  String get adminReviewSaved => 'حُفظت المراجعة';

  @override
  String get adminReviewSavedUnlocked => 'حُفظت المراجعة وفُتح الدرس التالي';

  @override
  String get adminSave => 'حفظ';

  @override
  String get adminSaveReview => 'حفظ المراجعة';

  @override
  String get adminSaved => 'تم الحفظ';

  @override
  String get adminScore => 'الدرجة';

  @override
  String get adminSectionType => 'نوع القسم';

  @override
  String get adminSectionTypeHint => 'مثل: فصل، صفحة، موضوع';

  @override
  String get adminSetStructure => 'كيف يُنظَّم هذا الكتاب؟';

  @override
  String get adminSetStructureHint => 'اختر مستويات مثل سورة ← آية أو صفحة';

  @override
  String get adminSource => 'المصدر';

  @override
  String get adminStructureExplain =>
      'اختر طريقة تقسيم الكتاب. توضع الدروس داخل أصغر جزء.';

  @override
  String get adminSubject => 'المادة';

  @override
  String get adminSubjectHint => 'مثل: القرآن، العقيدة، الفقه، العربية';

  @override
  String get adminSubtitle => 'وصف مختصر';

  @override
  String get adminSummary => 'ملخص قصير';

  @override
  String get adminSurah => 'رقم السورة';

  @override
  String get adminTabCourses => 'الدورات';

  @override
  String get adminTabLearners => 'الطلاب';

  @override
  String get adminTabPeople => 'الأشخاص';

  @override
  String get adminText => 'النص';

  @override
  String get adminTextHint => 'استخدم **غامق** و*مائل* وابدأ السطر بـ - للنقاط';

  @override
  String get adminThumbnail => 'صورة الدورة';

  @override
  String get adminTitle => 'العنوان';

  @override
  String get adminToneInfo => 'معلومة';

  @override
  String get adminToneNote => 'ملاحظة';

  @override
  String get adminToneWarning => 'مهم';

  @override
  String get adminTranscript => 'النص المكتوب (اختياري)';

  @override
  String get adminTranslator => 'المترجم';

  @override
  String get adminTrue => 'صح';

  @override
  String get adminUnitOptional => 'الوحدة';

  @override
  String get adminUnits => 'الوحدات';

  @override
  String get adminUnitsHint =>
      'تقسّم الوحدات الدورة إلى مراحل كبرى، وهي اختيارية.';

  @override
  String get adminUnlimited => 'غير محدود';

  @override
  String get adminUnpublish => 'إخفاء عن الطلاب';

  @override
  String get adminVerseFrom => 'من آية';

  @override
  String get adminVerseTo => 'إلى آية';

  @override
  String get adminVisibleToLearners => 'ظاهرة للطلاب';

  @override
  String get adminWholeCourse => 'الدورة كاملة';

  @override
  String adminChangeRoleBody(String name) {
    return 'تغيير دور $name؟ تتغيّر صلاحياته فورًا.';
  }

  @override
  String get authPhone => 'الهاتف';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPhoneLabel => 'رقم الهاتف';

  @override
  String get authPhoneHint => 'مثال: 0772 123 456 أو ‎+256 772 123 456';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authFullName => 'الاسم الكامل';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignUp => 'إنشاء حساب';

  @override
  String get authNoAccount => 'جديد في سدرة؟ أنشئ حسابًا';

  @override
  String get authHaveAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authSignUpTitle => 'أنشئ حسابك';

  @override
  String get authSignUpSubtitle =>
      'استخدم رقم هاتفك أو بريدك الإلكتروني، وستسجّل الدخول به وبكلمة المرور.';

  @override
  String get authForgot => 'نسيت كلمة المرور؟';

  @override
  String authForgotBody(String org) {
    return 'اطلب من معلّمك أو من $org إعادة تعيينها. ستحصل على كلمة مرور مؤقتة وتختار كلمة جديدة عند الدخول.';
  }

  @override
  String get authChangePasswordTitle => 'اختر كلمة مرور جديدة';

  @override
  String get authChangePasswordForced =>
      'أُعيد تعيين كلمة مرورك. اختر كلمة جديدة للمتابعة.';

  @override
  String get authCurrentPassword => 'كلمة المرور الحالية (أو المؤقتة)';

  @override
  String get authNewPassword => 'كلمة المرور الجديدة';

  @override
  String get authSavePassword => 'حفظ كلمة المرور';

  @override
  String get authPasswordChanged => 'تم تغيير كلمة المرور';

  @override
  String get authChangePassword => 'تغيير كلمة المرور';

  @override
  String get authRequired => 'مطلوب';

  @override
  String authPasswordRule(int n) {
    return '$n أحرف على الأقل';
  }

  @override
  String get authPasswordsDiffer => 'كلمتا المرور غير متطابقتين';

  @override
  String get authPhoneInvalid =>
      'أدخل رقم هاتف مثل 0772 123 456، أو مع رمز الدولة (+…)';

  @override
  String get authEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get authErrorInvalidCredentials =>
      'بيانات الدخول وكلمة المرور غير متطابقة.';

  @override
  String get authErrorTaken =>
      'يوجد حساب بهذا الرقم أو البريد. جرّب تسجيل الدخول.';

  @override
  String get authErrorWeak => 'يجب أن تكون كلمة المرور ٨ أحرف على الأقل.';

  @override
  String get authErrorIdentifier =>
      'تحقّق من رقم الهاتف (مع رمز الدولة) أو البريد.';

  @override
  String get authErrorLocked => 'محاولات كثيرة. انتظر ١٥ دقيقة ثم حاول مجددًا.';

  @override
  String authErrorDisabled(String org) {
    return 'هذا الحساب معطّل. تواصل مع $org.';
  }

  @override
  String get authErrorSamePassword => 'اختر كلمة مرور مختلفة عن الحالية.';

  @override
  String get authErrorOffline =>
      'لا يوجد اتصال. تحقّق من الإنترنت وحاول مجددًا.';

  @override
  String get adminResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get adminResetPasswordBody =>
      'أعطِ هذه الكلمة المؤقتة للطالب، وعليه اختيار كلمة جديدة عند الدخول.';

  @override
  String get adminTemporaryPassword => 'كلمة المرور المؤقتة';

  @override
  String get adminPasswordReset =>
      'أُعيد التعيين. شارك الكلمة المؤقتة مع الطالب.';

  @override
  String get roleSuperadmin => 'مدير عام';

  @override
  String get authUsername => 'اسم المستخدم';

  @override
  String get authUsernameInvalid => '٣–٣٠ حرفًا أو رقمًا أو نقطة أو شرطة سفلية';

  @override
  String get adminTabOverview => 'نظرة عامة';

  @override
  String get adminStatLearners => 'الطلاب';

  @override
  String get adminStatTeachers => 'المعلّمون';

  @override
  String get adminStatAdmins => 'المديرون';

  @override
  String get adminStatPublished => 'دورات منشورة';

  @override
  String get adminStatDrafts => 'دورات مسودة';

  @override
  String get adminStatEnrolments => 'تسجيلات نشطة';

  @override
  String get adminStatActive7d => 'طلاب نشطون (٧ أيام)';

  @override
  String get adminStatCompleted7d => 'دروس مكتملة (٧ أيام)';

  @override
  String get adminQuickActions => 'إجراءات سريعة';

  @override
  String get adminAddPerson => 'إضافة شخص';

  @override
  String get adminSearchPeople =>
      'ابحث بالاسم أو الهاتف أو البريد أو اسم المستخدم';

  @override
  String get adminEveryone => 'الجميع';

  @override
  String get adminNoPeople => 'لا يوجد أحد';

  @override
  String get adminDisabled => 'معطّل';

  @override
  String get adminDisabledNote => 'هذا الحساب معطّل ولا يمكنه تسجيل الدخول.';

  @override
  String get adminEditDetails => 'تعديل البيانات';

  @override
  String get adminSuperadminHint => 'يمكنه إنشاء المديرين الآخرين وإدارتهم';

  @override
  String get adminDisableAccount => 'تعطيل الحساب';

  @override
  String get adminEnableAccount => 'تفعيل الحساب';

  @override
  String get adminDisableHint =>
      'يُسجَّل خروجه من كل الأجهزة ولا يمكنه الدخول حتى يُفعَّل مجددًا. لا يُحذف شيء.';

  @override
  String get adminUsernameHint => 'اختياري، مثل ustadh_ali';

  @override
  String get adminOneIdentifier =>
      'أدخل واحدًا على الأقل: الهاتف أو البريد أو اسم المستخدم، وبه يسجّل الدخول.';

  @override
  String get adminRole => 'الدور';

  @override
  String get adminPersonCreated => 'تم إنشاء الحساب';

  @override
  String get adminPersonCreatedBody =>
      'أعطِ هذه الكلمة المؤقتة للشخص، وعليه اختيار كلمة مرور خاصة عند أول دخول.';

  @override
  String get adminCourseTeachers => 'معلّمو هذه الدورة';

  @override
  String get adminAddTeacher => 'إضافة معلّم';

  @override
  String get adminAddLearner => 'إضافة طالب';

  @override
  String get adminNoTeachersYet =>
      'لم يُعيَّن معلّمون بعد. يستطيع المديرون دائمًا مراجعة الطلاب.';

  @override
  String get adminRemove => 'إزالة';

  @override
  String get adminEnrolActive => 'نشط';

  @override
  String get adminEnrolSuspended => 'موقوف';

  @override
  String get adminEnrolWithdrawn => 'منسحب';

  @override
  String get adminEnrolPending => 'قيد الانتظار';

  @override
  String get adminDeleteCourse => 'حذف الدورة';

  @override
  String adminDeleteCourseBody(String title) {
    return 'حذف «$title» نهائيًا؟ لم تُنشر قط وليس فيها متعلمون. لا يمكن التراجع.';
  }

  @override
  String get navMore => 'المزيد';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get moreBrowseCatalogue => 'تصفّح الدورات';

  @override
  String get moreBrowseCatalogueHint =>
      'اطّلع على الدورات المنشورة كما يراها الطلاب';

  @override
  String get drawerAcademic => 'الشؤون الأكاديمية';

  @override
  String get drawerTeaching => 'التعليم';

  @override
  String get drawerReview => 'مراجعة الطلاب';

  @override
  String get drawerPeople => 'الأشخاص';

  @override
  String get drawerRoles => 'الأدوار والصلاحيات';

  @override
  String get drawerOversight => 'الرقابة';

  @override
  String get drawerActivity => 'سجل النشاط';

  @override
  String get drawerAccount => 'حسابي';

  @override
  String get rolesNew => 'دور جديد';

  @override
  String get rolesIntro =>
      'الدور وظيفة في سدرة. لكل شخص دور واحد، وصلاحياته تحدد ما يراه ويفعله. يمكن تعديل الأدوار المدمجة، ويملك المدير العام كل الصلاحيات دائمًا.';

  @override
  String get rolesDeleteBody => 'حذف هذا الدور؟ يجب ألّا يكون مسندًا لأحد.';

  @override
  String get rolesSuperAdminLocked =>
      'يملك المدير العام كل الصلاحيات دائمًا ولا يمكن تغييره.';

  @override
  String get areaEnrolment => 'التسجيل';

  @override
  String get areaFinance => 'المالية';

  @override
  String get areaContent => 'المحتوى';

  @override
  String get areaReports => 'التقارير';

  @override
  String get areaSettings => 'الإعدادات';

  @override
  String get auditEmpty => 'لا يوجد نشاط مسجّل بعد';

  @override
  String get auditSystem => 'النظام';

  @override
  String get auditCreated => 'أنشأ';

  @override
  String get auditRemoved => 'حذف';

  @override
  String get auditChanged => 'عدّل';

  @override
  String get auditEnrolment => 'تسجيل';

  @override
  String get auditTeacherAssignment => 'إسناد معلّم';

  @override
  String get auditAccount => 'حساب';

  @override
  String get auditUnlock => 'فتح درس';

  @override
  String get auditReview => 'مراجعة';

  @override
  String rolesSummary(int permissions, int members) {
    return '$permissions صلاحية · $members أشخاص';
  }

  @override
  String get statusInReview => 'قيد المراجعة';

  @override
  String get statusArchived => 'مؤرشف';

  @override
  String get lifecycleTitle => 'الحالة';

  @override
  String lifecycleMoved(String status) {
    return 'حالة الدورة الآن: $status';
  }

  @override
  String get lifecycleSubmit => 'إرسال للمراجعة';

  @override
  String get lifecycleSubmitNote => 'ملاحظة للمراجع';

  @override
  String get lifecycleReturn => 'إعادة إلى المسودة';

  @override
  String get lifecycleReturnNote => 'ما يحتاج إلى إصلاح';

  @override
  String get lifecycleArchive => 'أرشفة';

  @override
  String get lifecycleRestore => 'استعادة كمسودة';

  @override
  String get lifecycleArchiveTitle => 'أرشفة هذه الدورة؟';

  @override
  String get lifecycleArchiveBody =>
      'ستُزال من الفهرس ولن يتمكن المتعلمون من فتحها. لا يُحذف شيء: تبقى التسجيلات والتقدم والمدفوعات، ويمكنك استعادتها لاحقًا.';

  @override
  String lifecyclePublishedOn(String date) {
    return 'ظاهرة للمتعلمين · نُشرت $date';
  }

  @override
  String get lifecycleArchivedHint =>
      'مؤرشفة. لا يراها المتعلمون، وسجلاتها محفوظة.';

  @override
  String get lifecycleInReviewHint => 'بانتظار مراجع لينشرها أو يعيدها.';

  @override
  String get lifecycleReady => 'جاهزة للنشر';

  @override
  String get lifecycleNotReady => 'قبل النشر:';

  @override
  String get issueNoPublishedLessons => 'انشر درسًا واحدًا على الأقل';

  @override
  String get issueNoDescription => 'أضف وصفًا للدورة';

  @override
  String get issueNoThumbnail => 'أضف صورة غلاف';

  @override
  String issueEmptyLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دروس منشورة بلا محتوى',
      one: 'درس منشور واحد بلا محتوى',
    );
    return '$_temp0';
  }

  @override
  String issueDraftLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دروس ما زالت مسودات',
      one: 'درس واحد ما زال مسودة',
    );
    return '$_temp0';
  }

  @override
  String get issueNoTeacher =>
      'عيّن معلمًا: ينتظر المتعلمون أن يفتح المعلم كل درس تالٍ';

  @override
  String get coursesSearchHint => 'ابحث بالعنوان أو المادة أو التصنيف أو الوسم';

  @override
  String get coursesFilterCurrent => 'الحالية';

  @override
  String get coursesNoMatch => 'لا توجد دورات مطابقة';

  @override
  String get courseCategory => 'التصنيف';

  @override
  String get courseCategoryHint => 'مثل: القرآن، العربية، الفقه';

  @override
  String get courseTags => 'الوسوم';

  @override
  String get courseTagsHint => 'افصل بينها بفواصل، مثل: تجويد، مبتدئون';

  @override
  String get courseSelfEnrol => 'يمكن للمتعلمين التسجيل بأنفسهم';

  @override
  String get courseSelfEnrolHint =>
      'أوقفه لتسجّل المتعلمين بنفسك رغم أن الدورة مجانية.';

  @override
  String get adminBlockLink => 'رابط (يوتيوب، تيليجرام، موقع)';

  @override
  String get linkUrlLabel => 'عنوان الرابط';

  @override
  String get linkUrlInvalid => 'أدخل رابطًا كاملًا، مثل https://youtu.be/…';

  @override
  String get linkTitleLabel => 'العنوان (اختياري)';

  @override
  String get linkDescriptionLabel => 'وصف قصير (اختياري)';

  @override
  String get linkPreview => 'ما سيراه المتعلمون';

  @override
  String get linkOpen => 'يُفتح خارج سدرة';

  @override
  String get linkProviderYoutube => 'يوتيوب';

  @override
  String get linkProviderTelegram => 'تيليجرام';

  @override
  String get adminStatInReview => 'دورات قيد المراجعة';

  @override
  String get personTitle => 'شخص';

  @override
  String get personActions => 'إجراءات';

  @override
  String personJoined(String date) {
    return 'انضم في $date';
  }

  @override
  String personLastSignIn(String date) {
    return 'آخر دخول $date';
  }

  @override
  String get personNeverSignedIn => 'لم يسجّل الدخول بعد';

  @override
  String get personTeaching => 'التدريس';

  @override
  String get personNoTeaching => 'لم يُعيَّن لأي دورة بعد';

  @override
  String personLearnerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متعلمين',
      one: 'متعلم واحد',
    );
    return '$_temp0';
  }

  @override
  String get personCourses => 'الدورات';

  @override
  String get personNoCourses => 'غير مسجّل في أي دورة';

  @override
  String personLessonsDone(int done, int total) {
    return 'أنجز $done من $total دروس';
  }

  @override
  String personLastActive(String date) {
    return 'آخر نشاط $date';
  }

  @override
  String get personReviews => 'تقييمات المعلم';

  @override
  String get personNoReviews => 'لا توجد تقييمات بعد';

  @override
  String get personQuizzes => 'نتائج الاختبارات';

  @override
  String get personQuizPending => 'بانتظار التصحيح';

  @override
  String get personActivity => 'النشاط الأخير';

  @override
  String get reviewPassed => 'نجح';

  @override
  String get reviewNeedsRevision => 'يحتاج إلى مزيد من التدريب';

  @override
  String get sourceSelf => 'سجّل بنفسه';

  @override
  String get sourceStaff => 'أضافه الطاقم';

  @override
  String get sourcePayment => 'مدفوع';

  @override
  String get peopleActive => 'نشط';

  @override
  String peopleShowing(int shown, int total) {
    return 'عرض $shown من $total';
  }

  @override
  String get peopleLoadMore => 'تحميل المزيد';

  @override
  String get staffWholeCourse => 'الدورة كاملة';

  @override
  String staffTeachesUnits(String units) {
    return 'يدرّس $units';
  }

  @override
  String get staffLimitUnits => 'تحديد الوحدات…';

  @override
  String staffLimitUnitsTitle(String name) {
    return 'ما الوحدات التي يدرّسها $name؟';
  }

  @override
  String get staffLimitUnitsHint =>
      'يقيّم المتعلمين ويفتح لهم الدروس في الوحدات المحددة فقط. لا تحدد شيئًا للدورة كاملة.';

  @override
  String get navReview => 'المراجعة';

  @override
  String get drawerLoadFailed =>
      'تعذّر تحميل القائمة. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get payCourseFee => 'رسوم الدورة';

  @override
  String payAlreadyCovered(String covered, String fee) {
    return 'تمت تغطية $covered من $fee';
  }

  @override
  String get payWithMobileMoney => 'الدفع عبر الهاتف المحمول';

  @override
  String get payOtherWay => 'دفعت بطريقة أخرى؟ أخبرنا';

  @override
  String get payPhoneHint =>
      'سنرسل طلب دفع إلى رقم MTN أو Airtel هذا. أبقِ الهاتف معك.';

  @override
  String get payPhoneLabel => 'رقم محفظة الهاتف';

  @override
  String get payPhoneInvalid =>
      'أدخل رقم MTN أو Airtel أوغندي، مثل 0772 123456';

  @override
  String get payNow => 'ادفع';

  @override
  String get payCheckPhoneTitle => 'تحقق من هاتفك';

  @override
  String payCheckPhoneBody(String amount, String phone) {
    return 'أدخل الرقم السري لدفع $amount من $phone. تتحدث هذه الصفحة تلقائيًا.';
  }

  @override
  String get payReceivedTitle => 'تم استلام الدفع';

  @override
  String get payReceivedBody => 'شكرًا لك. الدورة مفتوحة الآن.';

  @override
  String get payPendingTitle => 'بانتظار التأكيد';

  @override
  String get payPendingBody => 'سيؤكد فريق المالية دفعتك ويفتح الدورة.';

  @override
  String get payNoAnswerTitle => 'لا رد بعد';

  @override
  String get payNoAnswerBody =>
      'إن أدخلت الرقم السري فستُفتح الدورة فور تأكيد الدفع. وإلا فحاول مرة أخرى.';

  @override
  String get payFailedTitle => 'لم يكتمل الدفع';

  @override
  String get payFailedBody =>
      'رُفض الطلب أو أُلغي أو انتهت مهلته. لم يُخصم شيء. يمكنك المحاولة مجددًا.';

  @override
  String get payMethodBank => 'بنك';

  @override
  String get payMethodMobileMoney => 'محفظة الهاتف';

  @override
  String payAmountLabel(String currency) {
    return 'المبلغ المدفوع ($currency)';
  }

  @override
  String get payAmountInvalid => 'أدخل المبلغ الذي دفعته';

  @override
  String get payReferenceLabel => 'رقم العملية أو رقم قسيمة الإيداع';

  @override
  String get payReferenceRequired => 'أدخل رقم العملية أو القسيمة';

  @override
  String get payNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get paySubmitReport => 'إرسال للتأكيد';

  @override
  String get paySubmitReportHint =>
      'تُفتح الدورة بعد أن يتحقق فريق المالية من الدفع.';

  @override
  String get drawerFinance => 'المالية';

  @override
  String get drawerFinancePage => 'المدفوعات والمالية';

  @override
  String get drawerSettings => 'الإعدادات';

  @override
  String get financeOverview => 'نظرة عامة';

  @override
  String get financePayments => 'المدفوعات';

  @override
  String get financeOwing => 'المستحقات';

  @override
  String get financeWaivers => 'الإعفاءات';

  @override
  String get financeExpenses => 'المصروفات';

  @override
  String get periodThisMonth => 'هذا الشهر';

  @override
  String get periodLastMonth => 'الشهر الماضي';

  @override
  String get periodThisYear => 'هذا العام';

  @override
  String get periodAllTime => 'كل الأوقات';

  @override
  String financePendingBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دفعات بانتظار التحقق',
      one: 'دفعة واحدة بانتظار التحقق',
    );
    return '$_temp0';
  }

  @override
  String get financeCollected => 'المُحصّل';

  @override
  String get financeOutstanding => 'المتبقي';

  @override
  String get financeExpected => 'المتوقع';

  @override
  String get financeWaived => 'المُعفى';

  @override
  String get financeRefunded => 'المُسترد';

  @override
  String get financeProviderFees => 'رسوم MarzPay';

  @override
  String get financeRetained => 'الصافي';

  @override
  String get financeHowRetained => 'كيف يُحسب «الصافي»';

  @override
  String get financeFormula =>
      'الصافي = المُحصّل − المستردات − رسوم MarzPay − المصروفات';

  @override
  String get financeWaiverNote =>
      'الإعفاءات تقلل ما على المتعلمين ولا تُحسب أبدًا كمال مُحصّل.';

  @override
  String get financeByMethod => 'المُحصّل حسب الطريقة';

  @override
  String get financeByCourse => 'حسب الدورة';

  @override
  String financeCourseLine(int learners, String collected, String outstanding) {
    String _temp0 = intl.Intl.pluralLogic(
      learners,
      locale: localeName,
      other: '$learners متعلمين',
      one: 'متعلم واحد',
    );
    return '$_temp0 · المُحصّل $collected · المتبقي $outstanding';
  }

  @override
  String get methodMarzPay => 'محفظة الهاتف (MarzPay)';

  @override
  String get methodCash => 'نقدًا';

  @override
  String get methodOther => 'أخرى';

  @override
  String get paymentInProgress => 'قيد التنفيذ';

  @override
  String get paymentPending => 'للتحقق';

  @override
  String get paymentVerified => 'مؤكد';

  @override
  String get paymentFailed => 'فشل';

  @override
  String get paymentRejected => 'مرفوض';

  @override
  String get paymentReversed => 'مُلغى';

  @override
  String get financeRecordPayment => 'تسجيل دفعة';

  @override
  String get financeSearchPayments => 'ابحث بالاسم أو الهاتف أو رقم العملية';

  @override
  String get financeNoPayments => 'لا توجد مدفوعات هنا';

  @override
  String get financeLearner => 'المتعلم';

  @override
  String get financeCourse => 'الدورة';

  @override
  String get financeMethod => 'الطريقة';

  @override
  String get financeRecordedBy => 'سجّلها';

  @override
  String get financeVerifiedBy => 'تحقق منها';

  @override
  String get financeCreated => 'التاريخ';

  @override
  String get financeOpenLearner => 'فتح سجل المتعلم';

  @override
  String get financeVerify => 'تأكيد: تم استلام المال';

  @override
  String get financeReject => 'رفض';

  @override
  String get financeRefund => 'تسجيل استرداد';

  @override
  String get financeReverse => 'إلغاء (لم يُستلم المال)';

  @override
  String get reason => 'السبب';

  @override
  String get financeNobodyOwes => 'لا أحد عليه مستحقات';

  @override
  String financeOwingLine(
    String course,
    String fee,
    String paid,
    String waived,
  ) {
    return '$course · الرسوم $fee · المدفوع $paid · المُعفى $waived';
  }

  @override
  String get financeGrantWaiver => 'منح إعفاء';

  @override
  String get financeNoWaivers => 'لا توجد إعفاءات';

  @override
  String get financeFullFee => 'كامل الرسوم';

  @override
  String get financeRevoke => 'سحب الإعفاء';

  @override
  String get financeRecordExpense => 'تسجيل مصروف';

  @override
  String get financeNoExpenses => 'لا توجد مصروفات في هذه الفترة';

  @override
  String get financeVoid => 'إلغاء المصروف';

  @override
  String get financeChooseLearner => 'اختر المتعلم';

  @override
  String get financeChooseCourse => 'اختر الدورة';

  @override
  String get financeCourseChosen => 'تم اختيار الدورة';

  @override
  String get financeNoPaidCourses => 'لا توجد دورات مدفوعة بعد';

  @override
  String get financeChooseBoth => 'اختر المتعلم والدورة';

  @override
  String get financeCategory => 'الفئة';

  @override
  String get financeCategoryHint => 'مثل: إيجار، رواتب، مواصلات';

  @override
  String get financePayee => 'المستفيد (اختياري)';

  @override
  String get financeRecordHint =>
      'تنتظر المدفوعات المسجلة تحقق موظف المالية قبل احتسابها.';

  @override
  String get settingsTitle => 'إعدادات المؤسسة';

  @override
  String get settingsOrgName => 'اسم المؤسسة';

  @override
  String get settingsCurrency => 'العملة';

  @override
  String get settingsSupportPhone => 'هاتف الدعم';

  @override
  String get settingsSupportEmail => 'بريد الدعم';

  @override
  String get settingsBank => 'طريقة الدفع عبر البنك';

  @override
  String get settingsBankHint => 'البنك واسم الحساب ورقمه. يراها المتعلمون.';

  @override
  String get settingsMobileMoney =>
      'طريقة الدفع عبر محفظة الهاتف (خارج التطبيق)';

  @override
  String get settingsMarzPay => 'الدفع عبر محفظة الهاتف داخل التطبيق (MarzPay)';

  @override
  String get settingsMarzPayHint =>
      'يدفع المتعلمون بإدخال الرقم السري على هواتفهم.';

  @override
  String get enrolMany => 'تسجيل عدة متعلمين';

  @override
  String get enrolUntil => 'الوصول حتى (اختياري)';

  @override
  String get enrolNoEnd => 'بلا تاريخ انتهاء';

  @override
  String enrolSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تسجيل $count متعلمين',
      one: 'تسجيل متعلم واحد',
    );
    return '$_temp0';
  }

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get adminUnitLabel => 'الوحدة';

  @override
  String get assignmentAccepts => 'يمكن للمتعلمين تسليم:';

  @override
  String get assignmentAdd => 'إضافة واجب';

  @override
  String get assignmentAudio => 'تسجيلات صوتية';

  @override
  String get assignmentDeleteBody =>
      'حذف هذا الواجب؟ لا يمكن حذفه بعد أن يسلّم المتعلمون أعمالهم.';

  @override
  String get assignmentDocuments => 'مستندات';

  @override
  String assignmentDue(String date) {
    return 'موعد التسليم $date';
  }

  @override
  String get assignmentHint =>
      'أعمال يؤديها المتعلمون ويسلّمونها هنا: صور الكتابة أو مستندات أو تسجيلات. يراجعها المعلم ويرد عليها.';

  @override
  String get assignmentInstructions => 'المطلوب';

  @override
  String get assignmentMaxScore => 'الدرجة القصوى (اختياري)';

  @override
  String get assignmentPhotos => 'صور';

  @override
  String get assignmentText => 'إجابة مكتوبة';

  @override
  String get assignmentVideo => 'فيديو';

  @override
  String get assignmentsTitle => 'الواجبات';

  @override
  String get blockLanguage => 'لغة هذا المحتوى';

  @override
  String get blockLanguageHint =>
      'مثلًا: نص القرآن عربي حتى لو كان الدرس يُشرح بالإنجليزية.';

  @override
  String get blockShowLearners => 'إظهار للمتعلمين';

  @override
  String get blockTeachersOnly => 'للمعلمين فقط';

  @override
  String get close => 'إغلاق';

  @override
  String get courseAlsoTaughtIn => 'تُدرَّس أيضًا بـ';

  @override
  String courseForWhom(String who) {
    return 'لمن هذه الدورة: $who';
  }

  @override
  String get courseHidden => 'إخفاء من الفهرس';

  @override
  String get courseHiddenHint => 'لا يراها إلا المتعلمون المسجلون والطاقم.';

  @override
  String get courseLanguage => 'لغة التدريس الأساسية';

  @override
  String get courseLanguageHint =>
      'اللغة التي يُشرح بها. وجود نص عربي أو قرآني في الدروس لا يجعل العربية لغة التدريس.';

  @override
  String get coursePrerequisites => 'يجب إنهاؤها أولًا';

  @override
  String get coursePrerequisitesNone => 'لا متطلبات سابقة';

  @override
  String get courseTargetLearner => 'لمن هذه الدورة';

  @override
  String get courseTargetLearnerHint => 'مثل: مبتدئون لا يقرؤون العربية بعد';

  @override
  String get courseTrack => 'المسار التعليمي';

  @override
  String get courseTrackHint =>
      'القراءة والتلاوة والتجويد والعربية القرآنية أهداف مختلفة.';

  @override
  String get languageNotSet => 'غير محدد';

  @override
  String lessonCopied(String course) {
    return 'نُسخ إلى $course كمسودة';
  }

  @override
  String get lessonCopy => 'نسخ إلى دورة أخرى…';

  @override
  String lessonCopyTo(String lesson) {
    return 'نسخ «$lesson» إلى…';
  }

  @override
  String get lessonEditDetails => 'تعديل التفاصيل';

  @override
  String get lessonLanguage => 'لغة التدريس';

  @override
  String lessonLanguageFromCourse(String languages) {
    return 'مثل الدورة: $languages';
  }

  @override
  String get lessonLanguageSameAsCourse => 'مثل الدورة';

  @override
  String get lessonLocation => 'موضع هذا الدرس';

  @override
  String get lessonMove => 'نقل…';

  @override
  String lessonMoveTo(String lesson) {
    return 'نقل «$lesson» إلى…';
  }

  @override
  String get lessonMoveTop => 'أعلى الدورة (بلا وحدة)';

  @override
  String lessonMoved(String place) {
    return 'نُقل إلى $place';
  }

  @override
  String get lessonNoOutcomes =>
      'لا نتائج تعلم بعد. أضف ما سيستطيع المتعلم فعله.';

  @override
  String get lessonOutcomes => 'نتائج التعلم';

  @override
  String get lessonOutcomesHint =>
      'واحدة في كل سطر، مثل: «يقرأ الحروف المفتوحة بشكل صحيح»';

  @override
  String get lessonOverview => 'نظرة عامة';

  @override
  String get lessonQuranReference => 'المرجع القرآني';

  @override
  String get lessonQuranReferenceOptional => 'المرجع القرآني (اختياري)';

  @override
  String get lessonYouWill => 'في هذا الدرس ستتعلم أن';

  @override
  String get marzExplain =>
      'تعمل هذه الاختبارات على خادم المدفوعات، المكان الوحيد الذي يحفظ مفتاح MarzPay السري. لا يتحرك أي مال: يُختبر التحصيل بطلب يجب أن يرفضه MarzPay. لا يُثبت الدفع الحقيقي إلا بدفع رسوم دورة وإدخال الرقم السري.';

  @override
  String marzLastSeen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get marzNoAnswer => 'لم يرد خادم المدفوعات. هل هو يعمل؟';

  @override
  String marzResultsFrom(String time) {
    return 'نتائج $time';
  }

  @override
  String get marzRunTests => 'اختبار الربط';

  @override
  String get marzRunning => 'جارٍ الاختبار…';

  @override
  String get marzServerOffline =>
      'خادم المدفوعات لا يعمل: تنتظر مدفوعات المتعلمين حتى يعمل';

  @override
  String get marzServerOnline => 'خادم المدفوعات يعمل';

  @override
  String get marzTitle => 'MarzPay (الدفع عبر الهاتف)';

  @override
  String get provisionalBody =>
      'أُضيف كنقطة بداية. ينبغي أن يراجعه معلم أو عالم قبل أن يستخدمه المتعلمون.';

  @override
  String get provisionalTitle => 'يحتاج إلى مراجعة';

  @override
  String get quranAyahFrom => 'من الآية';

  @override
  String get quranAyahTo => 'إلى الآية';

  @override
  String quranRef(String ref) {
    return 'القرآن $ref';
  }

  @override
  String get quranSurah => 'رقم السورة';

  @override
  String get resourceAddLink => 'إضافة رابط';

  @override
  String get resourceCheckLink => 'فحص الرابط';

  @override
  String get resourceFile => 'الملف';

  @override
  String get resourceHide => 'إخفاء عن المتعلمين';

  @override
  String get resourceLanguage => 'اللغة';

  @override
  String get resourceLocked => 'ليس لديك صلاحية لفتح هذا الملف.';

  @override
  String get resourceLooksRight => 'صحيح: حفظ';

  @override
  String get resourceNotVerified => 'غير مفحوص';

  @override
  String get resourceOpen => 'فتح';

  @override
  String resourcePreviewUnavailable(String reason) {
    return 'لا توجد معاينة تلقائية ($reason). تحقق من العنوان بنفسك قبل الحفظ.';
  }

  @override
  String get resourceRemove => 'إزالة';

  @override
  String resourceRemoveBody(String title) {
    return 'إزالة «$title» من هنا؟ يبقى الملف نفسه محفوظًا.';
  }

  @override
  String get resourceSaveAnyway => 'أثق به: حفظ';

  @override
  String get resourceShow => 'إظهار للمتعلمين';

  @override
  String get resourceSize => 'الحجم';

  @override
  String get resourceType => 'النوع';

  @override
  String get resourceUpload => 'رفع ملف';

  @override
  String get resourceUploadNow => 'رفع';

  @override
  String resourceUploading(String name) {
    return 'جارٍ رفع $name';
  }

  @override
  String get resourceVerified => 'مفحوص';

  @override
  String get resourcesNone => 'لا ملفات أو روابط بعد.';

  @override
  String get resourcesTitle => 'المصادر';

  @override
  String get settingsPayments => 'المدفوعات';

  @override
  String get subAttachFile => 'إرفاق ملف';

  @override
  String subAttempt(int n) {
    return 'المحاولة $n';
  }

  @override
  String get subFeedback => 'ملاحظات للمتعلم';

  @override
  String subFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملفات',
      one: 'ملف واحد',
      zero: 'بلا ملفات',
    );
    return '$_temp0';
  }

  @override
  String get subFromGallery => 'من المعرض';

  @override
  String get subHandIn => 'تسليم';

  @override
  String get subHandedIn => 'تم التسليم. وصل إلى معلمك.';

  @override
  String get subMarkReviewed => 'تمت المراجعة';

  @override
  String get subMarkUnderReview => 'قيد المراجعة';

  @override
  String get subNoneToReview => 'لا شيء هنا';

  @override
  String get subPrivacyNote => 'لا يرى ما تسلّمه إلا أنت ومعلموك.';

  @override
  String get subReceived => 'تم الاستلام';

  @override
  String get subRequestResubmission => 'طلب إعادة التسليم';

  @override
  String get subResubmit => 'يرجى إعادة المحاولة';

  @override
  String get subReturned => 'أُعيد';

  @override
  String get subReviewed => 'تمت المراجعة';

  @override
  String get subSavedForLater =>
      'حُفظ على هذا الهاتف. سيُرفع عند الاتصال؛ اضغط «حاول مرة أخرى».';

  @override
  String get subScoreOptional => 'الدرجة (اختياري)';

  @override
  String get subSubmitAgain => 'تسليم مرة أخرى';

  @override
  String get subSubmitWork => 'تسليم العمل';

  @override
  String get subSubmitted => 'تم التسليم';

  @override
  String get subTakePhoto => 'التقاط صورة';

  @override
  String get subTeacherHint => 'أعمال سلّمها المتعلمون في دروسك';

  @override
  String get subTitle => 'الأعمال المسلّمة';

  @override
  String get subUnderReview => 'قيد المراجعة';

  @override
  String get subUploadFailed => 'فشل الرفع';

  @override
  String get subWaitingToUpload => 'بانتظار الرفع (لم يُسلَّم بعد)';

  @override
  String get subWorkTab => 'الأعمال';

  @override
  String get subYourAnswer => 'إجابتك';

  @override
  String subYourWork(String status, int attempt) {
    return 'عملك: $status (المحاولة $attempt)';
  }

  @override
  String taughtIn(String languages) {
    return 'يُدرَّس بـ $languages';
  }

  @override
  String get uploadFailed => 'فشل الرفع';

  @override
  String get uploadUploading => 'جارٍ الرفع…';

  @override
  String get aboutTitle => 'عن سدرة';

  @override
  String aboutBody(String org) {
    return 'سدرة تطبيق $org لتعلّم القرآن والعلوم الإسلامية. يعطي المعلم ورد اليوم مرة واحدة، ويقرأ المتعلمون ويستمعون ويسجّلون، ويحصل كل متعلم على تصحيح معلمه الخاص.';
  }

  @override
  String aboutBy(String org) {
    return 'صُنع لـ$org بواسطة Xhenvolt.';
  }

  @override
  String get aboutLicences => 'تراخيص البرمجيات المفتوحة';

  @override
  String aboutVersion(String version, String build) {
    return 'الإصدار $version (البناء $build)';
  }

  @override
  String get aboutWhatsNew => 'ما الجديد';

  @override
  String get analyticsTitle => 'مؤشرات التعليم';

  @override
  String analyticsDays(int days) {
    return '$days يومًا';
  }

  @override
  String get anWaiting => 'بانتظار المراجعة';

  @override
  String get anWaitingQ => 'أعمال لم تُراجَع بعد';

  @override
  String get anTurnaround => 'زمن المراجعة';

  @override
  String get anTurnaroundQ => 'متوسط الوقت حتى أول مراجعة';

  @override
  String get anFirstTry => 'صحيح من أول مرة';

  @override
  String get anFirstTryQ => 'المحاولات الأولى الصحيحة';

  @override
  String get anSubmissions => 'التسليمات';

  @override
  String get anSubmissionsQ => 'التسجيلات والأعمال المسلّمة';

  @override
  String get anIncomplete => 'غير مكتمل';

  @override
  String get anIncompleteQ => 'أوراد مفتوحة بعد 3 أيام';

  @override
  String get anTopCorrections => 'أكثر التصحيحات استخدامًا';

  @override
  String get anTopCategories => 'أكثر الأخطاء شيوعًا';

  @override
  String get anRepeat => 'متعلمون يعيدون كثيرًا';

  @override
  String get anByTeacher => 'المراجعات لكل معلم';

  @override
  String get anNone => 'لا شيء بعد';

  @override
  String get attNew => 'أعمال جديدة';

  @override
  String get attResubmissions => 'أعادوا المحاولة';

  @override
  String get attCorrection => 'بانتظار إعادة المحاولة';

  @override
  String get attNotSubmitted => 'لم يُرسل بعد';

  @override
  String get attBehind => 'متأخرون';

  @override
  String attOpenPortions(int count) {
    return '$count أوراد مفتوحة';
  }

  @override
  String get attAllClear => 'لا شيء يحتاجك الآن.';

  @override
  String get audioPlay => 'تشغيل';

  @override
  String get audioPause => 'إيقاف مؤقت';

  @override
  String get audioRecord => 'تسجيل';

  @override
  String get audioRecording => 'جارٍ التسجيل';

  @override
  String get audioPaused => 'متوقف مؤقتًا';

  @override
  String get audioPauseRecording => 'إيقاف مؤقت';

  @override
  String get audioResume => 'متابعة';

  @override
  String get audioStop => 'إيقاف';

  @override
  String get audioDiscard => 'حذف';

  @override
  String get audioRecordAgain => 'سجّل من جديد';

  @override
  String audioYourRecording(String duration) {
    return 'تسجيلك ($duration)';
  }

  @override
  String get audioNeedsMicrophone =>
      'يحتاج سدرة إلى الميكروفون للتسجيل. اسمح به من إعدادات الهاتف.';

  @override
  String get audioRecordFailed => 'لم ينجح التسجيل. حاول مرة أخرى.';

  @override
  String get audioCannotPlay => 'لا يمكن تشغيل هذا التسجيل.';

  @override
  String get audioLibraryTitle => 'مكتبة الصوتيات';

  @override
  String get audioSearch => 'ابحث في التسجيلات';

  @override
  String get audioOnlyMine => 'تسجيلاتي فقط';

  @override
  String get audioNone => 'لا تسجيلات بعد';

  @override
  String get correctionLibrary => 'مكتبة التصحيحات';

  @override
  String get correctionLibraryHint =>
      'التصحيحات المحفوظة أثناء المراجعة تظهر هنا جاهزة لإعادة الاستخدام.';

  @override
  String get correctionAdd => 'تصحيح جديد';

  @override
  String get correctionSearch => 'ابحث: ص، الشدة، المد…';

  @override
  String get correctionNone => 'لا توجد تصحيحات';

  @override
  String get correctionTitle => 'العنوان';

  @override
  String get correctionTitleHint => 'مثل: الفرق بين ص و س';

  @override
  String get correctionCategory => 'نوع الخطأ';

  @override
  String get correctionExplanation => 'شرح قصير (اختياري)';

  @override
  String correctionUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استُخدم $count مرات',
      one: 'استُخدم مرة',
      zero: 'لم يُستخدم',
    );
    return '$_temp0';
  }

  @override
  String get correctionArchive => 'أرشفة';

  @override
  String get correctionForYou => 'تصحيح لك';

  @override
  String get groupNew => 'مجموعة جديدة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String groupLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متعلمين',
      one: 'متعلم واحد',
      zero: 'لا متعلمين',
    );
    return '$_temp0';
  }

  @override
  String get groupNoLearners => 'لا يوجد متعلمون مسجلون في هذه الدورة بعد.';

  @override
  String get groupMembers => 'المتعلمون';

  @override
  String groupWaiting(int count) {
    return '$count بانتظارك';
  }

  @override
  String get groupsNone => 'لا مجموعات بعد. أنشئ مجموعة لصف تدرّسه.';

  @override
  String get myGroups => 'مجموعاتي';

  @override
  String get needsAttention => 'يحتاج انتباهي';

  @override
  String get navTeaching => 'التدريس';

  @override
  String get libraryTitle => 'مكتبة المحتوى';

  @override
  String get librarySearch => 'ابحث في الملفات والروابط';

  @override
  String get libraryRenameTag => 'إعادة تسمية أو وسم';

  @override
  String get libraryReplace => 'استبدال بنسخة جديدة';

  @override
  String get libraryReplaced =>
      'حُفظت النسخة الجديدة. الأعمال المعيّنة سابقًا تبقى على القديمة.';

  @override
  String libraryUsedIn(int lessons, int portions) {
    return 'في $lessons دروس و$portions أوراد';
  }

  @override
  String get listenTeacher => 'استمع إلى معلمك';

  @override
  String get listenModel => 'استمع إلى القراءة النموذجية';

  @override
  String get notSentYet => 'محفوظ على هذا الهاتف. لم يصل إلى معلمك بعد.';

  @override
  String get noteAdd => 'ملاحظة خاصة';

  @override
  String get notePrivate => 'ملاحظة (يراها المعلمون فقط)';

  @override
  String get notePrivateHint => 'مثل: ما زال يخلط بين ض و ظ';

  @override
  String notesAbout(String name) {
    return 'ملاحظات عن $name';
  }

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsNone => 'لا إشعارات';

  @override
  String get notificationsMarkRead => 'تعليم الكل كمقروء';

  @override
  String get partNew => 'جديد';

  @override
  String get partToDo => 'للإنجاز';

  @override
  String get partWaiting => 'أُرسل · بالانتظار';

  @override
  String get partUnderReview => 'المعلم يستمع';

  @override
  String get partTryAgain => 'أعد المحاولة';

  @override
  String get partDone => 'تم';

  @override
  String get portionDefaultTitle => 'صفحة ';

  @override
  String get portionCreateToday => 'إنشاء ورد اليوم';

  @override
  String portionCreateNext(String title) {
    return 'التالي بعد $title';
  }

  @override
  String get portionsTitle => 'الأوراد';

  @override
  String get portionEdit => 'تعديل الورد';

  @override
  String get portionTitle => 'العنوان';

  @override
  String get portionTitleHint => 'مثل: صفحة 12';

  @override
  String get portionTask => 'المطلوب من المتعلمين';

  @override
  String get portionTaskHint => 'مثل: اقرأ الصفحة ثلاث مرات وانتبه للشدة.';

  @override
  String get portionExplainedIn => 'لغة الشرح';

  @override
  String get portionLearnersSend => 'يرسل المتعلمون';

  @override
  String get portionPage => 'الصفحة';

  @override
  String get portionAddPage => 'إضافة صفحة (صورة أو PDF)';

  @override
  String get portionInstruction => 'تعليمات المعلم';

  @override
  String get portionRecordInstruction => 'سجّل التعليمات';

  @override
  String get portionModel => 'القراءة النموذجية';

  @override
  String get portionRecordModel => 'سجّل القراءة النموذجية';

  @override
  String get portionFromLibrary => 'من صوتياتي';

  @override
  String get portionUseRecording => 'استخدم هذا التسجيل';

  @override
  String get portionAssignGroup => 'تعيين للمجموعة';

  @override
  String get portionAssignChosen => 'تعيين لمتعلمين محددين';

  @override
  String portionAssignCount(int count) {
    return 'تعيين لـ $count';
  }

  @override
  String portionAssigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وصل إلى $count متعلمين',
      one: 'وصل إلى متعلم واحد',
      zero: 'لدى الجميع مسبقًا',
    );
    return '$_temp0';
  }

  @override
  String get portionSaveDraft => 'حفظ كمسودة';

  @override
  String get portionNotAssigned => 'لم يُعيَّن لأحد بعد';

  @override
  String get portionBoardHint => 'اضغط على المتعلم للاستماع والمراجعة.';

  @override
  String get recordHint => 'اقرأ الصفحة بصوت مسموع وسجّل نفسك.';

  @override
  String get recordAgainBelow => 'استمع، ثم سجّل مرة أخرى في الأسفل.';

  @override
  String get resExcellent => 'ممتاز';

  @override
  String get resCorrect => 'صحيح';

  @override
  String get resMinor => 'صحيح مع ملاحظة';

  @override
  String get resCorrection => 'يحتاج تصحيحًا';

  @override
  String get resExplain => 'يحتاج شرحًا';

  @override
  String get reviewCorrectionTitle => 'التصحيح';

  @override
  String get reviewUseExisting => 'تصحيح محفوظ';

  @override
  String get reviewRecordNew => 'سجّل جديدًا';

  @override
  String get reviewSaveToLibrary => 'احفظ في مكتبة التصحيحات';

  @override
  String get reviewSaveToLibraryHint =>
      'أعد استخدامه للمتعلم التالي بنفس الخطأ.';

  @override
  String get reviewFeedbackOptional => 'ملاحظة مكتوبة (اختياري)';

  @override
  String get reviewSent => 'أُرسل إلى المتعلم';

  @override
  String get sendToTeacher => 'أرسل إلى المعلم';

  @override
  String get sentToTeacher => 'أُرسل. وصل إلى معلمك.';

  @override
  String get sentWaiting => 'أُرسل: بانتظار معلمك';

  @override
  String get sentWaitingBody => 'ستُبلَّغ عندما يرد معلمك.';

  @override
  String teacherSays(String text) {
    return 'معلمك: $text';
  }

  @override
  String get theirRecording => 'تسجيله';

  @override
  String get todayLearning => 'تعلّم اليوم';

  @override
  String get useThis => 'استخدم';

  @override
  String yourAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'محاولاتك ($count)',
      one: 'محاولتك',
    );
    return '$_temp0';
  }

  @override
  String get yourTask => 'مهمتك';

  @override
  String get deleteLearner => 'حذف نهائي';

  @override
  String get deleteLearnerHint => 'مسح هذا المتعلم وكل ما يتعلق به';

  @override
  String deleteLearnerTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteLearnerBody =>
      'يمسح هذا حسابه وتسجيلاته في الدورات وتقدّمه وتسجيلاته الصوتية وصوره وملاحظات المعلمين والإشعارات. لا يمكن التراجع. إن كانت له مدفوعات فتُحفظ للحسابات باسم «متعلم محذوف» دون اسم أو بيانات اتصال.';

  @override
  String deleteLearnerTypeName(String name) {
    return 'اكتب «$name» للتأكيد';
  }

  @override
  String get deleteReason => 'السبب (اختياري، يُحفظ في سجل النشاط)';

  @override
  String get deleteLearnerConfirm => 'حذف نهائي';

  @override
  String get deleteLearnerDone => 'حُذف المتعلم.';

  @override
  String get deleteLearnerKept =>
      'حُذف المتعلم. حُفظت مدفوعاته للحسابات باسم «متعلم محذوف».';

  @override
  String get categoriesTitle => 'الأنواع';

  @override
  String get categoriesHint =>
      'تنظّم أنواع الأخطاء مكتبة التصحيحات. أعد التسمية أو الترتيب أو أضف أنواعًا؛ حذف النوع يُبقي تصحيحاته.';

  @override
  String get categoryAdd => 'نوع جديد';

  @override
  String get categoryAddSub => 'إضافة نوع فرعي';

  @override
  String get categoryRename => 'إعادة تسمية';

  @override
  String get categoryName => 'الاسم';

  @override
  String get categoryDelete => 'حذف';

  @override
  String categoryDeleteBody(String name) {
    return 'حذف «$name» وأنواعه الفرعية؟ تبقى تصحيحاته بلا نوع.';
  }

  @override
  String get resourcesForSection => 'مصادر هذا القسم';

  @override
  String get resourcesForUnit => 'مصادر هذه الوحدة';

  @override
  String get libraryUsageAccess => 'أماكن الاستخدام ومن يراه';

  @override
  String get libraryWhoCanSee => 'من يمكنه رؤيته';

  @override
  String get libraryAccessLearners => 'المتعلمون المصرّح لهم';

  @override
  String get libraryAccessLearnersHint =>
      'فقط المتعلمون المسموح لهم بالدرس أو الدورة التي يُستخدم فيها، والطاقم.';

  @override
  String get libraryAccessPublic => 'كل من يطّلع على صفحة الدورة';

  @override
  String get libraryAccessPublicHint =>
      'وأيضًا المسجلون غير الملتحقين بعد، مثل نشرة أو صفحة نموذجية.';

  @override
  String get libraryUsedWhere => 'أين يُستخدم';

  @override
  String get libraryAddTo => 'أضف إلى…';

  @override
  String get libraryMoveHint =>
      'لنقله: أضفه إلى المكان الجديد ثم أزله من القديم. تحتفظ الأوراد اليومية بملفاتها.';

  @override
  String get libraryNotUsed => 'غير مستخدم بعد.';

  @override
  String get libraryAddToCourse => 'إلى أي دورة؟';

  @override
  String libraryAddWhere(String course) {
    return 'أين في $course؟';
  }

  @override
  String get libraryCoursePage => 'صفحة الدورة';

  @override
  String get librarySection => 'القسم';

  @override
  String get personTeachesIn => 'يدرّس بـ';

  @override
  String get personTeachesInNone => 'غير محدد. اضغط لاختيار اللغات.';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get repLearners => 'المتعلمون';

  @override
  String get repLearnersQ => 'الحسابات الفعّالة';

  @override
  String get repActive => 'يدرسون';

  @override
  String get repActiveQ => 'متعلمون نشطوا في هذه المدة';

  @override
  String get repNew => 'جدد';

  @override
  String get repNewQ => 'انضموا في هذه المدة';

  @override
  String get repCompletions => 'أنهوا';

  @override
  String get repCompletionsQ => 'دورات اكتملت في هذه المدة';

  @override
  String get repCourses => 'إتمام الدورات';

  @override
  String get repCoursesQ => 'هل يتقدم المتعلمون في كل دورة؟';

  @override
  String repCourseLine(
    int enrolled,
    int completed,
    int progress,
    int active,
    int stalled,
  ) {
    return '$enrolled مسجلون · $completed أنهوا · $progress% متوسط التقدم · $active نشطون · $stalled متوقفون';
  }

  @override
  String get repQuiet => 'انقطعوا';

  @override
  String repQuietQ(int days) {
    return 'متعلمون مسجلون بلا نشاط منذ $days يومًا: من نتابع؟';
  }

  @override
  String get repNeverStarted => 'لم يبدأ';

  @override
  String repLastSeen(String date) {
    return 'آخر نشاط $date';
  }

  @override
  String get repTeachers => 'نشاط المعلمين';

  @override
  String get repTeachersQ => 'من يراجع، وبأي سرعة، وما الذي ينتظرهم؟';

  @override
  String repTeacherReviews(int count) {
    return '$count مراجعة';
  }

  @override
  String repTeacherTurnaround(String hours) {
    return '$hours ساعة للمراجعة';
  }

  @override
  String repTeacherWaiting(int count) {
    return '$count بانتظاره';
  }

  @override
  String get avatarTitle => 'صورة الملف الشخصي';

  @override
  String get avatarChange => 'تغيير صورة الملف الشخصي';

  @override
  String get avatarTakePhoto => 'التقط صورة';

  @override
  String get avatarUpload => 'ارفع من الهاتف';

  @override
  String get avatarChoose => 'أو اختر رمزًا';

  @override
  String get avatarRemove => 'إزالة الصورة';

  @override
  String get avatarSaved => 'تم تحديث صورة الملف الشخصي';

  @override
  String get viewerDownloading => 'جارٍ التنزيل…';

  @override
  String get viewerOpenAgain => 'افتح مرة أخرى';

  @override
  String get viewerNoApp =>
      'لا يوجد على هذا الهاتف تطبيق يفتح هذا النوع من المستندات. ثبّت تطبيق مستندات (مثل Microsoft Word أو WPS Office) ثم حاول مجددًا.';

  @override
  String get capPhoto => 'التقاط صورة';

  @override
  String get capVideo => 'تسجيل فيديو';

  @override
  String get capScan => 'مسح صفحات (PDF)';

  @override
  String get capAudio => 'تسجيل صوت';

  @override
  String get capGallery => 'من المعرض';

  @override
  String get capFile => 'اختيار ملف';

  @override
  String get capPaste => 'لصق نص';

  @override
  String capFailed(String reason) {
    return 'تعذّر الفتح: $reason';
  }

  @override
  String capSize(String size) {
    return 'الحجم: $size';
  }

  @override
  String capPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحات',
      one: 'صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get capLarge =>
      'هذا ملف كبير. رفعه يستهلك بيانات كثيرة؛ الأفضل استخدام Wi-Fi.';

  @override
  String get capUse => 'ارفع هذا';

  @override
  String get capAddContent => 'أضف: التقط أو سجّل أو امسح أو اختر';

  @override
  String get capAddWork => 'أضف صورة أو مسحًا أو ملفًا';

  @override
  String get capClipboardEmpty => 'لا يوجد نص للصق. انسخ نصًا أولًا.';

  @override
  String get capPasted => 'أُضيف النص. اضغط عليه لتعديله.';

  @override
  String get layoutGrid => 'عرض كشبكة';

  @override
  String get layoutList => 'عرض كقائمة';

  @override
  String get topCourses => 'أشهر الدورات';

  @override
  String topCoursesLearners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متعلمين',
      one: 'متعلم واحد',
    );
    return '$_temp0';
  }

  @override
  String get allCourses => 'كل الدورات';

  @override
  String get previewAsLearner => 'معاينة كمتعلم';

  @override
  String get previewAsLearnerHint => 'شاهد التطبيق كما يراه المتعلمون تمامًا';

  @override
  String get previewBanner => 'أنت تعاين التطبيق كمتعلم';

  @override
  String get previewExit => 'خروج';

  @override
  String get previewNoProgress => 'معاينة: يُسجَّل التقدم للمتعلمين فقط';

  @override
  String get rulesTitle => 'قواعد الدروس';

  @override
  String get rulesHint =>
      'كيف ينتقل المتعلم من درس إلى الذي يليه. تفرض قاعدة البيانات ذلك: لا يمكن فتح الدروس المقفلة.';

  @override
  String get ruleApproval => 'بعد موافقة المعلم على العمل';

  @override
  String get ruleApprovalHint =>
      'يسلّم المتعلم عمله ويصححه المعلم (كلمة كلمة إن شاء). الدرجة التي تبلغ علامة النجاح تفتح الدرس التالي.';

  @override
  String get ruleSubmission => 'بعد تسليم العمل';

  @override
  String get ruleSubmissionHint =>
      'تسليم عمل الدرس يفتح الدرس التالي، ويراجعه المعلم لاحقًا.';

  @override
  String get ruleTeacherHint => 'يفتح المعلم كل درس تالٍ يدويًا.';

  @override
  String get ruleSequentialHint => 'إنهاء (قراءة) الدرس يفتح الدرس التالي.';

  @override
  String get ruleOpenHint => 'كل الدروس مفتوحة بأي ترتيب.';

  @override
  String rulePassMark(int percent) {
    return 'علامة النجاح: $percent%';
  }

  @override
  String get ruleMaxAttempts => 'الحد الأقصى للمحاولات في الدرس (اختياري)';

  @override
  String get ruleMaxAttemptsHint => 'اتركه فارغًا لمحاولات غير محدودة.';

  @override
  String get courseNotifications => 'إشعارات هذه الدورة';

  @override
  String get courseNotificationsHint =>
      'أوقف ما لا ينبغي أن ترسله هذه الدورة. مفاتيح الإعدادات تنطبق على كل الدورات.';

  @override
  String get notifyLessonWork => 'عمل جديد للمعلمين';

  @override
  String get notifyReviewed => 'قبول العمل (للمتعلمين)';

  @override
  String get notifyCorrection => 'التصحيحات (للمتعلمين)';

  @override
  String get notifyPortionAssigned => 'ورد يومي جديد (للمتعلمين)';

  @override
  String get notifySubmission => 'تسجيلات الأوراد (للمعلمين)';

  @override
  String get notifyResubmission => 'إعادة المحاولة (للمعلمين)';

  @override
  String get lessonWorkRequired => 'يتطلب تسليم عمل';

  @override
  String lessonWorkFollowsCourse(String answer) {
    return 'يتبع قاعدة الدورة ($answer)';
  }

  @override
  String get lessonWorkFollowCourse => 'اتبع قاعدة الدورة';

  @override
  String get lessonWorkYes => 'نعم، يسلّم المتعلمون عملًا';

  @override
  String get lessonWorkNo => 'لا عمل في هذا الدرس';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get workSubmit => 'سلّم العمل';

  @override
  String get workSubmitAgain => 'سلّم مرة أخرى';

  @override
  String get workTitle => 'عملك';

  @override
  String get workHint =>
      'سجّل قراءتك، أو أضف صورة أو مسحًا أو ملفًا لعملك، ثم أرسله إلى معلمك.';

  @override
  String get workAnswer => 'إجابة مكتوبة (اختياري)';

  @override
  String get workWaiting => 'سُلّم: بانتظار معلمك';

  @override
  String get workApproved => 'قُبل. الدرس التالي مفتوح.';

  @override
  String get workApprovedNoUnlock => 'قُبل.';

  @override
  String get workTryAgain => 'يطلب منك معلمك إعادة المحاولة';

  @override
  String workScore(String score, int pass) {
    return 'الدرجة: $score% (علامة النجاح $pass%)';
  }

  @override
  String get workNeededToFinish => 'سلّم عملك لإنهاء هذا الدرس';

  @override
  String get workQueueTitle => 'أعمال الدروس';

  @override
  String get workQueueEmpty => 'لا توجد أعمال بانتظار المراجعة';

  @override
  String get workMarkWords => 'صحّح كلمة كلمة';

  @override
  String get workMarkWordsHint =>
      'اضغط على الكلمة: صحيحة ← ضعيفة ← خاطئة. تتبع الدرجة تصحيحك ويمكنك تعديلها.';

  @override
  String workScoreLabel(int score) {
    return 'الدرجة الكلية: $score%';
  }

  @override
  String workWillPass(int pass) {
    return 'ناجح (علامة النجاح $pass%): سيُفتح الدرس التالي';
  }

  @override
  String workWillFail(int pass) {
    return 'أقل من علامة النجاح ($pass%): سيُطلب من المتعلم إعادة المحاولة';
  }

  @override
  String get workApprove => 'قبول';

  @override
  String get workNeedsCorrection => 'يحتاج تصحيحًا';

  @override
  String get workNoText =>
      'لا يحتوي هذا الدرس على نص قرآني للتصحيح كلمة كلمة؛ ضع درجة كلية.';

  @override
  String get workLegend => 'صحيحة · ضعيفة · خاطئة';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsNotificationsHint =>
      'أوقف نوعًا من الإشعارات لكل الدورات. ويمكن أيضًا إيقافها لكل دورة على حدة.';

  @override
  String get inboxTitle => 'صندوق الأعمال';

  @override
  String get inboxEmpty => 'لا شيء بانتظارك';

  @override
  String inboxWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعمال بانتظارك',
      one: 'عمل واحد بانتظارك',
    );
    return '$_temp0';
  }

  @override
  String get inboxAutoNext => 'راجع التالي تلقائيًا';

  @override
  String get inboxAutoNextHint =>
      'بعد إنهاء عمل يُفتح التالي، لتصحح الصف كله دفعة واحدة.';

  @override
  String authErrorSignupClosed(String org) {
    return 'لا تقبل $org تسجيلات جديدة حاليًا. اطلب منهم إضافتك.';
  }

  @override
  String get settingsOrgNameAr => 'اسم المؤسسة بالعربية';

  @override
  String get settingsSignupSecurity => 'التسجيل والأمان';

  @override
  String get settingsAllowSignup => 'يمكن لأي شخص إنشاء حساب';

  @override
  String get settingsAllowSignupHint =>
      'عند الإيقاف، يضيف الموظفون المتعلمين فقط.';

  @override
  String get settingsMinPassword => 'أقصر كلمة مرور مسموحة (6–64)';

  @override
  String get settingsLockoutAttempts =>
      'عدد المحاولات الخاطئة قبل قفل الحساب (3–20)';

  @override
  String get settingsLockoutMinutes => 'دقائق بقاء الحساب مقفلًا';

  @override
  String get settingsTeachingDefaults => 'إعدادات التدريس الافتراضية';

  @override
  String get settingsTeachingDefaultsHint =>
      'تُستخدم للدورات الجديدة ولقوائم متابعة المعلمين.';

  @override
  String get settingsStaleDays =>
      'أيام قبل أن يحتاج العمل غير المراجَع إلى متابعة';

  @override
  String get settingsFallingBehind =>
      'عدد المقاطع المتأخرة قبل التنبيه على المتعلم';

  @override
  String get settingsDefaultRule => 'قاعدة الدروس للدورات الجديدة';

  @override
  String settingsDefaultPassMark(int n) {
    return 'درجة النجاح للدورات الجديدة: $n%';
  }

  @override
  String get settingsAppUpdates => 'تحديثات التطبيق';

  @override
  String get settingsAppUpdatesHint =>
      'عند نشر إصدار جديد، يُطلب من الهواتف ذات الإصدار الأقدم التحديث.';

  @override
  String get settingsLatestVersion => 'أحدث إصدار (مثل 2.27.0)';

  @override
  String get settingsLatestBuild => 'رقم أحدث بناء';

  @override
  String get settingsDownloadUrl => 'رابط التنزيل (https://…)';

  @override
  String get settingsMinBuild => 'أقدم بناء مسموح به';

  @override
  String get settingsMinBuildHint =>
      'يجب على الهواتف الأقدم التحديث للمتابعة. اتركه فارغًا للسماح للجميع.';

  @override
  String settingsThisBuild(String version, String build) {
    return 'هذا الهاتف يعمل بالإصدار $version (بناء $build).';
  }

  @override
  String get settingsLanguagesTracks => 'اللغات ومسارات التعلم';

  @override
  String get settingsLanguagesTracksHint => 'لغات تدريس الدورات وطريقة تجميعها';

  @override
  String get settingsExport => 'تصدير البيانات';

  @override
  String get settingsExportHint =>
      'المتعلمون والتسجيلات والمدفوعات والتقدم كجداول';

  @override
  String get langTitle => 'اللغات والمسارات';

  @override
  String get langLanguages => 'اللغات';

  @override
  String get langTracks => 'مسارات التعلم';

  @override
  String get langAdd => 'إضافة لغة';

  @override
  String get trackAdd => 'إضافة مسار';

  @override
  String get langCode => 'الرمز (مثل fr)';

  @override
  String get langName => 'الاسم بالإنجليزية';

  @override
  String get langNative => 'الاسم باللغة نفسها';

  @override
  String get langRtl => 'تُكتب من اليمين إلى اليسار';

  @override
  String get langActive => 'متاحة للدورات';

  @override
  String get langHidden => 'مخفية';

  @override
  String get langCodeInvalid => 'استخدم حرفين أو ثلاثة صغيرة، مثل fr';

  @override
  String get trackKey => 'مفتاح قصير (مثل fiqh)';

  @override
  String get trackKeyInvalid => 'حروف صغيرة وأرقام و _، تبدأ بحرف';

  @override
  String get trackName => 'الاسم';

  @override
  String get trackDescription => 'الوصف';

  @override
  String get exportTitle => 'تصدير البيانات';

  @override
  String get exportLearners => 'المتعلمون';

  @override
  String get exportLearnersHint => 'كل متعلم مع وسائل الاتصال وعدد الدورات';

  @override
  String get exportEnrolments => 'التسجيلات';

  @override
  String get exportEnrolmentsHint => 'من في أي دورة وإلى أين وصل';

  @override
  String get exportPayments => 'المدفوعات';

  @override
  String get exportPaymentsHint => 'كل دفعة وحالتها';

  @override
  String get exportProgress => 'تقدم الدروس';

  @override
  String get exportProgressHint => 'تقدم كل متعلم درسًا بدرس';

  @override
  String exportSaved(int count) {
    return 'تم حفظ $count صفًا';
  }

  @override
  String get exportEmpty => 'لا يوجد ما يُصدَّر بعد';

  @override
  String get exportNote =>
      'تُفتح الملفات في Excel أو Google Sheets أو أي تطبيق جداول.';

  @override
  String get updateAvailableTitle => 'إصدار جديد جاهز';

  @override
  String updateAvailableBody(String version) {
    return 'سدرة $version متاح مع أحدث التحسينات.';
  }

  @override
  String get updateRequiredTitle => 'يرجى تحديث سدرة';

  @override
  String get updateRequiredBody =>
      'لم يعد هذا الإصدار مدعومًا. نزّل الإصدار الجديد للمتابعة.';

  @override
  String get updateNow => 'تحديث';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get authErrorTryLater =>
      'محاولات تسجيل دخول كثيرة الآن. انتظر دقيقة ثم حاول مجددًا.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int n) {
    return 'قبل $n دقيقة';
  }

  @override
  String timeHoursAgo(int n) {
    return 'قبل $n ساعة';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $n أيام',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String get presenceTitle => 'من المتصل الآن';

  @override
  String get presenceMenuHint => 'الهواتف المسجلة وآخر ظهور وآخر استخدام';

  @override
  String get presenceHint =>
      'تسجيل الدخول والاتصال والاستخدام أمور مختلفة: قد يكون الهاتف مسجلًا لكنه غير متصل، أو متصلًا دون أن يستخدمه أحد.';

  @override
  String get presenceSearch => 'ابحث بالاسم';

  @override
  String presenceSignedIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'مسجل على $n هواتف',
      one: 'مسجل على هاتف واحد',
    );
    return '$_temp0';
  }

  @override
  String get presenceSignedOut => 'غير مسجل';

  @override
  String get presenceOnline => 'متصل';

  @override
  String get presenceActiveNow => 'يستخدم سدرة الآن';

  @override
  String presenceLastSeen(String when) {
    return 'آخر ظهور $when';
  }

  @override
  String presenceLastActive(String when) {
    return 'آخر استخدام $when';
  }

  @override
  String get presenceNeverSeen => 'لم يظهر بعد';

  @override
  String get devicesTitle => 'الأجهزة وتسجيلات الدخول';

  @override
  String get devicesMine => 'أجهزتك';

  @override
  String get devicesPersonHint =>
      'الهواتف، الاتصال، سجل الدخول؛ تسجيل خروج هاتف مفقود';

  @override
  String get devicesHint =>
      'كل هاتف سجّل الدخول إلى هذا الحساب. تسجيل خروج هاتف ينهيه فورًا، ويلزم كلمة المرور لاستخدامه مجددًا.';

  @override
  String get devicesEmpty =>
      'لا توجد أجهزة بعد. تظهر الهواتف بعد تسجيل الدخول بسدرة 2.28 أو أحدث.';

  @override
  String get devicesEndAll => 'خروج من كل الأجهزة';

  @override
  String get devicesEndAllBody =>
      'يُسجَّل خروج كل هاتف في هذا الحساب فورًا. تلزم كلمة المرور لتسجيل الدخول مجددًا.';

  @override
  String devicesEndAllDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم تسجيل خروج $n هواتف',
      one: 'تم تسجيل خروج هاتف واحد',
      zero: 'لم يكن أي هاتف مسجلًا',
    );
    return '$_temp0';
  }

  @override
  String get deviceThis => 'هذا الهاتف';

  @override
  String get deviceUnknown => 'هاتف غير معروف';

  @override
  String deviceApp(String version, String build) {
    return 'سدرة $version (بناء $build)';
  }

  @override
  String deviceAndroid(String version, String sdk) {
    return 'أندرويد $version (API $sdk)';
  }

  @override
  String deviceNetwork(String network) {
    return 'الشبكة: $network';
  }

  @override
  String get deviceNotificationsOff => 'الإشعارات محظورة';

  @override
  String get deviceMicOff => 'الميكروفون غير مسموح';

  @override
  String deviceLastSync(String when) {
    return 'آخر مزامنة $when';
  }

  @override
  String deviceFirstSeen(String when) {
    return 'أول ظهور $when';
  }

  @override
  String get deviceRevoke => 'تسجيل خروج هذا الهاتف';

  @override
  String get deviceRevokeTitle => 'تسجيل خروج هذا الهاتف؟';

  @override
  String get deviceRevokeBody =>
      'يتوقف فورًا ويحتاج كلمة المرور لتسجيل الدخول مجددًا. استخدم هذا لهاتف مفقود أو مسروق.';

  @override
  String get deviceRevokeReason => 'السبب (اختياري)';

  @override
  String deviceRevokedBy(String name, String when, String reason) {
    return 'سجّل خروجه $name $when. $reason';
  }

  @override
  String get authHistoryTitle => 'سجل تسجيل الدخول';

  @override
  String get authEventSignIn => 'تسجيل دخول';

  @override
  String get authEventSignedUp => 'إنشاء الحساب';

  @override
  String get authEventFailed => 'كلمة مرور خاطئة';

  @override
  String get authEventLocked => 'محاولة أثناء القفل';

  @override
  String get authEventDisabled => 'محاولة والحساب معطّل';

  @override
  String get authEventSignOut => 'تسجيل خروج';

  @override
  String get authEventRefreshRejected =>
      'استُخدم تسجيل دخول منتهٍ مجددًا (مرفوض)';

  @override
  String get authEventDeviceRevoked => 'تم تسجيل خروج هاتف';

  @override
  String get authEventSessionsEnded => 'خروج من كل الأجهزة';

  @override
  String get authEventPasswordChanged => 'تغيير كلمة المرور';

  @override
  String get issueReport => 'لدي مشكلة في هذا العمل';

  @override
  String get issueReportHint =>
      'أخبر معلمك بما يمنعك. ينتظر الموعد النهائي ما دام بلاغك مفتوحًا.';

  @override
  String get issueDontUnderstand => 'لا أفهم العمل';

  @override
  String get issueClarification => 'أحتاج توضيحًا';

  @override
  String get issueMoreTime => 'أحتاج وقتًا إضافيًا';

  @override
  String get issueUnavailable => 'أنا مريض أو غير متاح';

  @override
  String get issueTechnical => 'مشكلة تقنية';

  @override
  String get issueCannotAccess => 'لا أستطيع فتح المادة';

  @override
  String get issueCannotRecord => 'لا أستطيع تسجيل الصوت';

  @override
  String get issueCannotUpload => 'لا أستطيع الرفع';

  @override
  String get issueOther => 'شيء آخر';

  @override
  String get issueMessage => 'اشرح (اختياري)';

  @override
  String get issueAttach => 'إرفاق';

  @override
  String get issueAttachHint => 'أضف صورة أو تسجيلًا أو ملفًا إن كان مفيدًا';

  @override
  String get issueSend => 'أرسل إلى معلمي';

  @override
  String get issueSent => 'تم الإرسال. سيجيب معلمك هنا.';

  @override
  String get issueSentTitle => 'تم الإبلاغ عن المشكلة: بانتظار معلمك';

  @override
  String get issueAnsweredTitle => 'أجاب معلمك';

  @override
  String issueNewDue(String when) {
    return 'الموعد الجديد: $when';
  }

  @override
  String get issuesTitle => 'بلاغات المشكلات';

  @override
  String get issuesOpen => 'مفتوحة';

  @override
  String get issuesResolved => 'محلولة';

  @override
  String get issuesNone => 'لا توجد بلاغات';

  @override
  String issuesWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n متعلمين أبلغوا عن مشكلات',
      one: 'متعلم واحد أبلغ عن مشكلة',
    );
    return '$_temp0';
  }

  @override
  String get issueOpenAttachment => 'فتح المرفق';

  @override
  String get issueRespond => 'الرد';

  @override
  String get issueYourAnswer => 'ردك';

  @override
  String get issueGiveMoreTime => 'امنح وقتًا إضافيًا (اختياري)';

  @override
  String get issueMarkResolved => 'وضع علامة محلول';

  @override
  String get issueSendAnswer => 'إرسال الرد';

  @override
  String get lateWorkTitle => 'الأعمال المتأخرة';

  @override
  String get lateWorkHint =>
      'تُنشأ تلقائيًا وفق سياسات المتعلمين في الإعدادات. تسليم العمل يغلقها.';

  @override
  String get lateWorkNone => 'لا أحد متأخر';

  @override
  String lateWorkCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n تنبيهات تأخير',
      one: 'تنبيه تأخير واحد',
    );
    return '$_temp0';
  }

  @override
  String lateWorkHours(int n) {
    return 'متأخر $n ساعة';
  }

  @override
  String get lateWorkReinstate => 'إعادة التفعيل';

  @override
  String get lateWorkRunNow => 'افحص الآن';

  @override
  String get policyNotOpened => 'لم يفتح العمل';

  @override
  String get policyNotSubmitted => 'فتحه ولم يسلّمه';

  @override
  String get policyOverdue => 'متأخر';

  @override
  String get policyEscalated => 'رُفع إلى الإدارة';

  @override
  String get policySuspended => 'موقوف عن الدورة';

  @override
  String get policyInactive => 'لا يستخدم سدرة';

  @override
  String get policyReinstated => 'أعيد تفعيله';

  @override
  String get policyTitle => 'سياسات المتعلمين';

  @override
  String get policyHint =>
      'التذكيرات وقواعد التأخير. تُحسب الأوقات من الموعد؛ ويوقفها البلاغ ويؤجلها تمديد المعلم.';

  @override
  String get policyEnabled => 'إرسال التذكيرات وتنبيهات التأخير';

  @override
  String get policyWarnHours => 'ذكّر المتعلم بعد (ساعات تأخير)';

  @override
  String get policyWarnHoursHint => 'يخبره إن لم يفتح العمل أو لم يسلّمه.';

  @override
  String get policyOverdueHours => 'أخبر المعلم بعد (ساعات تأخير)';

  @override
  String get policyEscalateDays => 'أخبر الإدارة بعد (أيام تأخير)';

  @override
  String get policyGraceHours => 'مهلة سماح (ساعات)';

  @override
  String get policyReminderHours => 'كرر التذكير كل (ساعات)';

  @override
  String get policyCountWeekends => 'احتساب عطلة نهاية الأسبوع';

  @override
  String get policyCountWeekendsHint =>
      'عند الإيقاف لا يُحتسب السبت والأحد. العطل لا تُحتسب أبدًا.';

  @override
  String get policyInactiveDays => 'غير نشط بعد (أيام دون استخدام سدرة)';

  @override
  String get policyInactiveDaysHint =>
      'منفصل عن التأخير: يتلقى المتعلم تذكيرًا لطيفًا.';

  @override
  String get policyAutoSuspend => 'إيقاف تلقائي';

  @override
  String get policyAutoSuspendHint =>
      'مُعطّل افتراضيًا. فقط بعد تحذير قبل يوم على الأقل، ولا يحدث مع بلاغ مفتوح أو تمديد، وفقط إن استخدم المتعلم سدرة بعد إعطاء العمل. يُحفظ العمل والتقدم.';

  @override
  String get policySuspendDays => 'الإيقاف بعد (أيام تأخير)';

  @override
  String get policyPaymentDays =>
      'متابعة مدفوعات المحمول غير المُجابة لمدة (أيام)';

  @override
  String get policyPaymentDaysHint =>
      'بعدها تُعدّ الدفعة التي لم تُجب عنها MarzPay فاشلة.';

  @override
  String get policyRunning => 'السياسات تعمل.';

  @override
  String policyPausedUntil(String when) {
    return 'متوقفة حتى $when';
  }

  @override
  String policyLastRun(String when) {
    return 'آخر فحص $when';
  }

  @override
  String get policyResume => 'استئناف الآن';

  @override
  String policyPauseDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'إيقاف $n أيام',
      one: 'إيقاف ليوم',
    );
    return '$_temp0';
  }

  @override
  String get holidaysTitle => 'العطل';

  @override
  String get holidaysHint => 'أيام لا تُحتسب في المواعيد';

  @override
  String get holidaysAdd => 'إضافة عطلة';

  @override
  String get holidaysName => 'الاسم (مثل عيد الفطر)';

  @override
  String get holidaysNone => 'لا توجد عطل';

  @override
  String get transferChannel => 'الرفع والتنزيل';

  @override
  String get transferChannelHint => 'تقدم الرفع والتنزيل';

  @override
  String get uploadingWork => 'جارٍ رفع عملك';

  @override
  String get uploadDoneTitle => 'تم إرسال العمل';

  @override
  String get uploadDoneBody => 'استلمه معلمك.';

  @override
  String get uploadWaitingTitle => 'تم حفظ العمل: بانتظار الإنترنت';

  @override
  String get uploadWaitingBody => 'سيُرسل عند عودة الاتصال.';

  @override
  String get uploadFailedTitle => 'فشل الرفع';

  @override
  String get uploadFailedBody =>
      'عملك محفوظ على الهاتف. افتح سدرة لتحاول مجددًا.';

  @override
  String uploadFileMissing(String name) {
    return '$name لم يعد على هذا الهاتف. احذفه وأضفه مجددًا.';
  }

  @override
  String get chatsTitle => 'الرسائل';

  @override
  String get chatsEmpty => 'لا توجد محادثات بعد';

  @override
  String get chatsEmptyHint => 'ابدأ محادثة مع زميل، أو أنشئ مجموعة لفريقك.';

  @override
  String get chatNew => 'محادثة جديدة';

  @override
  String get chatNewGroup => 'مجموعة جديدة';

  @override
  String get chatGroupName => 'اسم المجموعة';

  @override
  String get chatGroupNameNeeded => 'أعط المجموعة اسمًا';

  @override
  String get chatCreateGroup => 'إنشاء المجموعة';

  @override
  String get chatAddPeople => 'إضافة أشخاص';

  @override
  String chatMembers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n أعضاء',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String get chatGroupAdmin => 'مشرف المجموعة';

  @override
  String get chatRemove => 'إزالة';

  @override
  String get chatLeave => 'مغادرة المجموعة';

  @override
  String get chatMute => 'كتم الإشعارات';

  @override
  String get chatMessageHint => 'رسالة';

  @override
  String get chatSend => 'إرسال';

  @override
  String get chatAttach => 'إرفاق';

  @override
  String get chatAttachment => 'مرفق';

  @override
  String get chatPhoto => 'صورة';

  @override
  String get chatVideo => 'فيديو';

  @override
  String get chatAudio => 'صوت';

  @override
  String get chatFile => 'ملف';

  @override
  String get chatVoiceNote => 'رسالة صوتية';

  @override
  String get chatRecording => 'جارٍ التسجيل';

  @override
  String get chatMicNeeded =>
      'اسمح لسدرة باستخدام الميكروفون لإرسال الرسائل الصوتية.';

  @override
  String get chatReply => 'رد';

  @override
  String get chatCopy => 'نسخ';

  @override
  String get chatDeleteForAll => 'حذف لدى الجميع';

  @override
  String get chatDeleted => 'تم حذف هذه الرسالة';

  @override
  String get chatNotSent => 'لم تُرسل. اضغط لإعادة المحاولة';

  @override
  String get chatToday => 'اليوم';

  @override
  String get chatYesterday => 'أمس';

  @override
  String get photoEditTitle => 'ضبط الصورة';

  @override
  String get photoEditHint => 'قرّب بإصبعين واسحب لوضع وجهك داخل الدائرة.';

  @override
  String get photoRotate => 'تدوير';

  @override
  String get photoReset => 'إعادة الضبط';

  @override
  String get photoUse => 'استخدام الصورة';

  @override
  String get photoView => 'عرض الصورة';

  @override
  String dashSignedInAs(String name, String role) {
    return 'مسجّل الدخول باسم $name · $role';
  }

  @override
  String dashOrgTitle(String org) {
    return '$org في لمحة';
  }

  @override
  String get dashOrgHint =>
      'أرقام المؤسسة كلها، لا أرقامك أنت. اضغط أي رقم لترى بالضبط من أو ماذا يعدّ.';

  @override
  String get dashThisWeek => 'هذا الأسبوع';

  @override
  String get dashPeople => 'الأشخاص';

  @override
  String get dashCourses => 'الدورات';

  @override
  String get dashLearnersInCourses => 'متعلمون في دورات';

  @override
  String get dashCoursePlaces => 'مقاعد الدورات (متعلم في 3 دورات = 3)';

  @override
  String get dashListEmpty => 'لا شيء هنا';

  @override
  String dashListCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n في هذه القائمة',
      one: 'واحد في هذه القائمة',
    );
    return '$_temp0';
  }

  @override
  String get dashLearnersGlance => 'المتعلمون في لمحة';

  @override
  String dashSeeAll(int n) {
    return 'عرض الكل ($n)';
  }

  @override
  String get dashGlanceUnavailable => 'لا يمكنك رؤية المتعلمين بدورك الحالي.';

  @override
  String get dashNoCourses => 'ليس في أي دورة';

  @override
  String get dashNeverUsed => 'لم يستخدم سدرة بعد';

  @override
  String dashLastUsed(String when) {
    return 'آخر استخدام لسدرة $when';
  }

  @override
  String dashLateWork(int n) {
    return '$n متأخر';
  }

  @override
  String dashOpenReports(int n) {
    return '$n بلاغ مشكلة';
  }

  @override
  String get ccGeneral => 'عام';

  @override
  String get ccGeneralHint =>
      'اسم المؤسسة والمنطقة الزمنية ووسائل الاتصال والمراسلة.';

  @override
  String get ccAccess => 'المستخدمون والدخول';

  @override
  String get ccAccessHint =>
      'من يمكنه التسجيل، قواعد كلمة المرور، القفل وحماية تسجيل الدخول.';

  @override
  String get ccTeaching => 'التدريس';

  @override
  String get ccSecurity => 'الأجهزة والأمان';

  @override
  String get ccSecurityHint =>
      'الهواتف المسجلة والجلسات ومحاولات الدخول الفاشلة وتسجيلات الخروج.';

  @override
  String get ccPaymentsHint => 'طرق الدفع وتعليمات الدفع اليدوي وتتبّع دفعة.';

  @override
  String get ccMarzpayHint =>
      'المال عبر الهاتف من خلال MarzPay: حالته الحقيقية ومركز الاختبار وحدود الأمان.';

  @override
  String get ccStorage => 'التخزين والوسائط';

  @override
  String get ccStorageHint =>
      'مكان حفظ الملفات (Cloudinary) وحد الرفع وفحوص التخزين.';

  @override
  String get ccDatabase => 'قاعدة البيانات';

  @override
  String get ccDatabaseHint =>
      'الاتصال وإصدار المخطط. تغييرات البنية تتم عبر عملية الإصدار، لا هنا.';

  @override
  String get ccSync => 'العمل دون اتصال والمزامنة';

  @override
  String get ccSyncHint => 'العمل المحفوظ على هذا الهاتف والذي ينتظر الإرسال.';

  @override
  String get ccAudit => 'السجل والتدقيق';

  @override
  String get ccAuditHint => 'من غيّر أي إعداد ومتى ولماذا؛ تصدير البيانات.';

  @override
  String get ccApplication => 'التطبيق';

  @override
  String get ccAdvanced => 'التشخيص';

  @override
  String get ccAdvancedHint => 'شغّل الفحوص عند حدوث عطل، مع سجل للنتائج.';

  @override
  String get ccTimeZone => 'المنطقة الزمنية (مثل Africa/Kampala)';

  @override
  String get ccTimeZoneHint => 'تُستخدم للمواعيد وعطلات نهاية الأسبوع والعطل.';

  @override
  String get ccMessagingOn => 'المراسلة للموظفين';

  @override
  String get ccMessagingLearners => 'يمكن للمتعلمين استخدام المراسلة أيضًا';

  @override
  String get ccSigninBrake => 'مكبح عام: محاولات دخول فاشلة في الدقيقة';

  @override
  String get ccSigninBrakeHint =>
      'فوق هذا الحد يجيب تسجيل الدخول «حاول لاحقًا» لمدة دقيقة (يوقف تخمين حسابات كثيرة).';

  @override
  String get ccPresenceMinutes => '«متصل» يعني ظهر خلال (دقائق)';

  @override
  String get ccAuthKeepDays => 'الاحتفاظ بسجل الدخول لمدة (أيام)';

  @override
  String get ccDefaultPassMark => 'درجة النجاح للدورات الجديدة (%)';

  @override
  String get ccMarzTestsOn => 'اختبارات MarzPay مسموحة (إيقاف طارئ)';

  @override
  String get ccMarzTestsOnHint =>
      'الإيقاف يوقف كل الاختبارات فورًا، ومنها المنتظرة.';

  @override
  String get ccMarzTestMax => 'أكبر مبلغ للاختبار (شلن)';

  @override
  String get ccMarzDisbursementOn => 'السماح باختبارات إرسال المال';

  @override
  String get ccMarzDisbursementOnHint =>
      'يخرج المال من محفظة MarzPay. مُعطّل افتراضيًا.';

  @override
  String get ccUploadMax => 'أكبر ملف للرفع (ميغابايت)';

  @override
  String get ccUploadMaxHint =>
      'ترفض الهواتف الملفات الأكبر قبل الإرسال. ويُطبّق أيضًا حد خطة Cloudinary.';

  @override
  String get ccSendTestNotification => 'أرسل لي إشعارًا تجريبيًا';

  @override
  String get ccPaymentTrace => 'تتبّع دفعة';

  @override
  String get ccMarzCenter => 'مركز اختبار MarzPay';

  @override
  String get ccDiagnostics => 'التشخيص';

  @override
  String get ccSettingsHistory => 'سجل الإعدادات';

  @override
  String get ccSecurityEvents => 'أحداث الأمان';

  @override
  String get ccOk => 'سليم';

  @override
  String get ccWarning => 'انتباه';

  @override
  String get ccFailed => 'فشل';

  @override
  String get ccUntested => 'لم يُختبر';

  @override
  String get ccDisabled => 'متوقف';

  @override
  String get ccSearchHint =>
      'ابحث في الإعدادات: كلمة المرور، الدفع، الإشعارات…';

  @override
  String get ccHealthTitle => 'هل سدرة سليمة الآن؟';

  @override
  String get ccHealthHint => 'الحالة الحية لكل جزء. اضغط أحدها للتفاصيل.';

  @override
  String get ccHealthNoPermission => 'لا يمكن لدورك رؤية حالة النظام.';

  @override
  String get ccSections => 'الأقسام';

  @override
  String get ccMarzDisabled => 'أوقفه مسؤول';

  @override
  String get ccMarzConnFailed => 'فشل آخر اختبار اتصال';

  @override
  String get ccMarzServerDown =>
      'خادم المدفوعات متوقف: لا يمكن إرسال المدفوعات';

  @override
  String get ccMarzVerified => 'مُتحقَّق: جُمع مال فعلًا عبر سدرة';

  @override
  String get ccMarzAuthOnly => 'متصل ومعتمد؛ لم يُثبت تحصيل حقيقي بعد';

  @override
  String get ccMarzUntested => 'لم يُختبر بعد';

  @override
  String ccDbLine(String have, String expected) {
    return 'المخطط $have (يتوقع هذا التطبيق $expected)';
  }

  @override
  String get ccPaymentsServer => 'خادم المدفوعات';

  @override
  String ccServerOnline(Object version) {
    return 'متصل (الإصدار $version)';
  }

  @override
  String get ccServerNever => 'لم يظهر أبدًا: لا يعمل في أي مكان';

  @override
  String ccServerLastSeen(String when) {
    return 'متوقف، آخر ظهور $when';
  }

  @override
  String ccStorageLine(Object n, String when) {
    return '$n عمليات رفع اليوم؛ آخرها $when';
  }

  @override
  String get ccStorageMissing => 'مفاتيح Cloudinary غير موجودة: سيفشل الرفع';

  @override
  String ccNotifLine(Object sent, Object phones, Object blocked) {
    return '$sent أُرسلت اليوم · $phones هواتف مسجلة · $blocked هواتف تحظر الإشعارات';
  }

  @override
  String ccSecurityLine(Object failed, Object locked, Object many) {
    return '$failed محاولات دخول فاشلة اليوم · $locked مقفل · $many حسابات على هواتف كثيرة';
  }

  @override
  String get ccLearning => 'التعلم';

  @override
  String ccLearningLine(
    Object active,
    Object reports,
    Object late,
    Object review,
  ) {
    return '$active نشط هذا الأسبوع · $reports بلاغات · $late متأخر · $review تنتظر المراجعة منذ يومين+';
  }

  @override
  String ccPaymentsLine(Object manual, Object stuck) {
    return '$manual مدفوعات يدوية للتحقق · $stuck مدفوعات هاتف عالقة';
  }

  @override
  String ccAppLine(String version, String build, Object latest) {
    return 'هذا الهاتف $version ($build) · أحدث بناء $latest';
  }

  @override
  String ccDiagLine(Object n) {
    return '$n فحوص فاشلة في آخر يوم';
  }

  @override
  String ccCheckedAt(String when) {
    return 'فُحص $when';
  }

  @override
  String ccSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حُفظت $n إعدادات',
      one: 'حُفظ إعداد واحد',
    );
    return '$_temp0';
  }

  @override
  String ccSavedSome(int ok, int failed) {
    return '$ok حُفظ، $failed رُفض: انظر الرسائل الحمراء';
  }

  @override
  String get ccReason => 'سبب التغيير (يُسجَّل)';

  @override
  String ccSaveChanges(int n) {
    return 'حفظ $n';
  }

  @override
  String ccRange(int min, int max) {
    return 'بين $min و$max.';
  }

  @override
  String ccLastChanged(String name, String when) {
    return 'آخر تغيير بواسطة $name، $when';
  }

  @override
  String get ccSystem => 'النظام';

  @override
  String get ccYes => 'نعم';

  @override
  String get ccNo => 'لا';

  @override
  String get ccDbConnected => 'متصل';

  @override
  String get ccDbLatest => 'أحدث تغيير مطبّق';

  @override
  String get ccDbAppExpects => 'يتوقع هذا التطبيق';

  @override
  String get ccDbCount => 'التغييرات المطبقة';

  @override
  String get ccDbBackups => 'النسخ الاحتياطية';

  @override
  String get ccDbBackupsHint =>
      'تحفظها Neon (راجع لوحتها؛ الخطط المدفوعة تستعيد لأي لحظة)';

  @override
  String get ccStorageProvider => 'المزوّد';

  @override
  String get ccConfigured => 'مُهيّأ';

  @override
  String get ccLastUpload => 'آخر رفع';

  @override
  String get ccUploads24h => 'عمليات الرفع اليوم';

  @override
  String get ccPurgeWaiting => 'ملفات تنتظر الحذف';

  @override
  String get ccPublicAddress => 'عنوان عام للردود';

  @override
  String get ccNoPollingOnly => 'لا (تُفحص المدفوعات كل 20 ثانية)';

  @override
  String get ccVerifiedPayments => 'مدفوعات هاتف مُتحقّقة';

  @override
  String get ccStuckPayments => 'عالقة لأكثر من ساعة';

  @override
  String get ccThisPhone => 'هذا الهاتف';

  @override
  String get ccBuildsInUse => 'الإصدارات المستخدمة (البناء: الهواتف)';

  @override
  String get ccFailedSignIns => 'محاولات دخول فاشلة (24 ساعة)';

  @override
  String get ccThrottled => 'تفعيل المكبح (24 ساعة)';

  @override
  String get ccLockedNow => 'حسابات مقفلة الآن';

  @override
  String get ccRevoked7d => 'هواتف أخرجها المسؤولون (7 أيام)';

  @override
  String get ccManyDevices => 'حسابات مسجلة على أكثر من 3 هواتف';

  @override
  String get ccSyncThisPhone => 'على هذا الهاتف';

  @override
  String ccSyncLine(int pending, int rejected, int queued) {
    return '$pending تغييرات تقدم تنتظر · $rejected مرفوضة · $queued تسليمات في الطابور';
  }

  @override
  String get ccSyncNow => 'أرسل الآن';

  @override
  String get ccHistoryHint =>
      'كل تغيير في إعداد: القيمة القديمة والجديدة ومن ومتى ولماذا. اضغط أحدها لرؤيته وحده.';

  @override
  String get ccNoSecurityEvents => 'لا توجد أحداث أمان';

  @override
  String get ccUnknownAccount => 'رقم غير معروف (بلا حساب)';

  @override
  String get ccTraceHint =>
      'ابحث باسم المتعلم أو هاتفه أو معرّف الدفعة في سدرة أو معرّف MarzPay أو المرجع. كل نتيجة تتبّع الدفعة من الطلب إلى MarzPay إلى سجل سدرة.';

  @override
  String get ccTraceSearch => 'الاسم أو الهاتف أو المعرّف أو المرجع';

  @override
  String get ccTraceNone => 'لا توجد دفعة مطابقة';

  @override
  String get ccTraceStep1 => '1 · الطلب في سدرة';

  @override
  String get ccTraceStep2 => '2 · لدى MarzPay';

  @override
  String get ccTraceStep3 => '3 · الردود المستلمة';

  @override
  String get ccTraceStep4 => '4 · سجل سدرة والوصول';

  @override
  String get ccTraceMethod => 'الطريقة';

  @override
  String get ccTraceCreated => 'أُنشئت';

  @override
  String get ccTraceSidraId => 'معرّف سدرة';

  @override
  String get ccTraceReference => 'المرجع';

  @override
  String get ccTraceProviderId => 'معرّف MarzPay';

  @override
  String get ccTraceProviderStatus => 'آخر رد من MarzPay';

  @override
  String get ccTraceAttempts => 'محاولات الإرسال';

  @override
  String get ccTraceCallbacks => 'الردود';

  @override
  String get ccTraceNoCallbacks => 'لا شيء (يُفحص بالاستعلام الدوري)';

  @override
  String get ccTraceSidraStatus => 'حالة سدرة';

  @override
  String get ccTraceVerifiedAt => 'تم التحقق';

  @override
  String get ccTraceBalance => 'المتبقي';

  @override
  String get ccTraceOutstanding => 'مستحق';

  @override
  String get ccTraceEnrolment => 'الوصول إلى الدورة';

  @override
  String get ccTraceHistory => 'التغييرات';

  @override
  String get ccTraceAskMarzPay => 'اسأل MarzPay الآن';

  @override
  String get ccDiagnosticsHint =>
      'كل فحص يبيّن ما اختبره وما ينبغي أن يحدث وما حدث وما العمل التالي. تُحفظ النتائج.';

  @override
  String get ccRunAll => 'شغّل كل الفحوص';

  @override
  String get ccRunCheck => 'شغّل الفحص';

  @override
  String get ccTested => 'ما اختُبر';

  @override
  String get ccExpected => 'المتوقع';

  @override
  String get ccHappened => 'ما حدث';

  @override
  String get ccNextAction => 'التالي';

  @override
  String get ccDiagHistory => 'نتائج سابقة';

  @override
  String get ccSafetySettings => 'إعدادات الأمان';

  @override
  String get diagDbTested => 'رحلة ذهاب وإياب إلى قاعدة البيانات من هذا الهاتف';

  @override
  String get diagDbExpected => 'إجابة خلال ثوانٍ';

  @override
  String diagDbHappened(int ms) {
    return 'أجابت خلال $ms مللي ثانية';
  }

  @override
  String get diagSession => 'جلسة الدخول';

  @override
  String get diagSessionTested => 'تجديد جلسة هذا الهاتف';

  @override
  String get diagSessionExpected => 'جلسة جديدة';

  @override
  String get diagSessionOk => 'جُددت الجلسة';

  @override
  String get diagSessionNone => 'لا جلسة: هذا الهاتف غير مسجّل';

  @override
  String get diagDevice => 'هذا الهاتف';

  @override
  String get diagDeviceTested => 'التسجيل والأذونات وإصدار التطبيق';

  @override
  String get diagDeviceExpected => 'مسجّل مع السماح بالإشعارات والميكروفون';

  @override
  String diagDeviceLinked(String model, String version) {
    return 'مسجّل باسم $model، سدرة $version';
  }

  @override
  String get diagDeviceNotLinked =>
      'غير مرتبط بهذه الجلسة بعد (اخرج وادخل مرة)';

  @override
  String get diagStorageTested => 'رفع ملف صغير إلى Cloudinary ثم تنزيله';

  @override
  String get diagStorageExpected => 'يعود المحتوى نفسه';

  @override
  String get diagStorageOk => 'رُفع ووُقّع ونُزّل سليمًا';

  @override
  String get diagStorageMismatch => 'الملف المنزّل يختلف عن المرفوع';

  @override
  String get diagNotifTested => 'إنشاء إشعار لك';

  @override
  String get diagNotifExpected => 'يظهر في التطبيق وفي شريط الإشعارات';

  @override
  String get diagNotifSent => 'أُنشئ';

  @override
  String get diagNotifNext =>
      'يجب أن يظهر في شريط الإشعارات خلال دقيقة وسدرة مفتوحة (15 دقيقة إن كانت مغلقة). وإلا فتحقق من إذن الإشعارات.';

  @override
  String get diagSyncTested => 'العمل المنتظر على هذا الهاتف';

  @override
  String get diagSyncExpected => 'لا شيء عالق';

  @override
  String get diagServerTested => 'نبض خادم المدفوعات';

  @override
  String get diagServerExpected => 'ظهر خلال آخر 90 ثانية';

  @override
  String get diagMarzTested => 'حالة MarzPay من أحدث الاختبارات';

  @override
  String get diagMarzExpected => 'متصل مع تحصيل حقيقي مُثبت';

  @override
  String get diagAppTested => 'بناء هذا التطبيق مقابل أحدث منشور';

  @override
  String get diagAppExpected => 'أحدث بناء';

  @override
  String diagAppCurrent(String version, String build) {
    return 'محدّث: $version ($build)';
  }

  @override
  String diagAppOld(String build, int latest) {
    return 'البناء $build، الأحدث $latest';
  }

  @override
  String get diagNextCheckNetwork =>
      'تحقق من إنترنت هذا الهاتف ثم أعد التشغيل.';

  @override
  String get diagNextSignIn => 'سجّل الدخول مجددًا.';

  @override
  String get diagNextPermissions =>
      'اسمح بها من إعدادات الهاتف ← التطبيقات ← سدرة.';

  @override
  String get diagNextStorage =>
      'تحقق من حالة Cloudinary وحدود الخطة؛ واسأل المطوّر إن استمر.';

  @override
  String get diagNextSync =>
      'افتح «العمل دون اتصال والمزامنة» وأعد محاولة العناصر الفاشلة.';

  @override
  String get diagNextServer =>
      'شغّل خادم المدفوعات على مضيفه (انظر docs/OPERATIONS.md). وحتى ذلك تنتظر مدفوعات الهاتف.';

  @override
  String get diagNextMarz => 'افتح مركز اختبار MarzPay وشغّل اختبار الاتصال.';

  @override
  String get diagNextUpdate => 'ثبّت أحدث نسخة.';

  @override
  String get mcConnection => 'الاتصال';

  @override
  String get mcConnectionHint =>
      'الشبكة وTLS وبيانات الاعتماد والحساب والبيئة وزمن الاستجابة.';

  @override
  String get mcCapabilities => 'ما يقدمه MarzPay لهذا الحساب';

  @override
  String get mcCapabilitiesHint =>
      'يقرأ خدمات التحصيل والصرف والوصول إلى الرصيد والردود.';

  @override
  String get mcBalance => 'الرصيد';

  @override
  String get mcBalanceHint => 'رصيد محفظة MarzPay.';

  @override
  String get mcCollection => 'التحصيل (استلام مال)';

  @override
  String get mcCollectionHint =>
      'طلب حقيقي على هاتف؛ يُثبت من دفتر MarzPay نفسه.';

  @override
  String get mcDisbursement => 'الصرف (إرسال مال)';

  @override
  String get mcDisbursementHint =>
      'يخرج المال من المحفظة إلى هاتف. مُعطّل حتى يُفعّل.';

  @override
  String get mcLookup => 'البحث عن معاملة';

  @override
  String get mcLookupHint => 'قارن سجل سدرة مع سجل MarzPay لدفعة واحدة.';

  @override
  String get mcLookupField => 'معرّف سدرة أو MarzPay أو المرجع';

  @override
  String get mcCallbacks => 'الردود';

  @override
  String get mcCallbacksHint => 'هل يستطيع MarzPay إبلاغ سدرة؟ يعرض ما وصل.';

  @override
  String get mcReconciliation => 'المطابقة';

  @override
  String get mcReconciliationHint =>
      'كل مدفوعات الهاتف في سدرة (30 يومًا) مقابل دفتر MarzPay.';

  @override
  String get mcAuthentication => 'الاعتماد';

  @override
  String get mcCollectionMm => 'تحصيل عبر الهاتف (MTN وAirtel)';

  @override
  String get mcCard => 'الدفع بالبطاقة';

  @override
  String get mcDisbursementMm => 'صرف عبر الهاتف';

  @override
  String get mcBank => 'تحويل بنكي';

  @override
  String get mcWallet => 'من حساب إلى حساب (تحويل محفظة)';

  @override
  String get mcRefund => 'استرداد / عكس';

  @override
  String get mcMatrix => 'القدرات';

  @override
  String get mcMatrixHint =>
      'المزوّد: يقدمه MarzPay لهذا الحساب. سدرة: مبني في سدرة. تُظهر الشارة أحدث دليل.';

  @override
  String get mcProvider => 'MarzPay';

  @override
  String get mcSidra => 'سدرة';

  @override
  String get mcUnsupportedByProvider => 'لا يقدمه MarzPay';

  @override
  String get mcRunCapabilities => 'شغّل اختبار القدرات';

  @override
  String get mcSidraMissing => 'يقدمه MarzPay؛ لم تستخدمه سدرة بعد';

  @override
  String get mcImplementedUntested => 'مبني، لم يُختبر بعد';

  @override
  String get mcImplementedBlocked => 'مبني؛ التحقق محجوب';

  @override
  String get mcVerified => 'مُتحقّق';

  @override
  String get mcAccepted => 'مقبول، غير مُثبت';

  @override
  String get mcFailedR => 'فشل';

  @override
  String get mcCancelled => 'أُلغي';

  @override
  String get mcPending => 'قيد الانتظار';

  @override
  String get mcUnknown => 'غير معروف';

  @override
  String get mcBlocked => 'محجوب';

  @override
  String get mcUnsupported => 'غير مدعوم';

  @override
  String get mcRunning => 'قيد التشغيل…';

  @override
  String get mcRealMoney => 'مال حقيقي';

  @override
  String get mcLast => 'الأخير';

  @override
  String get mcIntro =>
      'تعمل الاختبارات على خادم المدفوعات (المكان الوحيد الذي يحمل مفاتيح MarzPay). ينتهي كل منها بدليل أو بسبب صادق. فتح هذه الصفحة لا يبدأ أي اختبار.';

  @override
  String get mcWhatTesting => 'ماذا تختبر؟';

  @override
  String get mcTestTab => 'اختبار';

  @override
  String get mcHistoryTab => 'السجل';

  @override
  String get mcCallbacksList =>
      'كل اتصال أجراه MarzPay بسدرة وما فعلته سدرة به.';

  @override
  String get mcNoCallbacks => 'لم تصل ردود بعد';

  @override
  String get mcDuplicate => 'مكرر';

  @override
  String get mcNoTests => 'لا توجد اختبارات بعد';

  @override
  String get mcRunTest => 'شغّل الاختبار';

  @override
  String get mcFormInvalid => 'أدخل رقم MTN أو Airtel أوغندي ومبلغًا.';

  @override
  String get mcRealTitle => 'هذا ينقل مالًا حقيقيًا';

  @override
  String mcRealCollect(int amount, String phone) {
    return 'سيُطلب $amount شلن من $phone. يجب أن يُدخل صاحب الهاتف رقمه السري. يذهب المال إلى محفظة MarzPay.';
  }

  @override
  String mcRealSend(int amount, String phone) {
    return 'سيُرسل $amount شلن من محفظة MarzPay إلى $phone. لا يمكن لسدرة التراجع عنه.';
  }

  @override
  String get mcContinue => 'متابعة';

  @override
  String get mcTypeToConfirm => 'اكتب هذا تمامًا للتأكيد';

  @override
  String get mcCollectWarning =>
      'سيظهر طلب دفع حقيقي على الهاتف الذي تُدخله. استخدم هاتفك وأصغر مبلغ.';

  @override
  String get mcSendWarning =>
      'سيخرج مال حقيقي من محفظة MarzPay. ينبغي أن يؤكد المستلم الاستلام.';

  @override
  String get mcPayerPhone => 'هاتف الدافع (MTN أو Airtel)';

  @override
  String get mcRecipientPhone => 'هاتف المستلم (MTN أو Airtel)';

  @override
  String get mcAmount => 'المبلغ (شلن)';

  @override
  String get mcAmountHint => '500 على الأقل؛ وبحد أقصى ما في إعدادات الأمان.';

  @override
  String get mcDescription => 'ملاحظة (اختياري)';

  @override
  String get mcStartCollection => 'اطلب الدفعة';

  @override
  String get mcStartDisbursement => 'أرسل المال';

  @override
  String get mcQueuedLong =>
      'ما زال ينتظر: قد يكون خادم المدفوعات متوقفًا. يبدأ الاختبار فور تشغيله.';

  @override
  String get mcEvidence => 'الدليل';

  @override
  String get mcEnvironment => 'البيئة';

  @override
  String get ccMarzSelfChecks =>
      'فحوص ذاتية للتكامل (التكرار، المهلات، التحقق)';

  @override
  String get issuesMine => 'بلاغاتي عن المشكلات';

  @override
  String get issuesMineHint => 'المشكلات التي أبلغت عنها وردود معلميك';

  @override
  String get issuesMineEmpty =>
      'للإبلاغ عن مشكلة، افتح الدرس أو العمل واضغط \"الإبلاغ عن مشكلة\".';

  @override
  String get contactsImportTitle => 'الاستيراد من جهات الاتصال';

  @override
  String get contactsImportHint => 'اختر عدة متعلمين من هذا الهاتف دفعة واحدة';

  @override
  String get contactsAddOne => 'إضافة شخص واحد';

  @override
  String get contactsDenied => 'لا يستطيع سدرة قراءة جهات اتصالك';

  @override
  String get contactsDeniedBody =>
      'اسمح بالوصول إلى جهات الاتصال (الإعدادات ← التطبيقات ← سدرة ← الأذونات) ثم حاول مرة أخرى.';

  @override
  String get contactsNone => 'لا توجد جهات اتصال بها رقم هاتف';

  @override
  String get contactsSearch => 'ابحث بالاسم أو الرقم';

  @override
  String contactsSummary(int count, int created) {
    return '$count جهة اتصال · أضيف $created';
  }

  @override
  String get contactsSelectAll => 'تحديد الكل';

  @override
  String get contactsSelectNone => 'إلغاء التحديد';

  @override
  String get contactsAlready => 'موجود في سدرة';

  @override
  String contactsCreated(String password) {
    return 'أضيف · كلمة المرور $password';
  }

  @override
  String contactsImportN(int count) {
    return 'استيراد $count كمتعلمين';
  }

  @override
  String contactsImporting(int done, int count) {
    return 'جارٍ إضافة $done من $count…';
  }

  @override
  String contactsImportConfirm(int count) {
    return 'إضافة $count متعلمين؟';
  }

  @override
  String get contactsImportConfirmBody =>
      'يحصل كل منهم على حساب برقم هاتفه وكلمة مرور مؤقتة تظهر هنا بعد الاستيراد. انسخ القائمة وأرسل لكل شخص كلمته، وسيختار كلمة جديدة عند أول تسجيل دخول.';

  @override
  String get contactsCopyPasswords => 'نسخ الأسماء وكلمات المرور';

  @override
  String get contactsCopied => 'تم النسخ. أرسل لكل متعلم كلمة مروره.';

  @override
  String get targetWhole => 'العمل كله';

  @override
  String get targetOther => 'شيء آخر';

  @override
  String targetAyah(int surah, int ayah) {
    return 'سورة $surah، آية $ayah';
  }

  @override
  String targetAyahRange(int surah, int from, int to) {
    return 'سورة $surah، الآيات $from–$to';
  }

  @override
  String targetPage(int page) {
    return 'صفحة $page';
  }

  @override
  String targetPageLine(int page, int line) {
    return 'صفحة $page، سطر $line';
  }

  @override
  String targetPageLines(int page, int line, int lineEnd) {
    return 'صفحة $page، الأسطر $line–$lineEnd';
  }

  @override
  String get wtWaiting => 'بانتظار المعلم';

  @override
  String get wtUnderReview => 'المعلم يراجع';

  @override
  String get wtSuperseded => 'استُبدلت بمحاولة أحدث';

  @override
  String get wtTryAgain => 'حاول مرة أخرى';

  @override
  String get wtAccepted => 'مقبول';

  @override
  String wtLearnerTitle(String name) {
    return 'عمل $name';
  }

  @override
  String get wtMyWork => 'عملي';

  @override
  String get wtNothingYet =>
      'لم يُرسل شيء بعد. سجّل أو صوّر أو اكتب عملك في الأسفل.';

  @override
  String get wtCompleted => 'قبله معلمك. أحسنت!';

  @override
  String get wtYou => 'أنت';

  @override
  String get wtTeacher => 'المعلم';

  @override
  String get wtLearner => 'المتعلم';

  @override
  String wtFor(String what) {
    return 'بخصوص: $what';
  }

  @override
  String get wtAttachment => 'مرفق';

  @override
  String get wtUploadingPlain => 'جارٍ الرفع…';

  @override
  String wtUploading(int percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get wtSubmitting => 'تم الرفع ✓ جارٍ الإرسال إلى معلمك…';

  @override
  String get wtFailed => 'لم يُرسل';

  @override
  String get wtQueued => 'بانتظار الاتصال';

  @override
  String get wtDiscard => 'إزالة';

  @override
  String get wtDiscardBody => 'إزالة هذا من الهاتف؟ لم يُرسل بعد.';

  @override
  String get wtUploadedFile => 'تم الرفع';

  @override
  String get wtFileQueued => 'في الانتظار';

  @override
  String get wtCorrectionDefaultTitle => 'تصحيح';

  @override
  String get wtReplySent => 'أُرسل الرد.';

  @override
  String get wtNewAttempt => 'محاولة جديدة';

  @override
  String get wtReply => 'رد';

  @override
  String wtMarkLatest(int number) {
    return 'تقييم المحاولة $number:';
  }

  @override
  String get wtTryAgainAction => 'أعد المحاولة';

  @override
  String get wtTeacherReplyHint =>
      'صوت أو نص أو ملف أو تصحيح محفوظ. أرسل ما تحتاج.';

  @override
  String get wtLearnerReplyHint => 'أجب معلمك عن هذه المحاولة.';

  @override
  String get wtNewAttemptHint =>
      'أرسل عملك: تسجيلاً أو صوراً أو ملفات أو نصاً.';

  @override
  String get wtChooseTargetShort => 'بخصوص ماذا؟';

  @override
  String get wtRecord => 'تسجيل';

  @override
  String get wtTeacherTextHint => 'اكتب تصحيحاً أو ملاحظة';

  @override
  String get wtTextHint => 'اكتب شيئاً (اختياري)';

  @override
  String get wtSendReply => 'إرسال الرد';

  @override
  String get wtAyahInvalid => 'أدخل رقم السورة (1–114) وأرقام الآيات.';

  @override
  String get wtPageInvalid => 'أدخل رقم الصفحة (والأسطر من – إلى).';

  @override
  String get wtExerciseInvalid => 'اكتب اسم التمرين أو السؤال.';

  @override
  String get wtChooseTarget => 'بخصوص ماذا هذا؟';

  @override
  String get wtTargetAyah => 'آية أو آيات';

  @override
  String get wtSurah => 'السورة';

  @override
  String get wtAyahFrom => 'من آية';

  @override
  String get wtAyahTo => 'إلى آية';

  @override
  String get wtTargetPageLine => 'صفحة أو سطر';

  @override
  String get wtPage => 'الصفحة';

  @override
  String get wtLine => 'السطر';

  @override
  String get wtLineTo => 'إلى السطر';

  @override
  String get wtTargetExercise => 'تمرين أو سؤال';

  @override
  String get wtExerciseName => 'التمرين أو السؤال';

  @override
  String get wtExerciseHint => 'مثال: السؤال 4';

  @override
  String get wtTargetText => 'حدد جزءاً من الدرس';

  @override
  String get wtUseTarget => 'استخدام';

  @override
  String get wtSelectHint =>
      'اضغط مطولاً على الكلمات واسحب لتحديدها، ثم اضغط استخدام.';

  @override
  String get wtSelected => 'المحدد';

  @override
  String wtUseWholePassage(String what) {
    return 'استخدم المقطع كله ($what)';
  }

  @override
  String get wtUseSelection => 'استخدم الكلمات المحددة';

  @override
  String get accountMenu => 'الحساب';

  @override
  String get wtSendAgainHint =>
      'أُرسل. لاحظت خطأ؟ أرسل محاولة جديدة في الأسفل لتحل محل هذه.';

  @override
  String get wtSeeHistory => 'عرض عملي والملاحظات';

  @override
  String wtOpenWork(int count) {
    return 'عملي ($count محاولات): أرسل، رد، اطلع على الملاحظات';
  }

  @override
  String get wtHistory => 'السجل';

  @override
  String billPerWeek(String price) {
    return '$price / أسبوع';
  }

  @override
  String billPerMonth(String price) {
    return '$price / شهر';
  }

  @override
  String billPerTerm(String price) {
    return '$price / فصل دراسي';
  }

  @override
  String billPerDays(String price, int days) {
    return '$price كل $days يوماً';
  }

  @override
  String billPeriodsTotal(int count) {
    return '$count دفعات إجمالاً';
  }

  @override
  String get billPaused =>
      'متوقف: هناك رسوم متأخرة. ادفع أدناه لمتابعة التعلم.';

  @override
  String billCovered(int covered, int due) {
    return 'مدفوع $covered من $due حتى الآن';
  }

  @override
  String billNextDue(String date) {
    return 'الاستحقاق التالي $date';
  }

  @override
  String get billPeriodLabel => 'كم مرة تُدفع الرسوم؟';

  @override
  String get billOnce => 'مرة واحدة (دفعة واحدة)';

  @override
  String get billWeekly => 'كل أسبوع';

  @override
  String get billMonthly => 'كل شهر';

  @override
  String get billTermly => 'كل فصل دراسي';

  @override
  String get billCustom => 'كل … يوماً';

  @override
  String get billEveryDaysLabel => 'كل كم يوماً؟';

  @override
  String get billDaysInvalid => 'أدخل من 1 إلى 730 يوماً.';

  @override
  String get billPeriodsLabel => 'عدد الدفعات (اختياري)';

  @override
  String get billPeriodsHint => 'مثال: 3 فصول؛ فارغ = طوال مدة التسجيل';

  @override
  String get billPeriodsInvalid => 'أدخل من 1 إلى 520، أو اتركه فارغاً.';

  @override
  String get billHowItWorks =>
      'يُحتسب السعر أعلاه في كل فترة من يوم أول دفعة للمتعلم. يُذكَّر المتعلمون عند بدء الفترة؛ والفترة غير المدفوعة بعد أيام السماح (الإعدادات) توقف الدورة لهم حتى يدفعوا. طول الفصل في الإعدادات.';

  @override
  String get billTermDaysSetting => 'طول الفصل الدراسي (بالأيام)';

  @override
  String get billTermDaysSettingHint => 'للدورات التي تُدفع كل فصل دراسي.';

  @override
  String get billGraceSetting => 'أيام دفع الرسوم المتكررة';

  @override
  String get billGraceSettingHint =>
      'بعد بدء أسبوع أو شهر أو فصل جديد، لدى المتعلمين هذا العدد من الأيام للدفع قبل أن تتوقف الدورة لهم.';

  @override
  String wtAttemptN(int n) {
    return 'المحاولة $n';
  }

  @override
  String get ttTitle => 'معاملات تجريبية';

  @override
  String get ttConfirmTitle => 'ستتحرك أموال حقيقية';

  @override
  String ttConfirmCollect(int amount, String phone, String network) {
    return 'طلب $amount شلن من $phone ($network) إلى محفظة سدرة في MarzPay؟ سيظهر طلب رمز PIN على الهاتف.';
  }

  @override
  String ttConfirmDisburse(int amount, String phone, String network) {
    return 'إرسال $amount شلن من محفظة سدرة في MarzPay إلى $phone ($network)؟ لا يمكن التراجع.';
  }

  @override
  String get ttCollectNow => 'اجمع الآن';

  @override
  String get ttDisburseNow => 'أرسل المال الآن';

  @override
  String get ttMtn => 'MTN MoMo';

  @override
  String get ttAirtel => 'Airtel Money';

  @override
  String get ttRealMoney =>
      'للمشرفين والمطورين. هذه معاملات حقيقية عبر MarzPay وليست محاكاة. اجعل المبالغ صغيرة (الحد الأقصى في الإعدادات ← MarzPay).';

  @override
  String get ttNoKeys =>
      'هذا الإصدار بلا مفاتيح MarzPay، لذا ينتظر الاختبار خادم المدفوعات.';

  @override
  String get ttCollect => 'تحصيل (دخول المال)';

  @override
  String get ttDisburse => 'صرف (خروج المال)';

  @override
  String get ttCollectHint =>
      'يسحب المال من الهاتف إلى محفظة سدرة في MarzPay. يوافق الدافع برمز PIN.';

  @override
  String get ttDisburseHint =>
      'يرسل المال من محفظة سدرة إلى الهاتف. يتطلب رصيداً في المحفظة، وتفعيل اختبارات الإرسال (الإعدادات ← MarzPay)، والقائمة البيضاء لعناوين IP لدى MarzPay التي لا يجتازها الهاتف عادة: سيظهر ذلك في الرد.';

  @override
  String get ttPayerPhone => 'رقم الدافع';

  @override
  String get ttRecipientPhone => 'رقم المستلم';

  @override
  String get ttPhoneHelp => 'MTN (076–079) أو Airtel (070، 074، 075)';

  @override
  String get ttPhoneInvalid =>
      'أدخل رقم MTN MoMo أو Airtel Money، مثل 0772 123456';

  @override
  String get ttAmount => 'المبلغ';

  @override
  String get ttAmountHelp => '500 شلن على الأقل';

  @override
  String get ttAmountInvalid => 'أدخل مبلغاً صحيحاً لا يقل عن 500 شلن';

  @override
  String get ttHistory => 'المعاملات التجريبية السابقة';

  @override
  String get ttHistoryHint =>
      'اضغط على واحدة لعرض ردها الكامل. تُحفظ الأرقام مخفية جزئياً.';

  @override
  String get ttResultSuccess => 'نجحت (مثبتة)';

  @override
  String get ttResultAccepted => 'مقبولة، غير مثبتة';

  @override
  String get ttResultFailed => 'فشلت';

  @override
  String get ttResultCancelled => 'أُلغيت';

  @override
  String get ttResultPending => 'معلقة';

  @override
  String get ttResultBlocked => 'محظورة';

  @override
  String get ttResponse => 'الرد';

  @override
  String get ttClose => 'إغلاق';

  @override
  String get ttProviderStatus => 'حالة MarzPay';

  @override
  String get ttErrorCode => 'رمز الخطأ';

  @override
  String get ttHttpStatus => 'HTTP';

  @override
  String get ttReference => 'المرجع';

  @override
  String get ttRawResponse => 'رد MarzPay على الطلب (خام)';

  @override
  String get ttRawFinal => 'رد MarzPay النهائي (خام)';

  @override
  String get ttEntryHint =>
      'حصّل أو أرسل مبلغاً حقيقياً واطلع على رد MarzPay الدقيق';

  @override
  String get activateEntry => 'لدي رمز دعوة';

  @override
  String get activateTitle => 'انضم بدعوتك';

  @override
  String get activateSubtitle =>
      'أضافك معلمك إلى سدرة. أدخل رقمك والرمز الذي أرسله إليك واختر كلمة المرور الخاصة بك.';

  @override
  String get activateCode => 'رمز الدعوة';

  @override
  String get activateCodeInvalid => 'الرمز من 8 أحرف وأرقام، مثل ABCD-2345';

  @override
  String get activateNewPassword => 'اختر كلمة مرور';

  @override
  String get activateRepeat => 'أعد كتابة كلمة المرور';

  @override
  String get activateMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get activateButton => 'انضم إلى سدرة';

  @override
  String get authErrorInvited =>
      'أضافت مدرستك هذا الرقم بالفعل. اضغط \"لدي رمز دعوة\" واستخدم الرمز من معلمك.';

  @override
  String get authErrorInvalidCode =>
      'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً من معلمك.';

  @override
  String get authErrorAlreadyActive =>
      'هذا الحساب مفعّل بالفعل. سجّل الدخول بكلمة المرور.';

  @override
  String get obCenterTitle => 'استيراد المتعلمين وتسجيلهم';

  @override
  String get obCenterEntryHint =>
      'من واتساب أو جهات الاتصال أو Excel/CSV أو قائمة — مع حفظ موضع كل متعلم';

  @override
  String get obCenterIntro =>
      'أدخل صفاً كاملاً إلى سدرة دفعة واحدة. تتحقق سدرة أولاً من كل شخص مقابل المتعلمين الموجودين، ثم تضعهم في دورة ومجموعة مع معلمهم، وتحفظ أين توقف كل واحد، وتعطي كلاً منهم رمز دعوة. لا يُحفظ شيء حتى الخطوة الأخيرة.';

  @override
  String get obFromWhatsApp => 'من مجموعة واتساب';

  @override
  String get obFromWhatsAppHint =>
      'في واتساب: افتح المجموعة ← ⋮ ← المزيد ← تصدير الدردشة ← بدون وسائط. احفظ الملف أو شاركه ثم اختره هنا.';

  @override
  String get obFromContacts => 'من جهات اتصال هذا الهاتف';

  @override
  String get obFromContactsHint =>
      'اختر بالضبط من تريد إحضاره؛ لا يُقرأ أو يُرسل أي شيء آخر.';

  @override
  String get obFromFile => 'من ملف Excel أو CSV';

  @override
  String get obFromFileHint =>
      'أعمدة مثل الاسم والهاتف والبريد ورقم المتعلم والصفحة والسطر والحالة والملاحظات.';

  @override
  String get obFromPaste => 'الصق قائمة';

  @override
  String get obFromPasteHint => 'متعلم في كل سطر: الاسم والرقم بأي ترتيب.';

  @override
  String get obFromOne => 'متعلم واحد';

  @override
  String get obFromOneHint =>
      'أضف متعلماً واحداً مع دورته ومجموعته وموضعه الحالي.';

  @override
  String get obWhatsAppTruth =>
      'عن واتساب: لا يسمح واتساب لأي تطبيق بقراءة مجموعاتك أو أعضائها أو رسائلها، ولا تحاول سدرة ذلك أبداً. الدردشة المُصدَّرة ملف تنشئه أنت وتختاره؛ تقرأ سدرة منه أسماء وأرقام من كتبوا فيه فقط، وتحفظ الملف مع كل متعلم كسجل.';

  @override
  String get obNothingFound => 'لم يُعثر على متعلمين في ذلك.';

  @override
  String get obNotAnExport => 'لا يبدو هذا ملف دردشة مُصدَّراً من واتساب.';

  @override
  String get obFileTypes => 'اختر ملف .xlsx أو .csv أو .txt.';

  @override
  String get obFileUnreadable => 'تعذرت قراءة هذا الملف.';

  @override
  String get obPasteTitle => 'الصق المتعلمين';

  @override
  String get obPasteHint => 'أحمد موسى، 0772 123 456\nفاطمة علي 0701 234 567';

  @override
  String get obContactsWhy =>
      'لإحضار المتعلمين من جهات اتصال هذا الهاتف تحتاج سدرة إلى قراءة جهات الاتصال. ثم تختار بالضبط من تريد؛ تحتفظ سدرة فقط بمن تختارهم، وباسمهم ورقمهم فقط.';

  @override
  String get obContactsAllow => 'السماح بالوصول إلى جهات الاتصال';

  @override
  String obContactsCount(int total, int picked) {
    return '$total جهة اتصال · $picked مختار';
  }

  @override
  String obContinueWithN(int count) {
    return 'متابعة مع $count';
  }

  @override
  String get obStepChoose => 'من تريد إحضاره';

  @override
  String get obStepMatch => 'التحقق مع سدرة';

  @override
  String get obStepPlace => 'الدورة والمجموعة والمعلم';

  @override
  String get obStepPositions => 'أين يقف كل متعلم';

  @override
  String get obStepDone => 'تم';

  @override
  String get obBack => 'رجوع';

  @override
  String get obNext => 'التالي';

  @override
  String obCheck(int count) {
    return 'تحقق من $count مع سدرة';
  }

  @override
  String obImportN(int count) {
    return 'استيراد $count';
  }

  @override
  String get obWarnColumns =>
      'لا يحتوي الملف على عمود واضح للاسم أو الهاتف. راجع الصفوف أدناه وأصلحها.';

  @override
  String get obWarnSeveralCourses =>
      'يذكر الملف عدة دورات. استورد دورة واحدة في كل مرة (اختر الدورة في الخطوات التالية).';

  @override
  String obWarnNoNumbers(int count) {
    return '$count بلا رقم هاتف أو بريد (في تصدير واتساب يظهر المحفوظون في هاتفك بالاسم فقط). اضغط ✎ لإضافة رقمهم أو ألغِ اختيارهم.';
  }

  @override
  String obSelected(int selected, int total) {
    return '$selected من $total مختار';
  }

  @override
  String get obNoName => '(بلا اسم)';

  @override
  String get obNoNumber => 'بلا رقم';

  @override
  String obLastWrote(String date) {
    return 'آخر رسالة $date';
  }

  @override
  String get obEdit => 'تعديل';

  @override
  String get obFix => 'أصلح وتحقق مجدداً';

  @override
  String get obInclude => 'تضمين';

  @override
  String get obSkip => 'تخطي';

  @override
  String obPreviewTitle(int count) {
    return 'تم التحقق من $count';
  }

  @override
  String get obCountNew => 'جديد';

  @override
  String get obCountExisting => 'موجود في سدرة';

  @override
  String get obCountDuplicate => 'تكرار محتمل';

  @override
  String get obCountRepeated => 'مكرر في القائمة';

  @override
  String get obCountInvalid => 'يحتاج إصلاحاً';

  @override
  String get obDecideDuplicates =>
      'بعضهم يشبه متعلمين موجودين في سدرة. اختر لكل واحد: استخدام المتعلم الموجود أو إنشاء متعلم منفصل أو التخطي.';

  @override
  String obMatch(String name, String contact, String why) {
    return 'يطابق $name · $contact ($why)';
  }

  @override
  String get obWhyPhone => 'الرقم نفسه';

  @override
  String get obWhyEmail => 'البريد نفسه';

  @override
  String get obWhyName => 'الاسم نفسه';

  @override
  String obUseExisting(String name) {
    return 'استخدم $name';
  }

  @override
  String get obCreateSeparate => 'شخص مختلف: أنشئ';

  @override
  String get obReasonName => 'الاسم مفقود';

  @override
  String get obReasonPhone => 'رقم هاتف غير صالح';

  @override
  String get obReasonEmail => 'بريد غير صالح';

  @override
  String get obReasonNoContact => 'يحتاج رقم هاتف أو بريداً';

  @override
  String get obReasonRepeated => 'مذكور سابقاً في هذه القائمة';

  @override
  String get obCourse => 'الدورة';

  @override
  String get obNoCourseYet => 'بلا دورة بعد';

  @override
  String get obNoCourseHint =>
      'بدون دورة يُضاف المتعلمون فقط (ويُدعَون)؛ يمكنك تسجيلهم وتحديد مواضعهم لاحقاً.';

  @override
  String get obGroup => 'مجموعة التدريس';

  @override
  String get obNewGroup => 'مجموعة جديدة';

  @override
  String get obGroupName => 'اسم المجموعة';

  @override
  String get obExistingGroup => 'مجموعة موجودة';

  @override
  String get obTeacher => 'المعلم';

  @override
  String get obTeacherLater => 'اختر لاحقاً';

  @override
  String get obWhereFrom => 'من أين جاؤوا';

  @override
  String get obPrevPlatform => 'المنصة السابقة';

  @override
  String get obPrevGroup => 'المجموعة السابقة';

  @override
  String get obLastKnownOn => 'آخر تاريخ معروف';

  @override
  String get obNotSet => 'غير محدد';

  @override
  String get obInvite => 'أعطِ كل متعلم رمز دعوة';

  @override
  String get obInviteHint =>
      'يستخدمونه مرة واحدة للانضمام واختيار كلمة المرور الخاصة بهم. بلا كلمات مرور افتراضية.';

  @override
  String get obPositionsNeedCourse =>
      'اختر دورة (الخطوة السابقة) لتسجيل مواضع المتعلمين.';

  @override
  String get obEveryone => 'للجميع';

  @override
  String get obEveryoneHint =>
      'أين يقف معظم هذه المجموعة. غيّر المتعلمين فرادى أدناه. \"غير معروف\" مقبول: يمكنك التأكيد لاحقاً.';

  @override
  String get obEachLearner => 'كل متعلم (اضغط للتغيير)';

  @override
  String obSameAsEveryone(String where) {
    return 'كالجميع ($where)';
  }

  @override
  String get obUseEveryone => 'كالجميع';

  @override
  String get obLastFeedback => 'آخر ملاحظة من المعلم';

  @override
  String obConfirm(int created, int linked, int skipped) {
    return 'جاهز: $created متعلمين جدد، $linked موجودين مربوطين، $skipped متخطّين.';
  }

  @override
  String get obPositionUnknown => 'غير معروف — يحتاج تأكيداً';

  @override
  String get obPositionUnknownShort => 'غير معروف';

  @override
  String get obPositionUnknownHint =>
      'ستعرض سدرة \"يحتاج تأكيداً\" حتى تحدده. لا يُخمَّن شيء.';

  @override
  String get obPositionNeedsConfirm => 'الموضع يحتاج تأكيداً';

  @override
  String get obPositionLesson => 'درس';

  @override
  String get obAyah => 'آية';

  @override
  String get obExercise => 'تمرين';

  @override
  String get obLineOptional => 'السطر (اختياري)';

  @override
  String get obStatus => 'الحالة';

  @override
  String get obStatusUnknown => 'الحالة غير معروفة';

  @override
  String get obStatusNotStarted => 'لم يبدأ';

  @override
  String get obStatusInProgress => 'قيد التقدم';

  @override
  String get obStatusCorrection => 'يحتاج تصحيحاً';

  @override
  String get obStatusCompleted => 'مكتمل';

  @override
  String get obDoneTitle => 'تم استيراد المتعلمين';

  @override
  String obDoneCounts(int created, int matched, int skipped, int rejected) {
    return '$created أُنشئ · $matched رُبط · $skipped تُخطّي · $rejected لم يُستورد';
  }

  @override
  String get obRejectedTitle => 'لم يُستورد، ولماذا';

  @override
  String get obCopyErrors => 'انسخ قائمة المشكلات';

  @override
  String get obInvitationsTitle => 'الدعوات';

  @override
  String get obInvitationsHint =>
      'أرسل لكل متعلم رمزه. الرموز تعمل مرة واحدة وتنتهي بعد 30 يوماً؛ يمكنك إنشاء رمز جديد في أي وقت.';

  @override
  String get obCopyAllInvites => 'انسخ كل الدعوات';

  @override
  String get obSendWhatsApp => 'أرسل عبر واتساب';

  @override
  String obInviteMessage(String name, String code, String phone) {
    return 'السلام عليكم $name. انتقل صفنا إلى سدرة. ثبّت تطبيق سدرة، واضغط \"لدي رمز دعوة\"، وأدخل رقمك $phone والرمز $code، ثم اختر كلمة المرور.';
  }

  @override
  String obInvitationFor(String name) {
    return 'دعوة لـ $name';
  }

  @override
  String get obInvitationHintOne =>
      'يعمل مرة واحدة لمدة 30 يوماً. الرموز السابقة لهذا المتعلم لم تعد تعمل.';

  @override
  String get obCopy => 'نسخ';

  @override
  String get obNewCode => 'رمز دعوة جديد';

  @override
  String get obHistoryTitle => 'سجل الاستيراد';

  @override
  String get obHistoryHint =>
      'كل عملية استيراد: من ومتى ومن أين وماذا حدث — مع التراجع';

  @override
  String get obHistoryEmpty => 'لم يُستورد شيء بعد';

  @override
  String obBatchCounts(int processed, int created, int matched, int rejected) {
    return '$processed صف · $created جديد · $matched مربوط · $rejected لم يُستورد';
  }

  @override
  String get obUndo => 'تراجع';

  @override
  String get obUndone => 'تم التراجع';

  @override
  String get obUndoTitle => 'التراجع عن هذا الاستيراد؟';

  @override
  String get obUndoBody =>
      'يحذف المتعلمين الذين أنشأهم هذا الاستيراد ولم يسجلوا الدخول أو يفعلوا شيئاً بعد، والأماكن في الدورة والمجموعة التي أضافها لمتعلمين موجودين. يبقى من انضم بالفعل وكل متعلم كان موجوداً قبله.';

  @override
  String obUndoReport(int removed, int kept, int unlinked) {
    return '$removed حُذف · $kept بقي (مفعّل بالفعل) · $unlinked متعلمين موجودين فُك ربطهم';
  }

  @override
  String get obOutcomeCreated => 'أُنشئ';

  @override
  String get obOutcomeMatched => 'رُبط بموجود';

  @override
  String get obOutcomeSkipped => 'تُخطّي';

  @override
  String get obOutcomeRejected => 'لم يُستورد';

  @override
  String get obStateImported => 'غير مدعو';

  @override
  String get obStateInvited => 'مدعو';

  @override
  String get obStateActive => 'انضم';

  @override
  String get obBoardTitle => 'أين يقف المتعلمون';

  @override
  String get obBoardHint => 'لكل دورة: موضع كل متعلم ومن يحتاج إلى إعداد';

  @override
  String get obChooseCourse => 'اختر دورة';

  @override
  String get obBoardEmpty => 'الجميع هنا جاهزون';

  @override
  String get obOnlyNeeds => 'فقط من يحتاجون شيئاً';

  @override
  String obNeedsCount(int count) {
    return '$count ما زالوا يحتاجون موضعهم';
  }

  @override
  String get obSetPosition => 'حدد الموضع';

  @override
  String obSetPositionFor(int count) {
    return 'حدد الموضع لـ $count';
  }

  @override
  String get obWhereStopped => 'أين توقف هذا المتعلم؟';

  @override
  String get obContinueTitle => 'تابع من حيث توقفت';

  @override
  String get obLastPortion => 'آخر جزء';

  @override
  String get obLastSubmission => 'آخر عمل أُرسل';

  @override
  String get obNextAction => 'الخطوة التالية';

  @override
  String obNextRepeat(String where) {
    return 'أعد $where';
  }

  @override
  String obNextContinue(String where) {
    return 'تابع من $where';
  }

  @override
  String get obNextConfirm => 'أكّد أين يقف هذا المتعلم';

  @override
  String get obMigrationSource => 'جاء من';

  @override
  String get obImported => 'استُورد';

  @override
  String get obNote => 'ملاحظة';

  @override
  String obHistoricalFrom(String source, String date) {
    return 'سجل سابق من $source · استُورد $date';
  }

  @override
  String get obSourceContacts => 'جهات الاتصال';

  @override
  String get obSourceManual => 'أُدخل يدوياً';

  @override
  String get obSourceOtherLms => 'نظام آخر';

  @override
  String get aboutWhatItDoes => 'ماذا تقدّم سدرة';

  @override
  String get aboutFeatureTeach =>
      'يعطي المعلم ورد اليوم مرة واحدة، ويقرأ كل متعلم ويستمع ويسجّل ويحصل على تصحيح خاص.';

  @override
  String get aboutFeatureOffline =>
      'تعمل على الواي فاي وبيانات الجوال ودون إنترنت؛ ويُرسل عملك عند عودة الاتصال.';

  @override
  String get aboutFeatureWhatsApp =>
      'الانتقال من واتساب يحفظ موضع كل متعلم وتسجيلاته.';

  @override
  String get aboutFeaturePay =>
      'ادفع الرسوم عبر MTN أو Airtel؛ تُفتح الدورات المدفوعة بعد تأكيد الدفع.';

  @override
  String get aboutLatest => 'الأحدث';

  @override
  String aboutEarlier(int count) {
    return 'إصدارات سابقة ($count)';
  }

  @override
  String get lgFinanceHome => 'الرئيسية المالية';

  @override
  String get lgWhatWeHave => 'ما تملكه المنتهى';

  @override
  String get lgMarzPayShareNote =>
      'محفظة MarzPay هي حصة المنتهى فقط: الحساب مشترك مع DRAIS، فمجموعه في لوحة MarzPay ليس كله لنا.';

  @override
  String get lgEnterOpening =>
      'أدخل المبالغ الابتدائية (النقد، البنك، حصة MarzPay) لتكون هذه المجاميع حقيقية';

  @override
  String lgNotInBooks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلات خارج الدفاتر (عملة أخرى)',
      one: 'سجل واحد خارج الدفاتر (عملة أخرى)',
    );
    return '$_temp0';
  }

  @override
  String lgNeedsReview(String amount) {
    return '$amount يحتاج إلى حساب: صحّحه بقيد يومية';
  }

  @override
  String lgTestMoneyHeld(String amount) {
    return 'أموال الاختبار المحتجزة: $amount (ليست دخلاً)';
  }

  @override
  String get lgMonthIn => 'دخل هذا الشهر';

  @override
  String get lgMonthOut => 'مصروفات هذا الشهر';

  @override
  String get lgOwedToUs => 'مستحق لنا على المتعلمين';

  @override
  String get lgBillsToPay => 'فواتير للدفع';

  @override
  String lgClosedThrough(String date) {
    return 'الدفاتر مغلقة حتى $date';
  }

  @override
  String get lgDoSomething => 'تسجيل';

  @override
  String get lgPages => 'صفحات المالية';

  @override
  String get lgPaymentsPage => 'المدفوعات والرسوم';

  @override
  String get lgPaymentsPageHint =>
      'تحقق من المدفوعات، ومن عليه مستحقات، والإعفاءات، والاسترداد';

  @override
  String get lgAccounts => 'الحسابات';

  @override
  String get lgAccountsHint => 'كل حساب ورصيده؛ الأرصدة الافتتاحية';

  @override
  String get lgAccountsIntro =>
      'كل مبلغ يُسجَّل مرتين: حيث ذهب ومن أين جاء، فتتوازن الدفاتر دائماً. اضغط على حساب لترى حركاته.';

  @override
  String get lgJournal => 'دفتر اليومية';

  @override
  String get lgJournalHint => 'كل القيود، المدين والدائن';

  @override
  String get lgBills => 'الفواتير';

  @override
  String get lgBillsHint => 'الفواتير المستلمة وما زال مستحقاً';

  @override
  String get lgAssets => 'الأصول';

  @override
  String get lgAssetsHint => 'المعدات والأثاث وقيمتها';

  @override
  String get lgReports => 'التقارير المالية';

  @override
  String get lgReportsHint =>
      'الدخل والمصروفات، الميزانية العمومية، التدفق النقدي، الموازنة';

  @override
  String get lgCounts => 'عدّ الأموال';

  @override
  String get lgCountsHint => 'طابق النقد والبنك وMarzPay مع الدفاتر';

  @override
  String get lgTypeAsset => 'ما نملكه';

  @override
  String get lgTypeLiability => 'ما علينا';

  @override
  String get lgTypeEquity => 'رأس المال';

  @override
  String get lgTypeIncome => 'الدخل';

  @override
  String get lgTypeExpense => 'المصروفات';

  @override
  String get lgNoAccounts => 'لا يوجد حساب مناسب';

  @override
  String lgChoose(String what) {
    return 'اختر: $what';
  }

  @override
  String get lgExpenseIntro => 'ما الغرض منه ومن أين جاء المال.';

  @override
  String get lgWhatFor => 'الغرض';

  @override
  String get lgPaidFrom => 'دُفع من';

  @override
  String get lgDate => 'التاريخ';

  @override
  String get lgMoneyIn => 'مال وارد';

  @override
  String get lgMoneyInIntro =>
      'مال مستلم ليس رسوم دورة: تبرع أو قرض أو مال وضعه المالكون.';

  @override
  String get lgReceivedInto => 'استُلم في';

  @override
  String get lgKindOfMoney => 'نوع المال';

  @override
  String get lgDescription => 'الوصف';

  @override
  String get lgMoneyOut => 'مال صادر';

  @override
  String get lgMoneyOutIntro =>
      'مال مدفوع ليس مصروفاً أو فاتورة مسجلة: سداد قرض أو شراء شيء يُحتفظ به.';

  @override
  String get lgTransfer => 'نقل أموال';

  @override
  String get lgTransferIntro => 'بين حسابين لنا، مثل سحب MarzPay إلى البنك.';

  @override
  String get lgFromAccount => 'من';

  @override
  String get lgToAccount => 'إلى';

  @override
  String get lgTransferCharge => 'رسوم النقل (اختياري)';

  @override
  String get lgRecordBill => 'تسجيل فاتورة';

  @override
  String get lgBillIntro =>
      'فاتورة مستلمة لم تُدفع بعد. ادفعها لاحقاً كاملة أو على أجزاء.';

  @override
  String get lgSupplier => 'من الجهة';

  @override
  String get lgBillDate => 'تاريخ الفاتورة';

  @override
  String get lgDueDate => 'تاريخ الاستحقاق (اختياري)';

  @override
  String get lgRecordAsset => 'تسجيل أصل';

  @override
  String get lgAssetIntro =>
      'شيء اشتُري للاستخدام سنوات. تُوزَّع تكلفته على عمره الإنتاجي.';

  @override
  String get lgAssetName => 'الصنف';

  @override
  String get lgCost => 'التكلفة (UGX)';

  @override
  String get lgPurchasedOn => 'تاريخ الشراء';

  @override
  String get lgPaidHow => 'كيف دُفع';

  @override
  String get lgUsefulLife => 'العمر الإنتاجي بالأشهر (اختياري)';

  @override
  String get lgUsefulLifeHint => 'مثلاً 36 لحاسوب محمول';

  @override
  String get lgCountMoney => 'عدّ الأموال';

  @override
  String get lgCountIntro =>
      'أدخل ما يحويه الحساب فعلاً (النقد المعدود، كشف البنك، حصة MarzPay) لمقارنته بالدفاتر.';

  @override
  String get lgMoneyAccount => 'حساب المال';

  @override
  String get lgCounted => 'المبلغ المعدود (UGX)';

  @override
  String get lgCountNote => 'تفسير أي فرق';

  @override
  String get lgPostDifference => 'قيد الفرق';

  @override
  String get lgPostDifferenceHint =>
      'يسجّله في فروق النقد لتطابق الدفاتر ما عُدّ';

  @override
  String get lgCountResult => 'نتيجة العدّ';

  @override
  String lgCountMatches(String books) {
    return 'يطابق الدفاتر ($books).';
  }

  @override
  String lgCountDiffers(String books, String difference) {
    return 'تقول الدفاتر $books؛ والفرق $difference.';
  }

  @override
  String lgOpeningFor(String account) {
    return 'الرصيد الافتتاحي: $account';
  }

  @override
  String get lgOpeningIntro =>
      'ما كان في هذا الحساب عند بدء استخدام هذه الدفاتر، من سجل حقيقي (عدّ النقد، كشف البنك، MarzPay). تغييره يحل محل السابق.';

  @override
  String get lgOpeningAmount => 'المبلغ (UGX)';

  @override
  String get lgOpeningDate => 'بتاريخ';

  @override
  String lgPayBill(String supplier) {
    return 'ادفع لـ$supplier';
  }

  @override
  String lgStillOwed(String amount) {
    return 'ما زال مستحقاً: $amount';
  }

  @override
  String get lgSetBudget => 'تحديد الموازنة';

  @override
  String get lgBudgetIntro =>
      'خطّط لما تتوقع استلامه أو إنفاقه في شهر، ثم قارن بما حدث فعلاً.';

  @override
  String get lgBudgetAccount => 'دخل أو مصروف';

  @override
  String get lgBudgetMonth => 'الشهر';

  @override
  String get lgAddAccount => 'إضافة حساب';

  @override
  String get lgEditAccount => 'تعديل الحساب';

  @override
  String get lgBuiltInNote => 'حساب أساسي: رقمه ونوعه ثابتان.';

  @override
  String get lgAccountCode => 'الرقم';

  @override
  String get lgAccountCodeHint => 'من 3 إلى 6 أرقام، مثلاً 5250';

  @override
  String get lgAccountName => 'الاسم';

  @override
  String get lgAccountType => 'النوع';

  @override
  String get lgIsMoney => 'يحتفظ بمال';

  @override
  String get lgIsMoneyHint =>
      'نقد أو حساب بنكي أو محفظة: يُحسب ضمن ما تملكه المنتهى';

  @override
  String get lgInUse => 'قيد الاستخدام';

  @override
  String get lgJournalEntry => 'قيد يومية';

  @override
  String get lgJournalIntro =>
      'للتصحيحات وما لا تغطيه النماذج الأخرى. يجب أن يساوي المدين الدائن.';

  @override
  String get lgChooseAccount => 'اختر الحساب';

  @override
  String get lgRemoveLine => 'إزالة السطر';

  @override
  String get lgDebit => 'مدين';

  @override
  String get lgCredit => 'دائن';

  @override
  String get lgAddLine => 'إضافة سطر';

  @override
  String lgTotals(String debits, String credits) {
    return 'المدين $debits · الدائن $credits';
  }

  @override
  String get lgSetOpening => 'تحديد الرصيد الافتتاحي';

  @override
  String get lgNoMovements => 'لم يُسجَّل شيء بعد';

  @override
  String get lgBalanceNow => 'الرصيد الآن';

  @override
  String lgDr(String amount) {
    return 'مدين $amount';
  }

  @override
  String lgCr(String amount) {
    return 'دائن $amount';
  }

  @override
  String get lgSrcPayment => 'المدفوعات';

  @override
  String get lgSrcRefund => 'الاستردادات';

  @override
  String get lgSrcExpense => 'المصروفات';

  @override
  String get lgSrcTest => 'اختبارات MarzPay';

  @override
  String get lgSrcOpening => 'الأرصدة الافتتاحية';

  @override
  String get lgSrcBill => 'الفواتير';

  @override
  String get lgSrcBillPayment => 'سداد الفواتير';

  @override
  String get lgSrcAsset => 'الأصول';

  @override
  String get lgSrcDepreciation => 'الإهلاك';

  @override
  String get lgSrcManual => 'قيود يدوية';

  @override
  String get lgSrcReversal => 'عكس القيود';

  @override
  String get lgAll => 'الكل';

  @override
  String get lgNoEntries => 'لا توجد قيود بعد';

  @override
  String get lgReversed => 'معكوس';

  @override
  String get lgReverse => 'عكس هذا القيد';

  @override
  String get lgEntryBalanced => 'المدين يساوي الدائن.';

  @override
  String get lgNoBills => 'لا توجد فواتير';

  @override
  String lgDue(String date) {
    return 'تستحق $date';
  }

  @override
  String lgOwed(String amount) {
    return 'مستحق $amount';
  }

  @override
  String get lgPaid => 'مدفوعة';

  @override
  String get lgVoidBill => 'إلغاء هذه الفاتورة';

  @override
  String get lgRunDepreciation => 'قيد إهلاك الشهر الماضي';

  @override
  String get lgRunDepreciationHint =>
      'يوزّع تكلفة كل أصل على عمره؛ آمن عند تكراره';

  @override
  String lgDepreciationPosted(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصول أُهلكت في $month',
      one: 'أصل واحد أُهلك في $month',
      zero: 'لا شيء للإهلاك في $month',
    );
    return '$_temp0';
  }

  @override
  String get lgNoAssets => 'لا توجد أصول مسجلة';

  @override
  String lgBoughtFor(String cost, String date) {
    return '$cost في $date';
  }

  @override
  String lgOverMonths(int months) {
    return 'على $months شهراً';
  }

  @override
  String get lgValueNow => 'القيمة الآن';

  @override
  String get lgNoCounts => 'لا توجد عمليات عدّ بعد';

  @override
  String lgCountLine(String counted, String books) {
    return 'المعدود $counted، الدفاتر $books';
  }

  @override
  String get lgDifferencePosted => 'قُيّد الفرق';

  @override
  String get lgIncomeStatement => 'الدخل والمصروفات';

  @override
  String get lgBalanceSheet => 'الميزانية العمومية';

  @override
  String get lgCashFlow => 'التدفق النقدي';

  @override
  String get lgTrialBalance => 'ميزان المراجعة';

  @override
  String get lgBudget => 'الموازنة';

  @override
  String get lgCloseBooks => 'إغلاق الدفاتر';

  @override
  String get lgCloseBooksHelp => 'إغلاق الدفاتر حتى';

  @override
  String lgCloseBooksConfirm(String date) {
    return 'لن يمكن بعدها تأريخ أي قيد في $date أو قبله. المدفوعات المؤكدة لاحقاً لتلك الأيام تُقيَّد في أول يوم مفتوح. يمكنك إعادة الفتح عند الحاجة.';
  }

  @override
  String get lgSurplus => 'فائض';

  @override
  String get lgDeficit => 'عجز';

  @override
  String get lgSurplusSoFar => 'الفائض حتى الآن';

  @override
  String get lgBalanceSheetCheck =>
      'ما نملكه = ما علينا + رأس المال (مع الفائض حتى الآن).';

  @override
  String get lgOpeningMoney => 'المال في البداية';

  @override
  String get lgMoneyCameIn => 'مال وارد';

  @override
  String get lgMoneyWentOut => 'مال صادر';

  @override
  String get lgClosingMoney => 'المال في النهاية';

  @override
  String get lgNoBudget => 'لا موازنة لهذه الفترة';

  @override
  String lgBudgetLine(String actual, String budget) {
    return '$actual من $budget';
  }

  @override
  String get rcMyPayments => 'مدفوعاتي';

  @override
  String get rcMyPaymentsHint => 'المدفوعات والإيصالات';

  @override
  String get rcNoPayments => 'لا توجد مدفوعات بعد';

  @override
  String rcCovers(String from, String until) {
    return 'يغطي $from – $until';
  }

  @override
  String rcRefunded(String amount) {
    return 'استُرد $amount';
  }

  @override
  String get rcReceipt => 'إيصال';

  @override
  String get rcCancelled => 'عُكست هذه الدفعة: الإيصال ملغى.';

  @override
  String get rcSavePdf => 'حفظ بصيغة PDF';

  @override
  String get rcSaved => 'تم الحفظ';

  @override
  String get rcIssuedNote => 'أصدرته سدرة عند تأكيد الدفعة.';

  @override
  String get rcReceivedFrom => 'استُلم من';

  @override
  String get rcPhone => 'الهاتف';

  @override
  String get rcFor => 'مقابل';

  @override
  String get rcPeriod => 'الفترة المدفوعة';

  @override
  String get rcAmount => 'المبلغ';

  @override
  String get rcRefundedLabel => 'المسترد';

  @override
  String get rcMethod => 'طريقة الدفع';

  @override
  String get rcTransactionId => 'رقم المعاملة';

  @override
  String get rcPaidOn => 'تاريخ الدفع';

  @override
  String get rcConfirmedBy => 'أكّده';

  @override
  String get rcSidraRef => 'مرجع سدرة';

  @override
  String ppPayAhead(String periods) {
    return 'ادفع عدة $periods مرة واحدة';
  }

  @override
  String get ppTitle => 'الدفع المسبق';

  @override
  String get ppIntro => 'ادفع لعدة فترات الآن وتعلّم دون دفع مجدداً حتى تنتهي.';

  @override
  String ppCovers(String from, String until) {
    return 'يغطي من $from إلى $until';
  }

  @override
  String ppWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n أسبوعاً',
      few: '$n أسابيع',
      two: 'أسبوعان',
      one: 'أسبوع واحد',
    );
    return '$_temp0';
  }

  @override
  String ppMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n شهراً',
      few: '$n أشهر',
      two: 'شهران',
      one: 'شهر واحد',
    );
    return '$_temp0';
  }

  @override
  String ppTerms(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n فصلاً',
      few: '$n فصول',
      two: 'فصلان',
      one: 'فصل واحد',
    );
    return '$_temp0';
  }

  @override
  String ppPeriods(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n فترة',
      few: '$n فترات',
      two: 'فترتان',
      one: 'فترة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get rfTab => 'الاستردادات';

  @override
  String get rfIntro =>
      'يصبح الاسترداد ديناً للمتعلم عند الموافقة، ويُسدَّد عند إعادة المال. أرسله عبر الهاتف أو البنك أو نقداً، ثم سجّل رقم المعاملة هنا.';

  @override
  String get rfNone => 'لا توجد استردادات';

  @override
  String rfOwedSince(String date) {
    return 'مستحق منذ $date';
  }

  @override
  String rfPaidOut(String date, String account, String reference) {
    return 'دُفع $date من $account ($reference)';
  }

  @override
  String get rfPayOut => 'صرف';

  @override
  String rfPayOutTitle(String learner) {
    return 'استرداد لـ$learner';
  }

  @override
  String rfPayOutIntro(String amount, String phone) {
    return 'أعد $amount (رقمه: $phone)، ثم سجّل ذلك هنا.';
  }

  @override
  String get rfMethod => 'أُرسل عبر';

  @override
  String get rfMethodHint => 'مثلاً MTN، Airtel، بنك، نقد';

  @override
  String get rfReference => 'رقم المعاملة أو الإيصال';

  @override
  String rfOwedAlert(String amount) {
    return 'استردادات لم تُدفع بعد: $amount';
  }

  @override
  String get mkTitle => 'مطابقة MarzPay';

  @override
  String get mkIntro =>
      'تقارن سدرة كل دفعة MarzPay بسجلات MarzPay نفسها (الوارد والمبلغ والرسوم) كل بضع دقائق.';

  @override
  String mkCounts(int matched, int mismatched, int waiting, int notChecked) {
    return '$matched متطابقة · $mismatched مختلفة · $waiting قيد الانتظار · $notChecked لم تُفحص بعد';
  }

  @override
  String mkLast(String when) {
    return 'آخر فحص $when';
  }

  @override
  String get exDownloadPdf => 'تنزيل PDF';

  @override
  String get exDownloadExcel => 'تنزيل Excel';

  @override
  String exAsOf(String date) {
    return 'بتاريخ $date';
  }

  @override
  String get exItem => 'البند';

  @override
  String get exActual => 'الفعلي';

  @override
  String get exHeader => 'المنتهى · السجلات المالية في سدرة';

  @override
  String get arTitle => 'قواعد المحاسبة';

  @override
  String get arHint => 'كيف تعمل الدفاتر، ليؤكدها المحاسب';

  @override
  String get arIntro =>
      'هذه هي القواعد التي تتبعها دفاتر سدرة. على من يحفظ حسابات المنتهى قراءتها وتأكيدها أو طلب تغيير.';

  @override
  String get arNotConfirmed => 'لم يؤكد المحاسب قواعد المحاسبة بعد';

  @override
  String arConfirmed(String by, String date) {
    return 'أكّدها $by في $date';
  }

  @override
  String get arSendPdf => 'حفظ PDF للمحاسب';

  @override
  String get arConfirmTitle => 'تسجيل التأكيد';

  @override
  String get arConfirmIntro =>
      'سجّل من أكّد هذه القواعد (اسم المحاسب) وأي ملاحظة.';

  @override
  String get arConfirmedBy => 'أكّدها (الاسم)';

  @override
  String get arNote => 'ملاحظة (اختياري)';

  @override
  String get arRule => 'القاعدة';

  @override
  String get arWhat => 'معناها';

  @override
  String get arPdfHeader => 'المنتهى · قواعد المحاسبة في سدرة للمراجعة';

  @override
  String get arCashTitle => 'الأساس النقدي';

  @override
  String get arCash =>
      'يُحسب الدخل عند استلام المال. ما يزال على المتعلمين يُعرض منفصلاً ولا يُحسب دخلاً.';

  @override
  String get arOpeningTitle => 'المبالغ الابتدائية من سجلات حقيقية';

  @override
  String get arOpening =>
      'يبدأ كل حساب مالي بالمبلغ الذي يدخله الموظفون من سجل حقيقي (عدّ النقد، كشف البنك، MarzPay). لا تخمّن سدرة أي رصيد.';

  @override
  String get arMarzPayTitle => 'حصة المنتهى فقط في MarzPay';

  @override
  String get arMarzPay =>
      'حساب MarzPay مشترك مع DRAIS. تحسب الدفاتر مدفوعات المنتهى ورسومها ومصروفاتها في MarzPay فقط.';

  @override
  String get arFeesTitle => 'رسوم المزوّد الفعلية';

  @override
  String get arFees =>
      'رسوم كل دفعة هي ما خصمه MarzPay فعلاً، وليست نسبة مفترضة. الرسوم مصروف.';

  @override
  String get arTestTitle => 'أموال الاختبار ليست دخلاً';

  @override
  String get arTest =>
      'اختبارات MarzPay بأموال حقيقية تُحفظ في \'أموال الاختبار\' (التزام) ولا تُحسب دخلاً. رسومها مصروف.';

  @override
  String get arRefundsTitle => 'الاستردادات';

  @override
  String get arRefunds =>
      'الاسترداد المتفق عليه يخفّض الدخل فوراً ويبقى ديناً للمتعلم حتى يُدفع من حساب مالي.';

  @override
  String get arClosingTitle => 'إغلاق الأشهر';

  @override
  String get arClosing =>
      'يغلق الموظفون الماليون الشهر عند اكتماله. لا يمكن تأريخ أي قيد في شهر مغلق؛ القيود التلقائية المتأخرة تذهب لأول يوم مفتوح.';

  @override
  String get arAccountsTitle => 'الحسابات';

  @override
  String get arAccounts =>
      'يمكن للموظفين إضافة حسابات. الحسابات الأساسية تحتفظ برقمها ونوعها؛ ولا يُوقف حساب فيه مال.';

  @override
  String get arCurrencyTitle => 'عملة واحدة (UGX)';

  @override
  String get arCurrency =>
      'تُحفظ الدفاتر بالشلن الأوغندي. أي سجل بعملة أخرى يُعرض في الرئيسية المالية ولا يُحوَّل.';

  @override
  String get arPermanentTitle => 'القيود دائمة';

  @override
  String get arPermanent =>
      'كل قيد متوازن (المدين = الدائن) ولا يمكن تعديله أو حذفه. تُصحَّح الأخطاء بقيد عكسي.';

  @override
  String get mvPlay => 'تشغيل';

  @override
  String get mvView => 'عرض';

  @override
  String get apTitle => 'المظهر';

  @override
  String get apHint => 'السمة والخلفية وحجم النص';

  @override
  String get apMode => 'فاتح أو داكن';

  @override
  String get apModeOrg => 'الافتراضي';

  @override
  String get apModeSystem => 'حسب الهاتف';

  @override
  String get apModeLight => 'فاتح';

  @override
  String get apModeDark => 'داكن';

  @override
  String get apThemes => 'السمات';

  @override
  String get apThemesHint => 'السمات المقفلة متاحة مع السمات المميزة.';

  @override
  String get apOrgDefault => 'سمة المنتهى';

  @override
  String get apAnyColour => 'أي لون';

  @override
  String get apPremiumOnly => 'مع السمات المميزة';

  @override
  String get apWallpaper => 'الخلفية';

  @override
  String get apWallpaperHint => 'صورتك تبقى على هذا الهاتف.';

  @override
  String get apWpNone => 'بلا';

  @override
  String get apWpPhoto => 'صورتك';

  @override
  String get apWpDawn => 'الفجر';

  @override
  String get apWpDunes => 'الكثبان';

  @override
  String get apWpMint => 'النعناع';

  @override
  String get apWpSky => 'السماء';

  @override
  String get apWpDusk => 'الغروب';

  @override
  String get apWpNightSky => 'سماء الليل';

  @override
  String get apWpForest => 'الغابة';

  @override
  String get apWpRose => 'حديقة الورد';

  @override
  String get apCover => 'الخلفية خلف الصفحات';

  @override
  String get apCoverHint => 'يساراً: خلفية أوضح، يميناً: صفحات أبسط';

  @override
  String get apTextSize => 'حجم النص';

  @override
  String get apFont => 'خط العناوين';

  @override
  String get apFontSystem => 'خط الهاتف';

  @override
  String get apCorners => 'استدارة الزوايا';

  @override
  String get apReset => 'العودة لمظهر المنتهى';

  @override
  String get apPremiumTitle => 'السمات المميزة';

  @override
  String get apPremiumWhat =>
      'كل السمات وأي لون وخطوط العناوين واستدارة الزوايا ومقدار ظهور الخلفية. تُدفع مرة واحدة عبر الهاتف وتكون لك على كل هاتف تسجّل الدخول منه.';

  @override
  String apPremiumOffer(String price) {
    return 'سمات أكثر وأي لون والمزيد: $price مرة واحدة';
  }

  @override
  String get apPremiumNotOnSale => 'السمات المميزة غير معروضة للبيع بعد.';

  @override
  String get apUnlock => 'فتح';

  @override
  String get apUnlocked => 'أصبحت السمات المميزة لك';

  @override
  String apApprove(String price) {
    return 'وافق على $price في هاتفك';
  }

  @override
  String apPay(String price) {
    return 'ادفع $price عبر الهاتف';
  }

  @override
  String get apOrgLook => 'مظهر المؤسسة';

  @override
  String get apOrgLookHint => 'ما تعرضه كل الهواتف (المشرف العام)';

  @override
  String get apOrgLookIntro =>
      'يبدأ الجميع بهذا المظهر. ويمكنهم اختيار السمات المجانية وخلفيتهم؛ السمات المميزة تحتاج إلى دفع.';

  @override
  String get apMainColour => 'اللون الرئيسي';

  @override
  String get apAccentColour => 'اللون المميِّز';

  @override
  String get apWallpaperLink => 'أو رابط صورة (https)';

  @override
  String get apFreeThemes => 'السمات المجانية';

  @override
  String get apPremiumPrice => 'سعر السمات المميزة';

  @override
  String get apPremiumPriceHint => 'اتركه فارغاً لعدم عرضها للبيع';

  @override
  String get apThTeal => 'أخضر سدرة';

  @override
  String get apThNight => 'الليل';

  @override
  String get apThSand => 'الرمل';

  @override
  String get apThOcean => 'المحيط';

  @override
  String get apThEmerald => 'الزمرد';

  @override
  String get apThRoyal => 'الملكي';

  @override
  String get apThRose => 'الوردي';

  @override
  String get apThGoldNight => 'الليل الذهبي';

  @override
  String get apThOlive => 'الزيتوني';

  @override
  String get apThSky => 'السماوي';

  @override
  String get apThCrimson => 'القرمزي';

  @override
  String get apThSlate => 'الرمادي';
}
