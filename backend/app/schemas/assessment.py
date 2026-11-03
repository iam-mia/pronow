from typing import List, Optional
from pydantic import BaseModel, Field

class PhonemeScore(BaseModel):
    symbol: str = Field(..., description="Ký hiệu âm vị IPA")
    target_phoneme: str = Field(..., description="Âm vị chuẩn kỳ vọng")
    accuracy_score: float = Field(..., description="Điểm độ chính xác 0-100")
    is_correct: bool = Field(True, description="Đạt chuẩn (>= 75)")
    feedback: Optional[str] = Field(None, description="Gợi ý cải thiện khẩu hình")

class WordScore(BaseModel):
    word: str
    accuracy_score: float
    error_type: str = "None" # None, Mispronunciation, Omission, Insertion
    phonemes: List[PhonemeScore] = []

class TargetedDrill(BaseModel):
    phoneme: str
    drill_title: str
    practice_words: List[str]
    mouth_guidance: str

class PronunciationAssessmentResponse(BaseModel):
    overall_score: float
    accuracy_score: float
    fluency_score: float
    completeness_score: float
    words: List[WordScore]
    weak_phonemes: List[str] = []
    recommendations: List[TargetedDrill] = []
    streak_info: Optional[dict] = None

class StreakStatus(BaseModel):
    current_streak: int
    longest_streak: int
    last_activity_date: Optional[str]
    freeze_days_available: int
    has_practiced_today: bool

class DailyGoalRequest(BaseModel):
    target_minutes: int = 15
    target_sentences: int = 10
    reminder_time_hour: int = 20
    reminder_time_minute: int = 0
    is_reminder_enabled: bool = True

class DailyGoalResponse(DailyGoalRequest):
    user_id: str
    today_minutes_completed: int = 0
    today_sentences_completed: int = 0
