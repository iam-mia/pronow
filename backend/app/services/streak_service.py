from datetime import date, datetime, timedelta
from typing import Dict, Any
from app.schemas.assessment import StreakStatus
from app.db.database import DatabaseManager

class StreakService:
    @staticmethod
    def get_or_create_streak(user_id: str) -> Dict[str, Any]:
        return DatabaseManager.get_streak(user_id)

    @staticmethod
    def record_practice_activity(user_id: str) -> StreakStatus:
        streak_data = StreakService.get_or_create_streak(user_id)
        today = date.today()
        today_str = today.isoformat()

        last_date_str = streak_data.get("last_activity_date")
        current_streak = streak_data.get("current_streak", 0)
        longest_streak = streak_data.get("longest_streak", 0)
        freeze_days = streak_data.get("freeze_days_available", 2)

        if not last_date_str:
            current_streak = 1
        else:
            try:
                last_date = date.fromisoformat(last_date_str)
                delta_days = (today - last_date).days

                if delta_days == 0:
                    pass
                elif delta_days == 1:
                    current_streak += 1
                    # Milestone reward: every 7 days gives +1 streak freeze (max 2)
                    if current_streak % 7 == 0 and freeze_days < 2:
                        freeze_days = min(2, freeze_days + 1)
                elif delta_days == 2:
                    if freeze_days > 0:
                        freeze_days -= 1
                        current_streak += 1
                    else:
                        current_streak = 1
                else:
                    current_streak = 1
            except Exception:
                current_streak = 1

        longest_streak = max(longest_streak, current_streak)

        # Save to SQLite database
        DatabaseManager.update_streak(
            user_id=user_id,
            current_streak=current_streak,
            longest_streak=longest_streak,
            last_activity_date=today_str,
            freeze_days=freeze_days
        )

        return StreakStatus(
            current_streak=current_streak,
            longest_streak=longest_streak,
            last_activity_date=today_str,
            freeze_days_available=freeze_days,
            has_practiced_today=True
        )

    @staticmethod
    def get_streak_status(user_id: str) -> StreakStatus:
        streak_data = StreakService.get_or_create_streak(user_id)
        today = date.today()
        last_date_str = streak_data.get("last_activity_date")
        has_practiced_today = False
        
        if last_date_str:
            try:
                last_date = date.fromisoformat(last_date_str)
                if (today - last_date).days == 0:
                    has_practiced_today = True
            except Exception:
                pass

        return StreakStatus(
            current_streak=streak_data.get("current_streak", 0),
            longest_streak=streak_data.get("longest_streak", 0),
            last_activity_date=last_date_str,
            freeze_days_available=streak_data.get("freeze_days_available", 2),
            has_practiced_today=has_practiced_today
        )
