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
  String get authPhoneHint => 'أدخل رمز الدولة، مثل +256 700 123 456';

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
  String get authForgotBody =>
      'اطلب من معلّمك أو من المنتهى إعادة تعيينها. ستحصل على كلمة مرور مؤقتة وتختار كلمة جديدة عند الدخول.';

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
  String get authPasswordRule => '٨ أحرف على الأقل';

  @override
  String get authPasswordsDiffer => 'كلمتا المرور غير متطابقتين';

  @override
  String get authPhoneInvalid => 'ابدأ بـ + ورمز الدولة';

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
  String get authErrorDisabled => 'هذا الحساب معطّل. تواصل مع المنتهى.';

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
  String get aboutBody =>
      'سدرة تطبيق المنتهى لتعلّم القرآن والعلوم الإسلامية. يعطي المعلم ورد اليوم مرة واحدة، ويقرأ المتعلمون ويستمعون ويسجّلون، ويحصل كل متعلم على تصحيح معلمه الخاص.';

  @override
  String get aboutBy => 'صُنع للمنتهى بواسطة Xhenvolt.';

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
}
