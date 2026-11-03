from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Response
from typing import Optional, List
from app.schemas.assessment import (
    PronunciationAssessmentResponse,
    StreakStatus,
    DailyGoalRequest,
    DailyGoalResponse,
    TargetedDrill
)
from app.services.speech_service import SpeechService
from app.services.streak_service import StreakService
from app.db.database import DatabaseManager

api_router = APIRouter()

@api_router.post("/assess-pronunciation", response_model=PronunciationAssessmentResponse)
async def assess_pronunciation_endpoint(
    audio: Optional[UploadFile] = File(None),
    reference_text: str = Form(...),
    user_id: str = Form("default-user")
):
    """
    Submits user audio file and reference text for real speech & phoneme assessment.
    Updates daily aggregate statistics and streak without storing the individual attempt.
    """
    audio_bytes = b""
    if audio:
        audio_bytes = await audio.read()

    # 1. Run real speech pronunciation assessment
    result = await SpeechService.assess_pronunciation(audio_bytes, reference_text, user_id)

    if audio_bytes and result.overall_score > 0:
        DatabaseManager.record_daily_activity(
            user_id=user_id,
            score=result.overall_score,
            duration_seconds=SpeechService.get_audio_duration_seconds(audio_bytes),
        )

    # 2. Update user streak if user actually spoke (> 0)
    if result.overall_score > 0:
        streak_status = StreakService.record_practice_activity(user_id)
        result.streak_info = streak_status.model_dump()
    else:
        streak_status = StreakService.get_streak_status(user_id)
        result.streak_info = streak_status.model_dump()

    return result

@api_router.get("/transcribe")
async def transcribe_text_endpoint(text: str):
    """Dynamically converts any arbitrary English sentence into standard IPA."""
    ipa = SpeechService.get_dynamic_ipa_for_sentence(text)
    return {"text": text, "ipa": ipa}

@api_router.get("/tts")
async def text_to_speech_endpoint(text: str):
    """Generates standard English audio reading for model listening."""
    audio_bytes = SpeechService.generate_tts_audio(text)
    return Response(content=audio_bytes, media_type="audio/mpeg")

@api_router.get("/daily-activity/{user_id}")
async def get_daily_activity_endpoint(user_id: str, days: int = 31):
    """Returns aggregate activity by day without storing individual practice attempts."""
    if not 1 <= days <= 365:
        raise HTTPException(status_code=400, detail="days must be between 1 and 365")
    return DatabaseManager.get_daily_activity(user_id, days=days)

# --- Lesson Progress Endpoints ---
@api_router.post("/lesson-progress")
async def save_lesson_progress_endpoint(
    user_id: str = Form("default-user"),
    lesson_id: str = Form(...),
    sentence_id: str = Form(...),
    sentence_text: str = Form(...),
    score: float = Form(...)
):
    """
    Saves user practice result for a fixed lesson sentence.
    Sentence is passed only if score >= 80.
    Updates daily streak if score > 0.
    """
    res = DatabaseManager.record_lesson_progress(
        user_id=user_id,
        lesson_id=lesson_id,
        sentence_id=sentence_id,
        sentence_text=sentence_text,
        score=score
    )
    if score > 0:
        StreakService.record_practice_activity(user_id)
    return res

@api_router.get("/lesson-progress/{user_id}")
async def get_lesson_progress_endpoint(user_id: str):
    """Retrieves all completed or attempted lesson sentences with highest score."""
    return DatabaseManager.get_lesson_progress(user_id)

# --- Saved Custom Sentences (Notebook) Endpoints ---
@api_router.post("/saved-sentences")
async def save_custom_sentence_endpoint(
    user_id: str = Form("default-user"),
    sentence_text: str = Form(...),
    ipa: str = Form(...)
):
    """User voluntarily bookmarks an arbitrary custom sentence to practice again later."""
    return DatabaseManager.save_custom_sentence(user_id, sentence_text, ipa)

@api_router.get("/saved-sentences/{user_id}")
async def get_saved_sentences_endpoint(user_id: str):
    """Retrieves user's saved arbitrary custom sentences."""
    return DatabaseManager.get_saved_custom_sentences(user_id)

@api_router.delete("/saved-sentences/{sentence_id}")
async def delete_saved_sentence_endpoint(sentence_id: int, user_id: str = "default-user"):
    """Removes a sentence from the user's custom practice notebook."""
    success = DatabaseManager.delete_saved_custom_sentence(user_id, sentence_id)
    return {"success": success}

@api_router.get("/streaks/{user_id}", response_model=StreakStatus)
async def get_streak_endpoint(user_id: str):
    """Retrieves current streak, longest streak, and streak freeze status."""
    return StreakService.get_streak_status(user_id)

@api_router.get("/daily-goals/{user_id}", response_model=DailyGoalResponse)
async def get_daily_goal_endpoint(user_id: str):
    """Retrieves user's daily practice goals and progress for today."""
    return DailyGoalResponse(
        user_id=user_id,
        target_minutes=15,
        target_sentences=10,
        reminder_time_hour=20,
        reminder_time_minute=0,
        is_reminder_enabled=True,
        today_minutes_completed=0,
        today_sentences_completed=0
    )
