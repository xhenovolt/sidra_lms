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
    return 'حذف «$title» نهائيًا مع كل دروسه وتسجيلاته وتقدّم طلابه؟ لا يمكن التراجع. لإخفائها فقط، أوقف النشر بدلًا من ذلك.';
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
}
