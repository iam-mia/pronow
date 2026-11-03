-- ==============================================================================
-- ProNow: Database Schema for English Pronunciation & Discipline Habit Tracker
-- Target: Supabase / PostgreSQL 15+
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. PROFILES (Extends Supabase auth.users or standalone users)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    target_level TEXT NOT NULL DEFAULT 'B1', -- A1, A2, B1, B2, C1
    timezone TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- -----------------------------------------------------------------------------
-- 2. STREAKS (Habit & Discipline Tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_activity_date DATE,
    freeze_days_available INT NOT NULL DEFAULT 2, -- Default 2 streak freeze days
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_streak UNIQUE (user_id)
);

-- -----------------------------------------------------------------------------
-- 3. DAILY_GOALS (Customizable Daily Objectives & Notification Time)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_minutes INT NOT NULL DEFAULT 15,
    target_sentences INT NOT NULL DEFAULT 10,
    reminder_time_hour INT NOT NULL DEFAULT 20, -- 8:00 PM
    reminder_time_minute INT NOT NULL DEFAULT 0,
    is_reminder_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_daily_goal UNIQUE (user_id)
);

-- -----------------------------------------------------------------------------
-- 4. LESSONS & SENTENCES (Curriculum / Pronunciation Drills)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'General', -- Daily Conversation, Business, Travel, Minimal Pairs
    difficulty_level INT NOT NULL DEFAULT 1, -- 1 to 5
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.sentences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
    reference_text TEXT NOT NULL,
    ipa_transcription TEXT NOT NULL,
    audio_standard_url TEXT,
    difficulty INT NOT NULL DEFAULT 1,
    focus_phonemes TEXT[] DEFAULT '{}', -- Array of phonemes e.g. ['θ', 'ð', 'r']
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- -----------------------------------------------------------------------------
-- 5. PRACTICE_SESSIONS & PRONUNCIATION_ASSESSMENTS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    end_time TIMESTAMPTZ,
    total_duration_seconds INT NOT NULL DEFAULT 0,
    sentences_completed INT NOT NULL DEFAULT 0,
    average_score NUMERIC(5, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.pronunciation_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES public.practice_sessions(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sentence_id UUID REFERENCES public.sentences(id) ON DELETE SET NULL,
    reference_text TEXT NOT NULL,
    audio_recorded_url TEXT,
    overall_score NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    accuracy_score NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    fluency_score NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    completeness_score NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    raw_ai_response JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- -----------------------------------------------------------------------------
-- 6. WORD & PHONEME LEVEL BREAKDOWN
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.word_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES public.pronunciation_assessments(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    accuracy_score NUMERIC(5, 2) NOT NULL,
    error_type TEXT DEFAULT 'None', -- None, Mispronunciation, Omission, Insertion
    word_order INT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.phoneme_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word_assessment_id UUID NOT NULL REFERENCES public.word_assessments(id) ON DELETE CASCADE,
    phoneme_symbol TEXT NOT NULL,
    target_phoneme TEXT NOT NULL,
    accuracy_score NUMERIC(5, 2) NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT true,
    phoneme_order INT NOT NULL
);

-- -----------------------------------------------------------------------------
-- 7. USER_WEAK_PHONEMES (Analytics & Targeted Practice Generation)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_weak_phonemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    phoneme_symbol TEXT NOT NULL,
    fail_count INT NOT NULL DEFAULT 0,
    practice_count INT NOT NULL DEFAULT 0,
    average_score NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    last_failed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_phoneme UNIQUE (user_id, phoneme_symbol)
);

-- -----------------------------------------------------------------------------
-- 8. INDEXES FOR HIGH QUERY PERFORMANCE
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_streaks_user_id ON public.streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_assessments_user_id ON public.pronunciation_assessments(user_id);
CREATE INDEX IF NOT EXISTS idx_assessments_created_at ON public.pronunciation_assessments(created_at);
CREATE INDEX IF NOT EXISTS idx_weak_phonemes_user_id ON public.user_weak_phonemes(user_id);
CREATE INDEX IF NOT EXISTS idx_sentences_lesson_id ON public.sentences(lesson_id);

-- -----------------------------------------------------------------------------
-- 9. SEED DATA FOR DEMO & TESTING
-- -----------------------------------------------------------------------------
INSERT INTO public.lessons (id, title, category, difficulty_level, description)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Mastering the Th-Sounds (/θ/ & /ð/)', 'Minimal Pairs', 1, 'Luyện tập phát âm chuẩn âm răng xát vô thanh và hữu thanh.'),
    ('22222222-2222-2222-2222-222222222222', 'Final Consonants (/t/, /d/, /s/, /z/)', 'Daily Essentials', 2, 'Khắc phục thói quen nuốt âm đuôi của người Việt.'),
    ('33333333-3333-3333-3333-333333333333', 'Smooth Linking & Rhythm', 'Fluency', 3, 'Nối âm tự nhiên và nhịp điệu tiếng Anh.')
ON CONFLICT DO NOTHING;

INSERT INTO public.sentences (id, lesson_id, reference_text, ipa_transcription, focus_phonemes)
VALUES 
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'I think that this is the best path.', 'aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ', ARRAY['θ', 'ð']),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Thank you for thirty thoughtful gifts.', 'θæŋk juː fɔːr ˈθɜːrti ˈθɔːtfəl gɪfts', ARRAY['θ']),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'She works hard and loves cold drinks.', 'ʃiː wɜːrks hɑːrd ænd lʌvz koʊld drɪŋks', ARRAY['s', 'd', 'z'])
ON CONFLICT DO NOTHING;
