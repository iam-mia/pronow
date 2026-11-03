import sqlite3
import os
from datetime import datetime, date, timedelta
from typing import Dict, Any, List, Optional

DB_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "pronow.db")

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Streaks
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS streaks (
            user_id TEXT PRIMARY KEY,
            current_streak INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0,
            last_activity_date TEXT,
            freeze_days_available INTEGER NOT NULL DEFAULT 2,
            updated_at TEXT NOT NULL
        )
    """)

    # 2. Daily Goals
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS daily_goals (
            user_id TEXT PRIMARY KEY,
            target_minutes INTEGER NOT NULL DEFAULT 15,
            target_sentences INTEGER NOT NULL DEFAULT 10,
            reminder_time_hour INTEGER NOT NULL DEFAULT 20,
            reminder_time_minute INTEGER NOT NULL DEFAULT 0,
            is_reminder_enabled INTEGER NOT NULL DEFAULT 1,
            today_minutes_completed INTEGER NOT NULL DEFAULT 0,
            today_sentences_completed INTEGER NOT NULL DEFAULT 0,
            today_date TEXT NOT NULL
        )
    """)

    # Daily aggregates support goals, the calendar, and score charts without per-attempt logs.
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS daily_activity (
            user_id TEXT NOT NULL,
            activity_date TEXT NOT NULL,
            score_total REAL NOT NULL DEFAULT 0,
            assessment_count INTEGER NOT NULL DEFAULT 0,
            duration_seconds INTEGER NOT NULL DEFAULT 0,
            successful_sentences INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, activity_date)
        )
    """)

    cursor.execute("DROP TABLE IF EXISTS practice_history")
    cursor.execute("DROP TABLE IF EXISTS user_weak_phonemes")

    # 5. Lesson Progress (Fixed sentences per lesson, >= 80 to pass, keeps best score)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS lesson_progress (
            user_id TEXT NOT NULL,
            lesson_id TEXT NOT NULL,
            sentence_id TEXT NOT NULL,
            sentence_text TEXT NOT NULL,
            best_score REAL NOT NULL DEFAULT 0.0,
            is_passed INTEGER NOT NULL DEFAULT 0,
            attempts_count INTEGER NOT NULL DEFAULT 0,
            last_attempt_at TEXT NOT NULL,
            PRIMARY KEY (user_id, sentence_id)
        )
    """)

    # 6. Saved Custom Sentences (User notebook of arbitrary custom sentences for re-practicing)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS saved_custom_sentences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            sentence_text TEXT NOT NULL,
            ipa TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)

    conn.commit()
    conn.close()

# Initialize DB tables on import
init_db()

# DB Access Functions
class DatabaseManager:
    @staticmethod
    def get_streak(user_id: str) -> Dict[str, Any]:
        conn = get_db_connection()
        row = conn.execute("SELECT * FROM streaks WHERE user_id = ?", (user_id,)).fetchone()
        conn.close()
        if row:
            return dict(row)
        return {
            "user_id": user_id,
            "current_streak": 0,
            "longest_streak": 0,
            "last_activity_date": None,
            "freeze_days_available": 2,
            "updated_at": datetime.utcnow().isoformat()
        }

    @staticmethod
    def update_streak(user_id: str, current_streak: int, longest_streak: int, last_activity_date: str, freeze_days: int):
        conn = get_db_connection()
        now_str = datetime.utcnow().isoformat()
        conn.execute("""
            INSERT INTO streaks (user_id, current_streak, longest_streak, last_activity_date, freeze_days_available, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                current_streak = excluded.current_streak,
                longest_streak = excluded.longest_streak,
                last_activity_date = excluded.last_activity_date,
                freeze_days_available = excluded.freeze_days_available,
                updated_at = excluded.updated_at
        """, (user_id, current_streak, longest_streak, last_activity_date, freeze_days, now_str))
        conn.commit()
        conn.close()

    @staticmethod
    def record_daily_activity(
        user_id: str,
        score: float,
        duration_seconds: int,
        activity_date: Optional[date] = None,
    ) -> None:
        day = (activity_date or date.today()).isoformat()
        conn = get_db_connection()
        conn.execute("""
            INSERT INTO daily_activity (
                user_id, activity_date, score_total, assessment_count,
                duration_seconds, successful_sentences
            ) VALUES (?, ?, ?, 1, ?, ?)
            ON CONFLICT(user_id, activity_date) DO UPDATE SET
                score_total = score_total + excluded.score_total,
                assessment_count = assessment_count + 1,
                duration_seconds = duration_seconds + excluded.duration_seconds,
                successful_sentences = successful_sentences + excluded.successful_sentences
        """, (user_id, day, score, max(0, duration_seconds), int(score >= 80.0)))
        conn.commit()
        conn.close()

    @staticmethod
    def get_daily_activity(user_id: str, days: int = 31) -> List[Dict[str, Any]]:
        conn = get_db_connection()
        start_date = (date.today() - timedelta(days=days - 1)).isoformat()
        rows = conn.execute("""
            SELECT activity_date AS practice_date,
                   ROUND(score_total / assessment_count, 1) AS average_score,
                   assessment_count AS attempts_count,
                   duration_seconds / 60.0 AS minutes_completed,
                   successful_sentences AS sentences_completed
            FROM daily_activity
            WHERE user_id = ? AND activity_date >= ?
            ORDER BY activity_date
        """, (user_id, start_date)).fetchall()
        conn.close()
        return [dict(row) for row in rows]

    @staticmethod
    def record_lesson_progress(
        user_id: str,
        lesson_id: str,
        sentence_id: str,
        sentence_text: str,
        score: float
    ) -> Dict[str, Any]:
        """
        Records practice attempt for a fixed lesson sentence.
        A sentence is ONLY passed if score >= 80.0.
        Always preserves the user's best score.
        """
        conn = get_db_connection()
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Check existing record
        row = conn.execute("""
            SELECT best_score, is_passed, attempts_count
            FROM lesson_progress
            WHERE user_id = ? AND sentence_id = ?
        """, (user_id, sentence_id)).fetchone()

        if row:
            current_best = max(row["best_score"], score)
            new_passed = 1 if (row["is_passed"] == 1 or score >= 80.0) else 0
            new_attempts = row["attempts_count"] + 1

            conn.execute("""
                UPDATE lesson_progress
                SET best_score = ?, is_passed = ?, attempts_count = ?, last_attempt_at = ?
                WHERE user_id = ? AND sentence_id = ?
            """, (current_best, new_passed, new_attempts, now_str, user_id, sentence_id))
        else:
            current_best = score
            new_passed = 1 if score >= 80.0 else 0
            new_attempts = 1
            conn.execute("""
                INSERT INTO lesson_progress (
                    user_id, lesson_id, sentence_id, sentence_text,
                    best_score, is_passed, attempts_count, last_attempt_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (user_id, lesson_id, sentence_id, sentence_text, current_best, new_passed, new_attempts, now_str))

        conn.commit()
        conn.close()

        return {
            "user_id": user_id,
            "lesson_id": lesson_id,
            "sentence_id": sentence_id,
            "score": score,
            "best_score": current_best,
            "is_passed": bool(new_passed),
            "attempts_count": new_attempts,
            "last_attempt_at": now_str
        }

    @staticmethod
    def get_lesson_progress(user_id: str) -> List[Dict[str, Any]]:
        conn = get_db_connection()
        rows = conn.execute("""
            SELECT user_id, lesson_id, sentence_id, sentence_text,
                   best_score, is_passed, attempts_count, last_attempt_at
            FROM lesson_progress
            WHERE user_id = ?
            ORDER BY lesson_id, sentence_id
        """, (user_id,)).fetchall()
        conn.close()
        return [dict(r) for r in rows]

    @staticmethod
    def save_custom_sentence(user_id: str, sentence_text: str, ipa: str) -> Dict[str, Any]:
        """Saves a custom or arbitrary user sentence to their practice notebook."""
        conn = get_db_connection()
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor = conn.cursor()

        # Check if already exists
        existing = conn.execute("""
            SELECT id FROM saved_custom_sentences
            WHERE user_id = ? AND LOWER(sentence_text) = LOWER(?)
        """, (user_id, sentence_text.strip())).fetchone()

        if existing:
            conn.close()
            return {"id": existing["id"], "user_id": user_id, "sentence_text": sentence_text, "ipa": ipa, "created_at": now_str, "status": "already_saved"}

        cursor.execute("""
            INSERT INTO saved_custom_sentences (user_id, sentence_text, ipa, created_at)
            VALUES (?, ?, ?, ?)
        """, (user_id, sentence_text.strip(), ipa.strip(), now_str))
        new_id = cursor.lastrowid
        conn.commit()
        conn.close()

        return {"id": new_id, "user_id": user_id, "sentence_text": sentence_text, "ipa": ipa, "created_at": now_str, "status": "saved"}

    @staticmethod
    def get_saved_custom_sentences(user_id: str) -> List[Dict[str, Any]]:
        conn = get_db_connection()
        rows = conn.execute("""
            SELECT id, user_id, sentence_text, ipa, created_at
            FROM saved_custom_sentences
            WHERE user_id = ?
            ORDER BY id DESC
        """, (user_id,)).fetchall()
        conn.close()
        return [dict(r) for r in rows]

    @staticmethod
    def delete_saved_custom_sentence(user_id: str, sentence_id: int) -> bool:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM saved_custom_sentences WHERE id = ? AND user_id = ?", (sentence_id, user_id))
        affected = cursor.rowcount
        conn.commit()
        conn.close()
        return affected > 0
