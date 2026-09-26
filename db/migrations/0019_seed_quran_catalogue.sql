-- Phase 3: the first Qur'an-learning catalogue, seeded into the
-- curriculum engine (no Flutter code knows these courses).
--
-- * IDEMPOTENT: every row has a stable id (md5 of a seed key) and is
--   inserted with ON CONFLICT DO NOTHING. Running the seed again creates
--   nothing and never overwrites an administrator's edits.
-- * PROVISIONAL: every course and lesson carries metadata
--   {"provisional": true, "review_note": …}. Courses are seeded "In
--   review" and "By invitation": learners see nothing until an
--   administrator has checked the curriculum and published it.
-- * The sequences follow the commonly taught Qāʿidah / Yassarnal-Qurʾān
--   progression and standard beginner tajwīd teaching in the recitation of
--   Ḥafṣ ʿan ʿĀṣim. They are original curriculum metadata (titles,
--   outcomes, short explanations), not copies of any book. No page numbers
--   are given because the institution's edition was not available.
-- * Qur'anic text is limited to al-Fātiḥah, al-Ikhlāṣ, al-Falaq, an-Nās,
--   the istiʿādhah and the basmalah (Uthmani script, Ḥafṣ), each flagged
--   "verify against a printed muṣḥaf" before publishing.

create or replace function app_private.seed_id(p_key text)
returns uuid language sql immutable as $$ select md5('sidra-seed:' || p_key)::uuid $$;

create or replace function app_private.seed_course(
  p_slug text, p_title text, p_subtitle text, p_subject text, p_track text,
  p_difficulty difficulty_level, p_target text, p_description text,
  p_objectives text[], p_hours numeric, p_note text)
returns uuid
language plpgsql as $$
begin
  insert into courses (id, slug, title, subtitle, subject, track_key, difficulty,
                       target_learner, description, learning_objectives, estimated_hours,
                       language, access, self_enrol, progression, status, metadata)
  values (app_private.seed_id('course:' || p_slug), p_slug, p_title, p_subtitle, p_subject,
          p_track, p_difficulty, p_target, p_description, p_objectives, p_hours,
          'en', 'restricted', false, 'teacher_gated', 'in_review',
          jsonb_build_object('provisional', true, 'seed', 'quran-catalogue-v1',
                             'review_note', p_note))
  on conflict (slug) do nothing;
  return (select id from courses where slug = p_slug);
end $$;

create or replace function app_private.seed_unit(
  p_course text, p_pos int, p_title text, p_description text)
returns uuid
language plpgsql as $$
declare v uuid := app_private.seed_id('unit:' || p_course || ':' || p_pos);
begin
  insert into course_units (id, course_id, title, description, position, status)
  values (v, (select id from courses where slug = p_course), p_title, p_description, p_pos,
          'published')
  on conflict (id) do nothing;
  return v;
end $$;

create or replace function app_private.seed_node(
  p_course text, p_unit_pos int, p_key text, p_pos int, p_title text, p_type text,
  p_surah int default null, p_vs int default null, p_ve int default null,
  p_label text default null)
returns uuid
language plpgsql as $$
declare v uuid := app_private.seed_id('node:' || p_course || ':' || p_key);
begin
  insert into curriculum_nodes (id, course_id, unit_id, node_type, title, position,
                                surah_number, verse_start, verse_end, reference_label, status)
  values (v, (select id from courses where slug = p_course),
          app_private.seed_id('unit:' || p_course || ':' || p_unit_pos),
          p_type, p_title, p_pos, p_surah, p_vs, p_ve, p_label, 'published')
  on conflict (id) do nothing;
  return v;
end $$;

-- A lesson in a unit (p_node_key null) or in a section.
create or replace function app_private.seed_lesson(
  p_course text, p_unit_pos int, p_pos int, p_title text, p_summary text,
  p_objectives text[], p_minutes int,
  p_node_key text default null, p_surah int default null,
  p_ayah_start int default null, p_ayah_end int default null,
  p_note text default null)
returns uuid
language plpgsql as $$
declare
  v uuid := app_private.seed_id('lesson:' || p_course || ':' || p_unit_pos || ':'
                                || coalesce(p_node_key || ':', '') || p_pos);
  v_node uuid := case when p_node_key is not null
                      then app_private.seed_id('node:' || p_course || ':' || p_node_key) end;
begin
  insert into lessons (id, course_id, unit_id, node_id, title, summary, objectives,
                       estimated_minutes, position, status, quran_surah,
                       quran_ayah_start, quran_ayah_end, metadata)
  values (v, (select id from courses where slug = p_course),
          case when v_node is null
               then app_private.seed_id('unit:' || p_course || ':' || p_unit_pos) end,
          v_node, p_title, p_summary, p_objectives, p_minutes, p_pos, 'published',
          p_surah, p_ayah_start, p_ayah_end,
          jsonb_strip_nulls(jsonb_build_object(
            'provisional', true, 'seed', 'quran-catalogue-v1', 'review_note', p_note)))
  on conflict (id) do nothing;
  return v;
end $$;

create or replace function app_private.seed_block(
  p_lesson uuid, p_pos int, p_type content_block_type, p_body jsonb,
  p_language text default 'en', p_audience text default 'all')
returns void
language sql as $$
  insert into lesson_content_blocks (id, lesson_id, position, block_type, body, language, audience)
  values (app_private.seed_id(p_lesson::text || ':block:' || p_pos), p_lesson, p_pos, p_type,
          p_body, p_language, p_audience)
  on conflict (id) do nothing
$$;

create or replace function app_private.seed_text(p_lesson uuid, p_pos int, p_text text)
returns void language sql as $$
  -- a backslash-n in the seed strings means a new line
  select app_private.seed_block(p_lesson, p_pos, 'rich_text',
    jsonb_build_object('text', replace(p_text, '\n', E'\n')))
$$;

create or replace function app_private.seed_arabic(
  p_lesson uuid, p_pos int, p_arabic text,
  p_surah int default null, p_vs int default null, p_ve int default null)
returns void language sql as $$
  select app_private.seed_block(p_lesson, p_pos, 'quran_text',
    jsonb_strip_nulls(jsonb_build_object('arabic', p_arabic, 'surah', p_surah,
                                         'verse_start', p_vs, 'verse_end', p_ve)), 'ar')
$$;

create or replace function app_private.seed_note(
  p_lesson uuid, p_pos int, p_text text, p_tone text default 'note',
  p_audience text default 'all')
returns void language sql as $$
  select app_private.seed_block(p_lesson, p_pos, 'callout',
    jsonb_build_object('text', p_text, 'tone', p_tone), 'en', p_audience)
$$;

-- Practice quiz: p_questions = [{"prompt": …, "options": [...], "correct": i}]
create or replace function app_private.seed_quiz(
  p_lesson uuid, p_pos int, p_title text, p_questions jsonb)
returns void
language plpgsql as $$
declare
  v_a uuid := app_private.seed_id(p_lesson::text || ':quiz');
  v_q uuid; q jsonb; qi int := 0; o text; oi int;
begin
  insert into assessments (id, course_id, lesson_id, title, kind, grading, status)
  values (v_a, (select course_id from lessons where id = p_lesson), p_lesson, p_title,
          'practice', 'auto', 'published')
  on conflict (id) do nothing;
  for q in select * from jsonb_array_elements(p_questions) loop
    v_q := app_private.seed_id(v_a::text || ':q' || qi);
    insert into assessment_questions (id, assessment_id, position, question_type, prompt, points)
    values (v_q, v_a, qi, 'single_choice', q->>'prompt', 1)
    on conflict (id) do nothing;
    oi := 0;
    for o in select * from jsonb_array_elements_text(q->'options') loop
      insert into assessment_options (id, question_id, position, label, is_correct)
      values (app_private.seed_id(v_q::text || ':o' || oi), v_q, oi, o,
              oi = (q->>'correct')::int)
      on conflict (id) do nothing;
      oi := oi + 1;
    end loop;
    qi := qi + 1;
  end loop;
  insert into lesson_content_blocks (id, lesson_id, position, block_type, body, assessment_id)
  values (app_private.seed_id(p_lesson::text || ':block:' || p_pos), p_lesson, p_pos,
          'assessment', '{}', v_a)
  on conflict (id) do nothing;
end $$;

-- Teacher-assessed recitation (the teacher listens and grades).
create or replace function app_private.seed_recitation(
  p_lesson uuid, p_pos int, p_title text, p_prompt text)
returns void
language plpgsql as $$
declare v_a uuid := app_private.seed_id(p_lesson::text || ':recitation');
begin
  insert into assessments (id, course_id, lesson_id, title, instructions, kind, grading,
                           pass_mark_percent, status)
  values (v_a, (select course_id from lessons where id = p_lesson), p_lesson, p_title,
          p_prompt, 'graded', 'teacher', 70, 'published')
  on conflict (id) do nothing;
  insert into assessment_questions (id, assessment_id, position, question_type, prompt, points)
  values (app_private.seed_id(v_a::text || ':q0'), v_a, 0, 'recitation', p_prompt, 10)
  on conflict (id) do nothing;
  insert into lesson_content_blocks (id, lesson_id, position, block_type, body, assessment_id)
  values (app_private.seed_id(p_lesson::text || ':block:' || p_pos), p_lesson, p_pos,
          'assessment', '{}', v_a)
  on conflict (id) do nothing;
end $$;

-- Work the learner does and hands in (photo of writing, recording…).
create or replace function app_private.seed_assignment(
  p_lesson uuid, p_title text, p_instructions text, p_types text[], p_max numeric default 10)
returns void language sql as $$
  insert into assignments (id, course_id, lesson_id, title, instructions, submission_types,
                           max_score, status)
  values (app_private.seed_id(p_lesson::text || ':assignment'),
          (select course_id from lessons where id = p_lesson), p_lesson, p_title,
          p_instructions, p_types, p_max, 'published')
  on conflict (id) do nothing
$$;

-- ======================================================================
create or replace function app_private.seed_quran_catalogue()
returns jsonb
language plpgsql
as $seed$
declare
  c text;
  l uuid;
  v_book uuid;
  v_struct uuid;
begin
  -- ------------------------------------------------------------ books --
  v_book := app_private.seed_id('book:yassarnal-quran');
  insert into books (id, title, author, description, language, edition, copyright_notes, status)
  values (v_book, 'Yassarnal-Qurʾān (edition used at Almuntahha)', null,
          'Beginner Qur''an-reading primer. Record the exact edition and publisher before publishing; lesson titles in Sidra are original and do not reproduce the book.',
          'ar', 'to be confirmed', 'Copyrighted by its publisher: attach scans only with permission.',
          'draft')
  on conflict (id) do nothing;
  v_struct := app_private.seed_id('structure:yassarnal-quran');
  insert into book_structures (id, book_id, name, is_default)
  values (v_struct, v_book, 'By stage and lesson', true) on conflict (id) do nothing;
  insert into book_structure_levels (id, structure_id, depth, node_type, label_singular, label_plural)
  values (app_private.seed_id('level:yassarnal:1'), v_struct, 1, 'stage', 'Stage', 'Stages'),
         (app_private.seed_id('level:yassarnal:2'), v_struct, 2, 'lesson', 'Lesson', 'Lessons')
  on conflict (id) do nothing;

  v_book := app_private.seed_id('book:mushaf-hafs');
  insert into books (id, title, description, language, edition, status)
  values (v_book, 'The Noble Qurʾān: Madinah muṣḥaf (Ḥafṣ ʿan ʿĀṣim)',
          'Reference muṣḥaf for recitation lessons. Qur''anic text in Sidra must be checked against it.',
          'ar', 'King Fahd Complex, Ḥafṣ ʿan ʿĀṣim (confirm printing)', 'draft')
  on conflict (id) do nothing;
  v_struct := app_private.seed_id('structure:mushaf-hafs');
  insert into book_structures (id, book_id, name, is_default)
  values (v_struct, v_book, 'By sūrah and āyah', true) on conflict (id) do nothing;
  insert into book_structure_levels (id, structure_id, depth, node_type, label_singular,
                                     label_plural, uses_surah, uses_verses)
  values (app_private.seed_id('level:mushaf:1'), v_struct, 1, 'surah', 'Sūrah', 'Sūrahs', true, false),
         (app_private.seed_id('level:mushaf:2'), v_struct, 2, 'ayah_range', 'Āyāt', 'Āyāt', false, true)
  on conflict (id) do nothing;

  -- ============================================ 1. YASSARNA BEGINNERS ==
  c := 'quran-yassarna-beginner';
  perform app_private.seed_course(c,
    'Yassarna: Beginners', 'Learn to read the Arabic script of the Qur’an from the first letter',
    'Qur’an reading', 'quran_reading', 'beginner',
    'Complete beginners, children or adults, who cannot yet read Arabic script.',
    'A step-by-step course in decoding the Arabic script as it is written in the Qur’an: the letters, their shapes, the vowel signs, sukūn and shaddah, up to reading short Qur’anic words and al-Fātiḥah with a teacher. It teaches READING (decoding); correct recitation and tajwīd rules are taught in later courses.',
    array['Recognise, name and pronounce all 28 Arabic letters',
          'Read letters in their joined forms',
          'Read words carrying fatḥah, kasrah, ḍammah, tanwīn, sukūn, madd and shaddah',
          'Read al-Fātiḥah slowly and accurately with a teacher'],
    30,
    'Sequence modelled on the common Qāʿidah / Yassarnal-Qurʾān progression. Confirm stages and order against the edition Almuntahha uses; no page numbers were entered.');
  insert into course_books (course_id, book_id, is_primary)
  values ((select id from courses where slug = c), app_private.seed_id('book:yassarnal-quran'), true)
  on conflict do nothing;

  perform app_private.seed_unit(c, 0, 'Stage 1: The letters on their own',
    'Al-ḥurūf al-mufradah: every letter, its name and its sound.');
  l := app_private.seed_lesson(c, 0, 0, 'How Arabic script works',
    'Right to left, 28 letters, and how this course works.',
    array['The learner reads a line from right to left and knows the alphabet has 28 letters.',
          'The learner knows that dots and small signs change how a letter is read.'], 15);
  perform app_private.seed_text(l, 0, 'Arabic is read and written **from right to left**. The alphabet has **28 letters**. Many letters share one shape and differ only by their dots, so look carefully at the dots.' || E'\n\n' || 'In this course you learn to **read** (decode) the script of the Qur’an. Beautiful recitation and tajwīd rules come later.');
  perform app_private.seed_note(l, 1, 'Practise a little every day: ten minutes daily is better than one long session a week.', 'info');
  perform app_private.seed_note(l, 2, 'Teacher: check how the learner holds the book and points right to left before moving on.', 'note', 'staff');

  l := app_private.seed_lesson(c, 0, 1, 'Letters alif to khāʾ',
    'The first seven letters, their names and sounds.',
    array['The learner names and pronounces ا ب ت ث ج ح خ.',
          'The learner points to each of these letters when the teacher names it.'], 20);
  perform app_private.seed_arabic(l, 0, 'ا  ب  ت  ث  ج  ح  خ');
  perform app_private.seed_text(l, 1, '- **ا** alif\n- **ب** bāʾ: one dot below\n- **ت** tāʾ: two dots above\n- **ث** thāʾ: three dots above\n- **ج** jīm: one dot inside\n- **ح** ḥāʾ: no dot\n- **خ** khāʾ: one dot above');
  perform app_private.seed_assignment(l, 'Write alif to khāʾ',
    'Write each of the letters ا ب ت ث ج ح خ five times on paper, say its name as you write, then photograph your page and hand it in.',
    array['image']);

  l := app_private.seed_lesson(c, 0, 2, 'Letters dāl to ḍād',
    'Eight more letters.',
    array['The learner names and pronounces د ذ ر ز س ش ص ض.'], 20);
  perform app_private.seed_arabic(l, 0, 'د  ذ  ر  ز  س  ش  ص  ض');

  l := app_private.seed_lesson(c, 0, 3, 'Letters ṭāʾ to yāʾ, and hamzah',
    'The remaining letters.',
    array['The learner names and pronounces ط ظ ع غ ف ق ك ل م ن ه و ي and recognises hamzah ء.'], 25);
  perform app_private.seed_arabic(l, 0, 'ط  ظ  ع  غ  ف  ق  ك  ل  م  ن  ه  و  ي  ء');

  l := app_private.seed_lesson(c, 0, 4, 'Letters that look alike',
    'Tell letters apart by their dots.',
    array['The learner distinguishes letters that differ only by dots (ب ت ث ن ي; ج ح خ; د ذ; ر ز; س ش; ص ض; ط ظ; ع غ; ف ق).'], 20);
  perform app_private.seed_arabic(l, 0, 'ب ت ث ن ي   ·   ج ح خ   ·   د ذ   ·   ر ز   ·   س ش   ·   ص ض   ·   ط ظ   ·   ع غ   ·   ف ق');
  perform app_private.seed_quiz(l, 1, 'Which letter is it?', jsonb_build_array(
    jsonb_build_object('prompt', 'Which letter has ONE dot BELOW?', 'options', jsonb_build_array('ب', 'ت', 'ث', 'ن'), 'correct', 0),
    jsonb_build_object('prompt', 'Which letter has THREE dots above?', 'options', jsonb_build_array('ت', 'ث', 'ش', 'ن'), 'correct', 1),
    jsonb_build_object('prompt', 'Which letter has NO dot?', 'options', jsonb_build_array('خ', 'ج', 'ح', 'غ'), 'correct', 2)));

  l := app_private.seed_lesson(c, 0, 5, 'Where the sounds come from (introduction)',
    'A first look at makhārij: throat, tongue and lips.',
    array['The learner hears and imitates the difference between close pairs such as ح/ه, ع/ء, س/ص, ت/ط, ذ/ز, ك/ق.'], 25,
    p_note => 'Introductory only. Detailed makhārij are taught in Yassarna: Advanced.');
  perform app_private.seed_text(l, 0, 'Some letters sound close to one another in English but not in Arabic. Listen to your teacher and repeat each pair slowly: **ح / ه**, **ع / ء**, **س / ص**, **ت / ط**, **ذ / ز**, **ك / ق**.');
  perform app_private.seed_recitation(l, 1, 'Say the pairs to your teacher',
    'Say each pair clearly to your teacher: ح ه, ع ء, س ص, ت ط, ذ ز, ك ق.');

  perform app_private.seed_unit(c, 1, 'Stage 2: Joined letters',
    'Al-ḥurūf al-murakkabah: the shapes letters take inside words.');
  l := app_private.seed_lesson(c, 1, 0, 'Beginning, middle and end shapes',
    'How a letter changes shape when joined.',
    array['The learner recognises ب ت ث ن ي ج ح خ س ش ع غ ف ق ك ل م ه in their beginning, middle and end shapes.'], 25);
  perform app_private.seed_arabic(l, 0, 'بـ  ـبـ  ـب   ·   عـ  ـعـ  ـع   ·   هـ  ـهـ  ـه');
  perform app_private.seed_assignment(l, 'Write bāʾ in every position',
    'Write ب on its own, at the beginning, in the middle and at the end of a word. Do the same for ع and ه. Photograph your work.',
    array['image']);

  l := app_private.seed_lesson(c, 1, 1, 'Letters that do not join forward',
    'The six letters ا د ذ ر ز و never join to the letter after them.',
    array['The learner identifies the six non-connecting letters and reads words where they break the joining.'], 20);
  perform app_private.seed_arabic(l, 0, 'ا  د  ذ  ر  ز  و');
  perform app_private.seed_quiz(l, 1, 'Joining', jsonb_build_array(
    jsonb_build_object('prompt', 'Which letter does NOT join to the letter after it?', 'options', jsonb_build_array('ب', 'د', 'م', 'س'), 'correct', 1),
    jsonb_build_object('prompt', 'Which letter does NOT join to the letter after it?', 'options', jsonb_build_array('و', 'ف', 'ك', 'ن'), 'correct', 0)));

  l := app_private.seed_lesson(c, 1, 2, 'Finding letters inside words',
    'Spot each letter in joined writing.',
    array['The learner names each letter in short joined words written without vowel signs.'], 20);
  perform app_private.seed_arabic(l, 0, 'كتب   قلم   بيت   نور   رحمن');

  perform app_private.seed_unit(c, 2, 'Stage 3: Short vowels',
    'Al-ḥarakāt: fatḥah, kasrah, ḍammah and tanwīn.');
  l := app_private.seed_lesson(c, 2, 0, 'Fatḥah',
    'The short "a" sign above a letter.',
    array['The learner reads every letter carrying fatḥah correctly (بَ تَ ثَ …).'], 20);
  perform app_private.seed_arabic(l, 0, 'بَ  تَ  ثَ  جَ  حَ  خَ  دَ  ذَ  رَ  زَ');

  l := app_private.seed_lesson(c, 2, 1, 'Kasrah and ḍammah',
    'The short "i" below and the short "u" above.',
    array['The learner reads letters with kasrah and ḍammah and tells the three short vowels apart.'], 25);
  perform app_private.seed_arabic(l, 0, 'بَ بِ بُ   ·   سَ سِ سُ   ·   قَ قِ قُ');

  l := app_private.seed_lesson(c, 2, 2, 'Reading syllables and short words',
    'Put the vowels together into words.',
    array['The learner reads three-letter words with short vowels (e.g. كَتَبَ، خَلَقَ، قَرَأَ) without spelling them out letter by letter.'], 25);
  perform app_private.seed_arabic(l, 0, 'كَتَبَ   خَلَقَ   قَرَأَ   جَعَلَ   سَمِعَ');
  perform app_private.seed_quiz(l, 1, 'Short vowels', jsonb_build_array(
    jsonb_build_object('prompt', 'How is بِ read?', 'options', jsonb_build_array('ba', 'bi', 'bu'), 'correct', 1),
    jsonb_build_object('prompt', 'How is كُ read?', 'options', jsonb_build_array('ka', 'ki', 'ku'), 'correct', 2)));
  perform app_private.seed_assignment(l, 'Record yourself reading',
    'Record yourself reading the five words in this lesson slowly and hand in the recording.',
    array['audio']);

  l := app_private.seed_lesson(c, 2, 3, 'Tanwīn',
    'Doubled vowel signs that add an "n" sound.',
    array['The learner reads tanwīn fatḥ, kasr and ḍamm correctly (بًا بٍ بٌ).'], 20);
  perform app_private.seed_arabic(l, 0, 'بًا  بٍ  بٌ   ·   كِتَابٌ   ·   رَحِيمًا');

  perform app_private.seed_unit(c, 3, 'Stage 4: Long vowels and sukūn',
    'Madd letters, the standing vowels, sukūn and līn.');
  l := app_private.seed_lesson(c, 3, 0, 'Madd letters: long vowels',
    'Alif after fatḥah, wāw after ḍammah, yāʾ after kasrah.',
    array['The learner lengthens a vowel for two counts when followed by its madd letter (بَا بُو بِي).'], 25);
  perform app_private.seed_arabic(l, 0, 'بَا  بُو  بِي   ·   قَالَ   ·   يَقُولُ   ·   قِيلَ');

  l := app_private.seed_lesson(c, 3, 1, 'The standing vowels',
    'The small vertical alif and similar signs in the Qur’anic script.',
    array['The learner reads the vertical (dagger) alif as a long "ā", as in ٱلرَّحْمَٰنِ.'], 20);
  perform app_private.seed_arabic(l, 0, 'ٱلرَّحْمَٰنِ   ·   مَٰلِكِ   ·   ذَٰلِكَ');

  l := app_private.seed_lesson(c, 3, 2, 'Sukūn',
    'A letter with no vowel closes the syllable.',
    array['The learner reads words with sukūn as one closed syllable (مِنْ، قُلْ، أَنْتَ).'], 20);
  perform app_private.seed_arabic(l, 0, 'مِنْ   قُلْ   أَنْتَ   يَعْلَمُ');

  l := app_private.seed_lesson(c, 3, 3, 'Līn: soft wāw and yāʾ',
    'Wāw or yāʾ with sukūn after a fatḥah.',
    array['The learner reads līn sounds correctly (خَوْف، بَيْت) without lengthening them like madd.'], 15);
  perform app_private.seed_arabic(l, 0, 'خَوْفٌ   بَيْتٌ   قُرَيْشٍ');

  perform app_private.seed_unit(c, 4, 'Stage 5: Shaddah and first Qur’anic reading',
    'Doubled letters, al- words, and reading al-Fātiḥah.');
  l := app_private.seed_lesson(c, 4, 0, 'Shaddah',
    'A doubled letter: stop on it, then read it again with its vowel.',
    array['The learner reads a letter with shaddah as doubled (رَبِّ، إِنَّ، ثُمَّ).'], 20);
  perform app_private.seed_arabic(l, 0, 'رَبِّ   إِنَّ   ثُمَّ   ٱلْحَقُّ');

  l := app_private.seed_lesson(c, 4, 1, 'Reading "al-": the sun and moon letters',
    'When the lām of "al-" is pronounced and when it is not.',
    array['The learner pronounces the lām before moon letters (ٱلْقَمَرُ) and assimilates it before sun letters (ٱلشَّمْسُ).'], 25);
  perform app_private.seed_arabic(l, 0, 'ٱلْقَمَرُ   ·   ٱلشَّمْسُ   ·   ٱلْكِتَابُ   ·   ٱلنَّاسُ');

  l := app_private.seed_lesson(c, 4, 2, 'Reading al-Fātiḥah with your teacher',
    'Apply everything so far to the opening sūrah.',
    array['The learner reads al-Fātiḥah slowly, letter by letter, with correct vowels, sukūn, madd and shaddah.'], 30,
    p_surah => 1, p_ayah_start => 1, p_ayah_end => 7,
    p_note => 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ١ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ٢ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ٣ مَٰلِكِ يَوْمِ ٱلدِّينِ ٤ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ٥ ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ ٦ صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ ٧', 1, 1, 7);
  perform app_private.seed_recitation(l, 1, 'Read al-Fātiḥah to your teacher',
    'Read al-Fātiḥah slowly to your teacher. Accuracy of each letter and vowel matters more than speed.');

  -- ======================================== 2. INTRODUCTION TO ARABIC ==
  c := 'arabic-language-introduction';
  perform app_private.seed_course(c,
    'Introduction to Arabic Language', 'The words and structures you meet in the Qur’an',
    'Arabic language', 'quranic_arabic', 'beginner',
    'Learners who can already read Arabic script and want to begin understanding it.',
    'A first course in Arabic LANGUAGE (not the alphabet): roots, nouns, gender and number, pronouns, pointing words, the two kinds of sentence, common particles and high-frequency Qur’anic vocabulary, ending with al-Fātiḥah and al-Ikhlāṣ word by word.',
    array['Recognise the three kinds of word: ism, fiʿl and ḥarf',
          'Tell gender, number and definiteness from a word’s form',
          'Identify nominal and verbal sentences',
          'Give the meaning of common Qur’anic words'],
    30,
    'Proposed beginner sequence for Qur’anic Arabic. English glosses are simple dictionary meanings; teachers should use an approved translation for full meanings.');

  perform app_private.seed_unit(c, 0, 'Foundations: from letters to words', null);
  l := app_private.seed_lesson(c, 0, 0, 'Roots: the three-letter family',
    'Most Arabic words grow from a root of three letters.',
    array['The learner finds the three root letters in related words (كَتَبَ، كِتَابٌ، مَكْتَبٌ) and states the shared meaning.'], 25);
  perform app_private.seed_arabic(l, 0, 'ك ت ب  ←  كَتَبَ   كِتَابٌ   كَاتِبٌ   مَكْتَبٌ');
  perform app_private.seed_text(l, 1, 'The root **ك ت ب** carries the idea of *writing*: kataba (he wrote), kitāb (a book), kātib (a writer), maktab (a desk or office).');

  l := app_private.seed_lesson(c, 0, 1, 'Ism, fiʿl, ḥarf: three kinds of word',
    'Nouns, verbs and particles.',
    array['The learner sorts given words into ism (noun), fiʿl (verb) and ḥarf (particle).'], 20);
  perform app_private.seed_quiz(l, 0, 'What kind of word?', jsonb_build_array(
    jsonb_build_object('prompt', 'كِتَابٌ is…', 'options', jsonb_build_array('ism (noun)', 'fiʿl (verb)', 'ḥarf (particle)'), 'correct', 0),
    jsonb_build_object('prompt', 'خَلَقَ is…', 'options', jsonb_build_array('ism (noun)', 'fiʿl (verb)', 'ḥarf (particle)'), 'correct', 1),
    jsonb_build_object('prompt', 'فِي is…', 'options', jsonb_build_array('ism (noun)', 'fiʿl (verb)', 'ḥarf (particle)'), 'correct', 2)));

  perform app_private.seed_unit(c, 1, 'Nouns', 'Definiteness, gender and number.');
  l := app_private.seed_lesson(c, 1, 0, 'Definite and indefinite',
    'Tanwīn marks "a …", al- marks "the …".',
    array['The learner tells whether a noun is definite or indefinite (كِتَابٌ / ٱلْكِتَابُ).'], 20);
  perform app_private.seed_arabic(l, 0, 'كِتَابٌ  a book   ·   ٱلْكِتَابُ  the book');
  l := app_private.seed_lesson(c, 1, 1, 'Masculine and feminine',
    'The tāʾ marbūṭah (ة) usually marks feminine.',
    array['The learner identifies the feminine form of common nouns and adjectives (مُسْلِمٌ / مُسْلِمَةٌ).'], 20);
  perform app_private.seed_quiz(l, 0, 'Feminine', jsonb_build_array(
    jsonb_build_object('prompt', 'Which word is feminine?', 'options', jsonb_build_array('مُؤْمِنٌ', 'مُؤْمِنَةٌ', 'كِتَابٌ'), 'correct', 1)));
  l := app_private.seed_lesson(c, 1, 2, 'One, two, many',
    'Singular, dual and plural.',
    array['The learner recognises singular, dual (ـَانِ / ـَيْنِ) and sound plural (ـُونَ / ـِينَ) forms.'], 25);
  perform app_private.seed_arabic(l, 0, 'مُسْلِمٌ   ·   مُسْلِمَانِ   ·   مُسْلِمُونَ');
  perform app_private.seed_quiz(l, 1, 'Number', jsonb_build_array(
    jsonb_build_object('prompt', 'مُسْلِمَانِ means…', 'options', jsonb_build_array('one Muslim', 'two Muslims', 'many Muslims'), 'correct', 1)));

  perform app_private.seed_unit(c, 2, 'Pronouns and pointing words', null);
  l := app_private.seed_lesson(c, 2, 0, 'Separate pronouns',
    'I, you, he, she, we, they.',
    array['The learner gives the meaning of هُوَ، هِيَ، أَنْتَ، أَنَا، نَحْنُ، هُمْ.'], 20);
  perform app_private.seed_arabic(l, 0, 'أَنَا   أَنْتَ   هُوَ   هِيَ   نَحْنُ   هُمْ');
  l := app_private.seed_lesson(c, 2, 1, 'This and that',
    'Demonstratives: هَٰذَا، هَٰذِهِ، ذَٰلِكَ، تِلْكَ.',
    array['The learner uses near and far demonstratives with masculine and feminine nouns.'], 20,
    p_note => 'Example ذَٰلِكَ ٱلْكِتَابُ is from al-Baqarah 2:2; verify spelling against the muṣḥaf.');
  perform app_private.seed_arabic(l, 0, 'ذَٰلِكَ ٱلْكِتَابُ', 2, 2, 2);
  l := app_private.seed_lesson(c, 2, 2, 'Attached pronouns',
    'His book, your Lord, our Lord.',
    array['The learner gives the meaning of attached pronouns in words like رَبُّكَ، رَبُّنَا، كِتَابُهُ.'], 20);

  perform app_private.seed_unit(c, 3, 'Sentences', null);
  l := app_private.seed_lesson(c, 3, 0, 'The nominal sentence',
    'Mubtadaʾ and khabar: "Allah is Forgiving".',
    array['The learner identifies the subject (mubtadaʾ) and predicate (khabar) in short nominal sentences.'], 25);
  perform app_private.seed_arabic(l, 0, 'ٱللَّهُ غَفُورٌ   ·   ٱلْبَيْتُ كَبِيرٌ');
  l := app_private.seed_lesson(c, 3, 1, 'The past-tense verb',
    'فَعَلَ: he did.',
    array['The learner recognises past-tense verbs and who did the action (كَتَبَ، كَتَبُوا، كَتَبْتُ).'], 25);
  l := app_private.seed_lesson(c, 3, 2, 'The verbal sentence',
    'Verb first, then the doer.',
    array['The learner identifies the verb and the doer (fāʿil) in a verbal sentence.'], 20);
  l := app_private.seed_lesson(c, 3, 3, 'Particles and prepositions',
    'فِي، مِنْ، إِلَى، عَلَى، وَ، فَ، ثُمَّ.',
    array['The learner gives the meaning of the most common particles and prepositions.'], 20);
  perform app_private.seed_arabic(l, 0, 'فِي   مِنْ   إِلَى   عَلَى   وَ   فَ   ثُمَّ');

  perform app_private.seed_unit(c, 4, 'Understanding the Qur’an’s words', null);
  l := app_private.seed_lesson(c, 4, 0, 'High-frequency Qur’anic words',
    'A small set of words that appears very often.',
    array['The learner gives the meaning of 20 high-frequency Qur’anic words.'], 30,
    p_note => 'Choose the word list with your teachers; the examples shown are a starting point.');
  perform app_private.seed_arabic(l, 0, 'ٱللَّه   رَبّ   قَالَ   كَانَ   أَرْض   سَمَاء   يَوْم   ءَامَنُوا');
  perform app_private.seed_assignment(l, 'Word cards',
    'Write each word with its meaning on a card or page, then hand in a photo or type the list.',
    array['image', 'text']);
  l := app_private.seed_lesson(c, 4, 1, 'Al-Fātiḥah word by word',
    'The meaning of each word of the opening sūrah.',
    array['The learner gives the meaning of each word of al-Fātiḥah.'], 35,
    p_surah => 1, p_ayah_start => 1, p_ayah_end => 7,
    p_note => 'Word glosses are simple dictionary meanings; confirm with an approved translation.');
  perform app_private.seed_text(l, 0, '- **ٱلْحَمْدُ**: the praise\n- **لِلَّهِ**: (belongs) to Allah\n- **رَبِّ**: Lord (of)\n- **ٱلْعَٰلَمِينَ**: the worlds\n- **مَٰلِكِ**: Master / Owner (of)\n- **يَوْمِ ٱلدِّينِ**: the Day of Judgement\n- **نَعْبُدُ**: we worship\n- **نَسْتَعِينُ**: we ask for help\n- **ٱهْدِنَا**: guide us\n- **ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ**: the straight path');
  l := app_private.seed_lesson(c, 4, 2, 'Al-Ikhlāṣ word by word',
    'The meaning of each word of Sūrat al-Ikhlāṣ.',
    array['The learner gives the meaning of each word of al-Ikhlāṣ.'], 25,
    p_surah => 112, p_ayah_start => 1, p_ayah_end => 4,
    p_note => 'Verify the Qur’anic text and glosses before publishing.');
  perform app_private.seed_arabic(l, 0, 'قُلْ هُوَ ٱللَّهُ أَحَدٌ ١ ٱللَّهُ ٱلصَّمَدُ ٢ لَمْ يَلِدْ وَلَمْ يُولَدْ ٣ وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ ٤', 112, 1, 4);

  -- =========================================== 3. YASSARNA INTERMEDIATE ==
  c := 'quran-yassarna-intermediate';
  perform app_private.seed_course(c,
    'Yassarna: Intermediate', 'From decoding to fluent Qur’anic reading',
    'Qur’an reading', 'quran_reading', 'intermediate',
    'Learners who finished Yassarna: Beginners and can read vowelled words slowly.',
    'Builds fluency: mixed signs in longer words, the special spellings of the Qur’anic script (rasm), the connecting hamzah, madd in practice, stopping and starting, and fluent reading of short sūrahs, with teacher correction throughout.',
    array['Read longer Qur’anic words fluently', 'Handle the special spellings of the muṣḥaf',
          'Stop and start correctly', 'Read the last short sūrahs fluently'],
    30,
    'Proposed intermediate stage. Waqf sign systems differ between muṣḥaf editions (e.g. Madinah vs South Asian printings): teach the signs of the muṣḥaf the institution uses.');

  perform app_private.seed_unit(c, 0, 'Fluent reading of words', null);
  l := app_private.seed_lesson(c, 0, 0, 'All the signs together',
    'Review of ḥarakāt, madd, sukūn and shaddah in mixed words.',
    array['The learner reads words combining several signs without hesitation.'], 25);
  l := app_private.seed_lesson(c, 0, 1, 'Longer words',
    'Reading long words in syllables.',
    array['The learner breaks long Qur’anic words into syllables and reads them smoothly.'], 25);

  perform app_private.seed_unit(c, 1, 'The Qur’anic script (rasm)', null);
  l := app_private.seed_lesson(c, 1, 0, 'Letters written but not read',
    'For example the alif after the wāw of the plural (قَالُوا).',
    array['The learner does not pronounce letters that are written but silent, such as the final alif in قَالُوا.'], 20);
  perform app_private.seed_arabic(l, 0, 'قَالُوا   ءَامَنُوا   أَنَا');
  l := app_private.seed_lesson(c, 1, 1, 'Small signs in the muṣḥaf',
    'The small wāw and yāʾ, and other small letters.',
    array['The learner reads the small wāw/yāʾ after a pronoun as a lengthened vowel where they appear (e.g. لَهُۥ).'], 20);
  l := app_private.seed_lesson(c, 1, 2, 'The connecting hamzah (ٱ)',
    'Hamzat al-waṣl: read when starting, dropped when continuing.',
    array['The learner starts a word with hamzat al-waṣl correctly and drops it when joining from the previous word.'], 25);
  perform app_private.seed_quiz(l, 1, 'Connecting hamzah', jsonb_build_array(
    jsonb_build_object('prompt', 'When is the hamzah of ٱلْحَمْدُ pronounced?', 'options', jsonb_build_array('Always', 'Only when you START with it', 'Never'), 'correct', 1)));

  perform app_private.seed_unit(c, 2, 'Madd in practice', null);
  l := app_private.seed_lesson(c, 2, 0, 'Natural madd: two counts',
    'Keeping long vowels even.',
    array['The learner holds natural madd for an even two counts.'], 20);
  l := app_private.seed_lesson(c, 2, 1, 'The madd sign (~)',
    'Longer madd before hamzah or sukūn: first practice.',
    array['The learner lengthens vowels marked with the madd sign more than natural madd, following the teacher.'], 25,
    p_note => 'Practical introduction only; the counts and categories are taught in Yassarna: Advanced.');

  perform app_private.seed_unit(c, 3, 'Stopping and starting', null);
  l := app_private.seed_lesson(c, 3, 0, 'How to stop on a word',
    'Sukūn on the last letter; tāʾ marbūṭah becomes hāʾ; tanwīn fatḥ becomes alif.',
    array['The learner stops on a word correctly (رَحِيمٌ → رَحِيمْ، رَحْمَةٌ → رَحْمَهْ، عَلِيمًا → عَلِيمَا).'], 25);
  perform app_private.seed_quiz(l, 1, 'Stopping', jsonb_build_array(
    jsonb_build_object('prompt', 'Stopping on رَحْمَةٌ, you say…', 'options', jsonb_build_array('raḥmatun', 'raḥmah', 'raḥmat'), 'correct', 1),
    jsonb_build_object('prompt', 'Stopping on عَلِيمًا, you say…', 'options', jsonb_build_array('ʿalīman', 'ʿalīmā', 'ʿalīm'), 'correct', 1)));
  l := app_private.seed_lesson(c, 3, 1, 'Stop signs in the muṣḥaf',
    'What the small signs above the line mean.',
    array['The learner explains the stop signs printed in the muṣḥaf used by the class and follows them while reading.'], 25,
    p_note => 'Sign systems differ between muṣḥaf editions: adapt this lesson to the class muṣḥaf.');
  l := app_private.seed_lesson(c, 3, 2, 'Starting again after a stop',
    'Ibtidāʾ: where and how to resume.',
    array['The learner resumes reading at a sensible point and starts correctly with hamzat al-waṣl.'], 20);

  perform app_private.seed_unit(c, 4, 'Fluent short sūrahs', null);
  l := app_private.seed_lesson(c, 4, 0, 'An-Nās, al-Falaq and al-Ikhlāṣ',
    'Reading the last three sūrahs fluently.',
    array['The learner reads sūrahs 112–114 fluently and accurately.'], 30,
    p_note => 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ ١ مَلِكِ ٱلنَّاسِ ٢ إِلَٰهِ ٱلنَّاسِ ٣ مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ ٤ ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ ٥ مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ ٦', 114, 1, 6);
  perform app_private.seed_recitation(l, 1, 'Read the last three sūrahs',
    'Read an-Nās, al-Falaq and al-Ikhlāṣ to your teacher without stopping mid-word.');
  l := app_private.seed_lesson(c, 4, 1, 'Reading practice with correction',
    'Short passages read to the teacher, corrected, and read again.',
    array['The learner corrects errors the teacher points out and re-reads the passage accurately.'], 30);
  perform app_private.seed_assignment(l, 'Record a short sūrah',
    'Record yourself reading a short sūrah your teacher chooses and hand it in for correction.',
    array['audio']);

  -- ============================================= 4. YASSARNA ADVANCED ==
  c := 'quran-yassarna-advanced';
  perform app_private.seed_course(c,
    'Yassarna: Advanced', 'Systematic tajwīd for accurate Qur’anic recitation',
    'Tajwīd', 'tajwid', 'advanced',
    'Fluent readers who want to recite with the rules of tajwīd.',
    'A systematic course in tajwīd as recited in the reading of Ḥafṣ ʿan ʿĀṣim: articulation points and qualities of the letters, nūn and mīm sākinah, ghunnah, the kinds of madd, heavy and light letters, and stopping and starting, with teacher-assessed recitation.',
    array['Pronounce each letter from its articulation point with its qualities',
          'Apply the rules of nūn sākinah, tanwīn and mīm sākinah',
          'Apply the madd counts of Ḥafṣ ʿan ʿĀṣim',
          'Stop and start without changing the meaning'],
    40,
    'Rules follow Ḥafṣ ʿan ʿĀṣim via ash-Shāṭibiyyah, the reading most common in East Africa. Madd counts and some details differ in other riwāyāt and transmission routes: teachers of another reading should adjust.');

  perform app_private.seed_unit(c, 0, 'Articulation points and qualities', 'Makhārij and ṣifāt.');
  l := app_private.seed_lesson(c, 0, 0, 'The five articulation areas',
    'Al-jawf, al-ḥalq, al-lisān, ash-shafatān, al-khayshūm.',
    array['The learner names the five main articulation areas and gives a letter from each.'], 30);
  l := app_private.seed_lesson(c, 0, 1, 'Letters of the throat',
    'ء ه ع ح غ خ from the deep, middle and near throat.',
    array['The learner pronounces the six throat letters from their correct place.'], 30);
  perform app_private.seed_arabic(l, 0, 'ء ه   ·   ع ح   ·   غ خ');
  l := app_private.seed_lesson(c, 0, 2, 'Letters of the tongue and lips',
    'Tongue letters in detail, and the lips.',
    array['The learner distinguishes tongue letters that are often confused (ت/ط، د/ض، ذ/ظ/ز، س/ص/ث).'], 35);
  l := app_private.seed_lesson(c, 0, 3, 'Qualities of the letters',
    'Heavy and light, whispered and voiced, and other main qualities.',
    array['The learner explains the main qualities (ṣifāt) and identifies the heavy letters خ ص ض غ ط ق ظ.'], 30);
  perform app_private.seed_arabic(l, 0, 'خُصَّ ضَغْطٍ قِظْ');
  l := app_private.seed_lesson(c, 0, 4, 'Qalqalah',
    'The echoing letters ق ط ب ج د.',
    array['The learner applies qalqalah to ق ط ب ج د when they carry sukūn.'], 25);
  perform app_private.seed_arabic(l, 0, 'قُطْبُ جَدٍّ');

  perform app_private.seed_unit(c, 1, 'Nūn sākinah and tanwīn', null);
  l := app_private.seed_lesson(c, 1, 0, 'Iẓhār: clear pronunciation',
    'Before the six throat letters.',
    array['The learner pronounces nūn sākinah and tanwīn clearly before ء ه ع ح غ خ.'], 25);
  l := app_private.seed_lesson(c, 1, 1, 'Idghām: merging',
    'Into the letters of يَرْمَلُونَ, with and without ghunnah.',
    array['The learner merges nūn sākinah and tanwīn into ي ر م ل و ن, with ghunnah into ي ن م و.'], 30);
  l := app_private.seed_lesson(c, 1, 2, 'Iqlāb: turning into mīm',
    'Before bāʾ.',
    array['The learner turns nūn sākinah and tanwīn into a hidden mīm with ghunnah before ب.'], 20);
  l := app_private.seed_lesson(c, 1, 3, 'Ikhfāʾ: hiding',
    'Before the remaining fifteen letters.',
    array['The learner applies ikhfāʾ with ghunnah before the fifteen ikhfāʾ letters.'], 30);
  perform app_private.seed_quiz(l, 1, 'Which rule applies?', jsonb_build_array(
    jsonb_build_object('prompt', 'مِنْ خَيْرٍ', 'options', jsonb_build_array('iẓhār', 'idghām', 'iqlāb', 'ikhfāʾ'), 'correct', 0),
    jsonb_build_object('prompt', 'مِنْ بَعْدِ', 'options', jsonb_build_array('iẓhār', 'idghām', 'iqlāb', 'ikhfāʾ'), 'correct', 2),
    jsonb_build_object('prompt', 'مِن شَرِّ', 'options', jsonb_build_array('iẓhār', 'idghām', 'iqlāb', 'ikhfāʾ'), 'correct', 3),
    jsonb_build_object('prompt', 'مَن يَقُولُ', 'options', jsonb_build_array('iẓhār', 'idghām', 'iqlāb', 'ikhfāʾ'), 'correct', 1)));

  perform app_private.seed_unit(c, 2, 'Mīm sākinah and ghunnah', null);
  l := app_private.seed_lesson(c, 2, 0, 'Rules of mīm sākinah',
    'Ikhfāʾ shafawī, idghām of two mīms, iẓhār shafawī.',
    array['The learner applies the three rules of mīm sākinah.'], 25);
  l := app_private.seed_lesson(c, 2, 1, 'Ghunnah on nūn and mīm with shaddah',
    'A nasal sound of two counts.',
    array['The learner holds ghunnah on نّ and مّ for two counts.'], 20);

  perform app_private.seed_unit(c, 3, 'Madd', null);
  l := app_private.seed_lesson(c, 3, 0, 'Natural and secondary madd',
    'Madd ṭabīʿī and what makes a madd longer.',
    array['The learner explains the difference between natural madd (two counts) and secondary madd caused by hamzah or sukūn.'], 25);
  l := app_private.seed_lesson(c, 3, 1, 'Madd before hamzah',
    'Muttaṣil (same word) and munfaṣil (next word).',
    array['The learner applies madd muttaṣil and munfaṣil with the counts taught by the teacher (commonly 4–5 in Ḥafṣ via ash-Shāṭibiyyah).'], 30,
    p_note => 'Counts depend on the transmission route taught; confirm with the teacher.');
  l := app_private.seed_lesson(c, 3, 2, 'Madd before sukūn',
    'Madd lāzim and madd ʿāriḍ li-s-sukūn.',
    array['The learner applies madd lāzim (six counts) and chooses a consistent length for madd ʿāriḍ when stopping.'], 30);

  perform app_private.seed_unit(c, 4, 'Heavy and light letters; stopping', null);
  l := app_private.seed_lesson(c, 4, 0, 'Tafkhīm and tarqīq',
    'Heavy and light letters, rāʾ, and the lām of the name Allah.',
    array['The learner pronounces rāʾ and the lām in ٱللَّه heavy or light according to the rules.'], 30);
  l := app_private.seed_lesson(c, 4, 1, 'Waqf and ibtidāʾ in depth',
    'Stopping and starting without changing the meaning.',
    array['The learner chooses stopping and starting points that keep the meaning intact.'], 30);
  perform app_private.seed_recitation(l, 0, 'Recitation with tajwīd',
    'Recite a passage your teacher chooses, applying the rules of this course. Your teacher grades accuracy of letters, rules and stopping.');

  -- ================================= 5. INTRODUCTION TO QUR'AN RECITATION ==
  c := 'quran-recitation-introduction';
  perform app_private.seed_course(c,
    'Introduction to Qur’an Recitation', 'Reciting the Qur’an accurately, fluently and with presence',
    'Qur’an recitation', 'quran_recitation', 'beginner',
    'Learners who can read the Arabic script (Yassarna: Beginners or equivalent) and want to recite well.',
    'Recitation is more than decoding. This course distinguishes READING (decoding the script), RECITATION (saying the Qur’an accurately and fluently), TAJWĪD (knowing the rules) and UNDERSTANDING (meaning and tafsīr). It builds practical recitation of al-Fātiḥah and short sūrahs through listening, imitation, recording and teacher correction.',
    array['Explain how reading, recitation, tajwīd and understanding differ',
          'Begin recitation with the istiʿādhah and basmalah',
          'Recite al-Fātiḥah and the last three sūrahs accurately',
          'Improve by listening, recording and correction'],
    20,
    'Proposed structure. The etiquette lesson touches on matters where schools of fiqh differ; present positions as those of the learner’s school and refer questions to a teacher.');
  insert into course_books (course_id, book_id, is_primary)
  values ((select id from courses where slug = c), app_private.seed_id('book:mushaf-hafs'), true)
  on conflict do nothing;

  perform app_private.seed_unit(c, 0, 'What recitation is', null);
  l := app_private.seed_lesson(c, 0, 0, 'Reading, recitation, tajwīd, understanding',
    'Four related goals that are not the same.',
    array['The learner explains in their own words the difference between reading, recitation, tajwīd and understanding the Qur’an.'], 20);
  perform app_private.seed_text(l, 0, '- **Reading**: can I decode the Arabic script correctly?\n- **Recitation**: can I say the Qur’an accurately and fluently?\n- **Tajwīd**: do I know and apply the rules of recitation?\n- **Understanding**: do I know what the words mean (Arabic, tafsīr)?\n\nThis course is about **recitation**.');
  l := app_private.seed_lesson(c, 0, 1, 'Etiquette of recitation',
    'Preparing yourself to recite.',
    array['The learner describes the etiquette of recitation taught by their teacher: intention, cleanliness, attention and respect for the muṣḥaf.'], 20,
    p_note => 'Details such as purity requirements for touching the muṣḥaf differ between schools; teach the position of the learner’s school.');
  perform app_private.seed_note(l, 0, 'Some details differ between the schools of fiqh. Ask your teacher about the position you follow.', 'info');
  l := app_private.seed_lesson(c, 0, 2, 'How to begin: istiʿādhah and basmalah',
    'Seeking refuge, then the basmalah.',
    array['The learner recites the istiʿādhah and basmalah correctly before reciting.'], 20,
    p_note => 'Verify the Arabic text against a printed source.');
  perform app_private.seed_arabic(l, 0, 'أَعُوذُ بِٱللَّهِ مِنَ ٱلشَّيْطَٰنِ ٱلرَّجِيمِ');
  perform app_private.seed_arabic(l, 1, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');

  perform app_private.seed_unit(c, 1, 'Sūrat al-Fātiḥah', null);
  perform app_private.seed_node(c, 1, 'fatihah', 0, 'Sūrah 1: al-Fātiḥah', 'surah', 1, 1, 7, '1:1–7');
  l := app_private.seed_lesson(c, 1, 0, 'Āyāt 1–4', 'Accurate recitation of the first four āyāt.',
    array['The learner recites āyāt 1–4 of al-Fātiḥah with correct letters and vowels.'], 25,
    'fatihah', 1, 1, 4, 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ١ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ٢ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ٣ مَٰلِكِ يَوْمِ ٱلدِّينِ ٤', 1, 1, 4);
  l := app_private.seed_lesson(c, 1, 1, 'Āyāt 5–7', 'Accurate recitation of the last three āyāt.',
    array['The learner recites āyāt 5–7 of al-Fātiḥah, including the long madd in ٱلضَّآلِّينَ.'], 25,
    'fatihah', 1, 5, 7, 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ٥ ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ ٦ صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ ٧', 1, 5, 7);
  l := app_private.seed_lesson(c, 1, 2, 'Al-Fātiḥah in full', 'Reciting the whole sūrah to your teacher.',
    array['The learner recites al-Fātiḥah in full, accurately and without stopping mid-word.'], 25,
    'fatihah', 1, 1, 7);
  perform app_private.seed_recitation(l, 0, 'Recite al-Fātiḥah',
    'Recite al-Fātiḥah to your teacher. You are assessed on accuracy of letters, vowels and madd.');
  perform app_private.seed_assignment(l, 'Record al-Fātiḥah',
    'Record yourself reciting al-Fātiḥah and hand in the recording for your teacher’s correction.',
    array['audio']);

  perform app_private.seed_unit(c, 2, 'Short sūrahs', 'The last three sūrahs of the Qur’an.');
  perform app_private.seed_node(c, 2, 'ikhlas', 0, 'Sūrah 112: al-Ikhlāṣ', 'surah', 112, 1, 4, '112:1–4');
  perform app_private.seed_node(c, 2, 'falaq', 1, 'Sūrah 113: al-Falaq', 'surah', 113, 1, 5, '113:1–5');
  perform app_private.seed_node(c, 2, 'nas', 2, 'Sūrah 114: an-Nās', 'surah', 114, 1, 6, '114:1–6');
  l := app_private.seed_lesson(c, 2, 0, 'Reciting al-Ikhlāṣ', null,
    array['The learner recites al-Ikhlāṣ accurately, including the qalqalah in أَحَدٌ when stopping.'], 20,
    'ikhlas', 112, 1, 4, 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'قُلْ هُوَ ٱللَّهُ أَحَدٌ ١ ٱللَّهُ ٱلصَّمَدُ ٢ لَمْ يَلِدْ وَلَمْ يُولَدْ ٣ وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ ٤', 112, 1, 4);
  l := app_private.seed_lesson(c, 2, 0, 'Reciting al-Falaq', null,
    array['The learner recites al-Falaq accurately, including the shaddah in ٱلنَّفَّٰثَٰتِ.'], 20,
    'falaq', 113, 1, 5, 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ ١ مِن شَرِّ مَا خَلَقَ ٢ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ٣ وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِى ٱلْعُقَدِ ٤ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ ٥', 113, 1, 5);
  l := app_private.seed_lesson(c, 2, 0, 'Reciting an-Nās', null,
    array['The learner recites an-Nās accurately, distinguishing ٱلنَّاسِ, مَلِكِ and إِلَٰهِ.'], 20,
    'nas', 114, 1, 6, 'Qur’anic text: verify against a printed muṣḥaf before publishing.');
  perform app_private.seed_arabic(l, 0, 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ ١ مَلِكِ ٱلنَّاسِ ٢ إِلَٰهِ ٱلنَّاسِ ٣ مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ ٤ ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ ٥ مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ ٦', 114, 1, 6);

  perform app_private.seed_unit(c, 3, 'Growing your recitation', null);
  l := app_private.seed_lesson(c, 3, 0, 'Pace: tartīl, tadwīr, ḥadr',
    'Slow, moderate and swift recitation.',
    array['The learner describes the three paces of recitation and recites a short sūrah slowly (tartīl).'], 20);
  l := app_private.seed_lesson(c, 3, 1, 'Listening and imitating',
    'Learning from a qualified reciter.',
    array['The learner listens to a recording chosen by the teacher and imitates it āyah by āyah.'], 25,
    p_note => 'Teachers: attach a recording by a reciter the institution approves (Resources tab).');
  l := app_private.seed_lesson(c, 3, 2, 'Record, listen, correct',
    'Using your own recordings and your teacher’s feedback.',
    array['The learner records a recitation, identifies at least two of their own mistakes, and re-records after the teacher’s correction.'], 30);
  perform app_private.seed_assignment(l, 'Two recordings',
    'Record a short sūrah, hand it in, then record it again after your teacher’s feedback and hand in the second recording.',
    array['audio']);

  -- ------------------------------------------------- prerequisites --
  insert into course_prerequisites (course_id, requires_course_id)
  select (select id from courses where slug = a), (select id from courses where slug = b)
  from (values ('quran-yassarna-intermediate', 'quran-yassarna-beginner'),
               ('quran-yassarna-advanced', 'quran-yassarna-intermediate'),
               ('quran-recitation-introduction', 'quran-yassarna-beginner'),
               ('arabic-language-introduction', 'quran-yassarna-beginner')) p(a, b)
  on conflict do nothing;

  return jsonb_build_object(
    'courses', (select count(*) from courses where metadata->>'seed' = 'quran-catalogue-v1'),
    'units', (select count(*) from course_units u join courses c on c.id = u.course_id
              where c.metadata->>'seed' = 'quran-catalogue-v1'),
    'nodes', (select count(*) from curriculum_nodes n join courses c on c.id = n.course_id
              where c.metadata->>'seed' = 'quran-catalogue-v1'),
    'lessons', (select count(*) from lessons where metadata->>'seed' = 'quran-catalogue-v1'),
    'blocks', (select count(*) from lesson_content_blocks b join lessons l on l.id = b.lesson_id
               where l.metadata->>'seed' = 'quran-catalogue-v1'),
    'assessments', (select count(*) from assessments a join lessons l on l.id = a.lesson_id
                    where l.metadata->>'seed' = 'quran-catalogue-v1'),
    'assignments', (select count(*) from assignments a join lessons l on l.id = a.lesson_id
                    where l.metadata->>'seed' = 'quran-catalogue-v1'));
end;
$seed$;

-- Only the database owner seeds.
revoke all on function app_private.seed_course(text, text, text, text, text, difficulty_level, text, text, text[], numeric, text),
  app_private.seed_unit(text, int, text, text),
  app_private.seed_node(text, int, text, int, text, text, int, int, int, text),
  app_private.seed_lesson(text, int, int, text, text, text[], int, text, int, int, int, text),
  app_private.seed_block(uuid, int, content_block_type, jsonb, text, text),
  app_private.seed_text(uuid, int, text),
  app_private.seed_arabic(uuid, int, text, int, int, int),
  app_private.seed_note(uuid, int, text, text, text),
  app_private.seed_quiz(uuid, int, text, jsonb),
  app_private.seed_recitation(uuid, int, text, text),
  app_private.seed_assignment(uuid, text, text, text[], numeric),
  app_private.seed_quran_catalogue()
from public;

-- seed_id only hashes a key; staff tools and tests may compute seeded ids.
grant execute on function app_private.seed_id(text) to authenticated, sidra_app;

select app_private.seed_quran_catalogue();
