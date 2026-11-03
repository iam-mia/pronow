import io
import re
import math
import wave
import struct
import difflib
from typing import List, Dict, Tuple, Optional
import speech_recognition as sr
import eng_to_ipa as ipa_lib
from gtts import gTTS
from app.core.config import settings
from app.schemas.assessment import (
    PronunciationAssessmentResponse,
    WordScore,
    PhonemeScore,
    TargetedDrill
)

# Detailed phoneme breakdown for core curriculum words
IPA_DICTIONARY: Dict[str, List[Tuple[str, str]]] = {
    "i": [("aɪ", "aɪ")],
    "think": [("θ", "θ"), ("ɪ", "ɪ"), ("ŋ", "ŋ"), ("k", "k")],
    "thank": [("θ", "θ"), ("æ", "æ"), ("ŋ", "ŋ"), ("k", "k")],
    "thirty": [("θ", "θ"), ("ɜːr", "ɜːr"), ("t", "t"), ("i", "i")],
    "thoughtful": [("θ", "θ"), ("ɔː", "ɔː"), ("t", "t"), ("f", "f"), ("ʊ", "ʊ"), ("l", "l")],
    "gifts": [("g", "g"), ("ɪ", "ɪ"), ("f", "f"), ("t", "t"), ("s", "s")],
    "that": [("ð", "ð"), ("æ", "æ"), ("t", "t")],
    "this": [("ð", "ð"), ("ɪ", "ɪ"), ("s", "s")],
    "they": [("ð", "ð"), ("eɪ", "eɪ")],
    "their": [("ð", "ð"), ("ɛər", "ɛər")],
    "the": [("ð", "ð"), ("ə", "ə")],
    "is": [("ɪ", "ɪ"), ("z", "z")],
    "best": [("b", "b"), ("ɛ", "ɛ"), ("s", "s"), ("t", "t")],
    "path": [("p", "p"), ("æ", "æ"), ("θ", "θ")],
    "you": [("j", "j"), ("uː", "uː")],
    "for": [("f", "f"), ("ɔːr", "ɔːr")],
    "she": [("ʃ", "ʃ"), ("iː", "iː")],
    "works": [("w", "w"), ("ɜːr", "ɜːr"), ("k", "k"), ("s", "s")],
    "hard": [("h", "h"), ("ɑːr", "ɑːr"), ("d", "d")],
    "and": [("æ", "æ"), ("n", "n"), ("d", "d")],
    "loves": [("l", "l"), ("ʌ", "ʌ"), ("v", "v"), ("z", "z")],
    "cold": [("k", "k"), ("oʊ", "oʊ"), ("l", "l"), ("d", "d")],
    "drinks": [("d", "d"), ("r", "r"), ("ɪ", "ɪ"), ("ŋ", "ŋ"), ("k", "k"), ("s", "s")],
    "sheep": [("ʃ", "ʃ"), ("iː", "iː"), ("p", "p")],
    "ship": [("ʃ", "ʃ"), ("ɪ", "ɪ"), ("p", "p")],
    "sleep": [("s", "s"), ("l", "l"), ("iː", "iː"), ("p", "p")],
    "slip": [("s", "s"), ("l", "l"), ("ɪ", "ɪ"), ("p", "p")],
    "sink": [("s", "s"), ("ɪ", "ɪ"), ("ŋ", "ŋ"), ("k", "k")],
    "thin": [("θ", "θ"), ("ɪ", "ɪ"), ("n", "n")],
    "father": [("f", "f"), ("ɑː", "ɑː"), ("ð", "ð"), ("ər", "ər")],
    "mother": [("m", "m"), ("ʌ", "ʌ"), ("ð", "ð"), ("ər", "ər")],
    "mouth": [("m", "m"), ("aʊ", "aʊ"), ("θ", "θ")],
    "breath": [("b", "b"), ("r", "r"), ("ɛ", "ɛ"), ("θ", "θ")],
    "breathe": [("b", "b"), ("r", "r"), ("iː", "iː"), ("ð", "ð")],
}

PHONEME_FEEDBACK_GUIDELINES: Dict[str, str] = {
    "θ": "Đặt nhẹ đầu lưỡi ở giữa 2 hàm răng, đẩy hơi êm qua kẽ răng mà không làm rung dây thanh quản (tránh phát âm thành /s/ hoặc /t/).",
    "ð": "Vị trí răng và lưỡi giống âm /θ/, nhưng phải rung mạnh dây thanh quản ở cổ họng (tránh phát âm thành /d/).",
    "k": "Bật dứt khoát âm /k/ ở cuống họng. Không được nuốt âm cuối /k/ trong think, works, like, drink.",
    "t": "Bật dứt khoát đầu lưỡi khỏi chân răng hàm trên, tạo âm bật hơi rõ ràng ở cuối từ. Không được nuốt âm /t/.",
    "d": "Chạm đầu lưỡi vào chân răng trên và bật nhẹ đồng thời rung dây thanh.",
    "s": "Khép hờ hai hàm răng, khóe môi kéo nhẹ sang hai bên và đẩy luồng hơi sắc nét qua kẽ răng.",
    "z": "Khẩu hình giống /s/ nhưng rung dây thanh quản để tạo âm rung đặc trưng.",
    "ʃ": "Chu tròn môi về phía trước, nâng thân lưỡi lên gần vòm miệng và xì hơi dài (như tiếng 'suỵt').",
    "ʒ": "Khẩu hình giống /ʃ/ nhưng rung dây thanh quản (trong measure, vision, pleasure).",
    "tʃ": "Bật âm /t/ và xát /ʃ/ đồng thời chu môi (trong chair, check, teacher).",
    "dʒ": "Khẩu hình giống /tʃ/ nhưng rung mạnh dây thanh (trong job, judge, enjoy).",
    "iː": "Cười mỉm, khóe miệng kéo rộng sang hai bên, lưỡi đưa cao về phía trước (nguyên âm dài).",
    "ɪ": "Mở miệng hơi hờ hững hơn /iː/, phát âm ngắn, dứt khoát (nguyên âm ngắn).",
    "æ": "Hạ cằm sâu, mở miệng rộng theo chiều dọc (trong man, bad, cat).",
    "e": "Mở miệng vừa phải, không hạ cằm quá sâu (trong men, bed, pet).",
    "r": "Uốn nhẹ đầu lưỡi về phía sau nhưng KHÔNG CHẠM vòm họng, tròn nhẹ môi.",
    "l": "Đầu lưỡi chạm chắc vào chân răng hàm trên, luồng hơi thoát ra hai bên thân lưỡi."
}

import hashlib
import os

CACHE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "static", "audio_cache")
os.makedirs(CACHE_DIR, exist_ok=True)

class SpeechService:
    @staticmethod
    def get_audio_duration_seconds(audio_bytes: bytes) -> int:
        try:
            with io.BytesIO(audio_bytes) as bio:
                with wave.open(bio, "rb") as audio_file:
                    return round(audio_file.getnframes() / audio_file.getframerate())
        except (wave.Error, EOFError, OSError, ZeroDivisionError):
            return 0

    @staticmethod
    def get_dynamic_ipa_for_sentence(sentence: str) -> str:
        """Dynamically converts ANY English sentence into standard IPA."""
        try:
            converted = ipa_lib.convert(sentence)
            return f"/{converted}/"
        except Exception:
            return f"/{sentence.lower()}/"

    @staticmethod
    def generate_tts_audio(text: str) -> bytes:
        """
        Generates high quality standard English TTS audio.
        Caches audio to disk so repeated requests load in 0ms without network usage.
        """
        clean_text = text.strip()
        if not clean_text:
            clean_text = "Hello"

        # Hash text for persistent disk cache
        text_hash = hashlib.md5(clean_text.lower().encode('utf-8')).hexdigest()
        cache_path = os.path.join(CACHE_DIR, f"{text_hash}.mp3")

        # 1. Return from disk cache if present
        if os.path.exists(cache_path):
            try:
                with open(cache_path, "rb") as f:
                    return f.read()
            except Exception:
                pass

        # 2. Generate via gTTS and cache to disk
        try:
            tts = gTTS(text=clean_text, lang='en', slow=False)
            fp = io.BytesIO()
            tts.write_to_fp(fp)
            audio_bytes = fp.getvalue()
            with open(cache_path, "wb") as f:
                f.write(audio_bytes)
            return audio_bytes
        except Exception:
            # Fallback if gTTS fails
            return b""

    @staticmethod
    def _get_phonemes_for_word(word: str) -> List[Tuple[str, str]]:
        lower_w = word.lower().strip()
        if lower_w in IPA_DICTIONARY:
            return IPA_DICTIONARY[lower_w]

        try:
            ipa_str = ipa_lib.convert(lower_w).replace("*", "")
            symbols = []
            i = 0
            while i < len(ipa_str):
                # 2-char phonemes
                if i + 1 < len(ipa_str) and ipa_str[i:i+2] in ["iː", "aɪ", "ɔː", "eɪ", "dʒ", "tʃ", "oʊ", "uː", "ɑː", "ɜː", "ɛər", "aʊ"]:
                    symbols.append((ipa_str[i:i+2], ipa_str[i:i+2]))
                    i += 2
                else:
                    symbols.append((ipa_str[i], ipa_str[i]))
                    i += 1
            if symbols:
                return symbols
        except Exception:
            pass

        return [(c, c) for c in lower_w]

    @staticmethod
    def _calculate_audio_energy(audio_bytes: bytes) -> float:
        if len(audio_bytes) < 44:
            return 0.0
        try:
            with io.BytesIO(audio_bytes) as bio:
                with wave.open(bio, 'rb') as wf:
                    frames = wf.readframes(wf.getnframes())
                    sample_width = wf.getsampwidth()
                    if sample_width == 2:
                        count = len(frames) // 2
                        shorts = struct.unpack(f"<{count}h", frames)
                        sum_sq = sum(s * s for s in shorts)
                        rms = math.sqrt(sum_sq / max(1, count))
                        return rms / 32768.0
        except Exception:
            pass

        diffs = [abs(audio_bytes[i] - audio_bytes[i - 1]) for i in range(1, min(len(audio_bytes), 2000))]
        avg_diff = sum(diffs) / max(1, len(diffs))
        return min(1.0, avg_diff / 50.0)

    @staticmethod
    def _verify_trailing_plosive_burst(audio_bytes: bytes, target_consonant: str) -> bool:
        """
        Analyzes the acoustic wave signal in the trailing active speech segment.
        Detects voiceless stop release burst (/k/, /t/, /p/) or fricative friction (/s/, /z/).
        If a user omitted the final /k/ (e.g. said 'thin' instead of 'think'),
        there will be no high-frequency transient burst or high zero-crossing rate.
        """
        if len(audio_bytes) < 800:
            return False

        try:
            with io.BytesIO(audio_bytes) as bio:
                with wave.open(bio, 'rb') as wf:
                    n_frames = wf.getnframes()
                    sample_rate = wf.getframerate()
                    sample_width = wf.getsampwidth()
                    channels = wf.getnchannels()

                    if sample_width != 2 or n_frames < sample_rate * 0.3:
                        return True # Cannot reliably analyze too short audio

                    raw_data = wf.readframes(n_frames)
                    count = len(raw_data) // 2
                    shorts = struct.unpack(f"<{count}h", raw_data)

                    # If stereo, convert to mono by taking first channel
                    if channels == 2:
                        samples = [shorts[i] for i in range(0, count, 2)]
                    else:
                        samples = list(shorts)

                    # 1. Find trailing active speech edge (backtrack from end to skip silence)
                    silence_threshold = 700 # ~2% of max 16-bit range
                    end_idx = len(samples) - 1
                    while end_idx > 0 and abs(samples[end_idx]) < silence_threshold:
                        end_idx -= 1

                    if end_idx < sample_rate * 0.2:
                        return True

                    # 2. Extract trailing 200ms of active speech
                    window_len = int(sample_rate * 0.20)
                    start_idx = max(0, end_idx - window_len)
                    trailing_samples = samples[start_idx:end_idx]

                    if len(trailing_samples) < 50:
                        return True

                    # 3. Calculate Zero Crossing Rate (ZCR)
                    # /k/ release burst & /s/ frication have high frequency noise -> high ZCR (> 0.16)
                    # Nasals /n/, /m/ or trailing vowels have smooth low frequency -> low ZCR (< 0.08)
                    zero_crossings = 0
                    for i in range(1, len(trailing_samples)):
                        if (trailing_samples[i] >= 0 and trailing_samples[i - 1] < 0) or \
                           (trailing_samples[i] < 0 and trailing_samples[i - 1] >= 0):
                            zero_crossings += 1
                    zcr = zero_crossings / max(1, len(trailing_samples))

                    # 4. Calculate Transient Energy Burst (peak variance / max slope)
                    diffs = [abs(trailing_samples[i] - trailing_samples[i-1]) for i in range(1, len(trailing_samples))]
                    max_burst_spike = max(diffs) if diffs else 0
                    avg_diff = sum(diffs) / max(1, len(diffs))
                    burst_ratio = max_burst_spike / max(1.0, avg_diff)

                    # Velar plosive /k/ requires either distinct high ZCR or release burst spike
                    if target_consonant in ["k", "t", "p"]:
                        if zcr >= 0.14 or burst_ratio >= 3.8:
                            return True
                        # If user swallowed /k/ (nasal continuation or silent drop), return False
                        return False
                    elif target_consonant in ["s", "z", "ʃ", "tʃ"]:
                        return zcr >= 0.15

                    return True
        except Exception as e:
            # Fallback to acoustic lenience on raw parse failure
            return True

    @staticmethod
    async def assess_pronunciation(
        audio_bytes: bytes,
        reference_text: str,
        user_id: str
    ) -> PronunciationAssessmentResponse:
        clean_ref_words = re.findall(r"[a-zA-Z']+", reference_text.strip().lower())
        
        # 1. Check for missing or silent audio
        if not audio_bytes or len(audio_bytes) < 400:
            return SpeechService._build_empty_response(clean_ref_words, "Không nhận được tín hiệu âm thanh từ micro. Vui lòng kiểm tra quyền micro và nói lại.")

        energy = SpeechService._calculate_audio_energy(audio_bytes)
        if energy < 0.005:
            return SpeechService._build_empty_response(
                clean_ref_words,
                "Không phát hiện giọng nói hoặc âm lượng quá nhỏ (dưới ngưỡng nghe). Vui lòng nói to và rõ hơn!"
            )

        # 2. Speech-to-Text Recognition with Alternative Hypotheses Inspection
        recognized_text = ""
        stt_alternatives: List[str] = []
        recognizer = sr.Recognizer()
        recognizer.energy_threshold = 300
        
        try:
            with io.BytesIO(audio_bytes) as bio:
                with sr.AudioFile(bio) as source:
                    audio_data = recognizer.record(source)
                    # Request full alternative hypotheses from Google STT
                    stt_raw_result = recognizer.recognize_google(audio_data, language="en-US", show_all=True)
                    if isinstance(stt_raw_result, dict) and "alternative" in stt_raw_result:
                        alts = stt_raw_result["alternative"]
                        if alts:
                            recognized_text = alts[0].get("transcript", "").lower()
                            stt_alternatives = [a.get("transcript", "").lower() for a in alts]
                    elif isinstance(stt_raw_result, str):
                        recognized_text = stt_raw_result.lower()
        except sr.UnknownValueError:
            return SpeechService._build_unrecognized_response(
                clean_ref_words,
                "Phát hiện âm thanh nhưng không nhận dạng được từ tiếng Anh nào rõ ràng. Vui lòng phát âm chậm và rõ từng từ."
            )
        except Exception:
            recognized_text = ""

        # 3. Align Words and Run Strict Acoustic Verification
        return SpeechService._align_and_score(clean_ref_words, recognized_text, audio_bytes, stt_alternatives)

    @staticmethod
    def _align_and_score(
        clean_ref_words: List[str],
        recognized_text: str,
        audio_bytes: bytes = b"",
        stt_alternatives: Optional[List[str]] = None
    ) -> PronunciationAssessmentResponse:
        spoken_words = re.findall(r"[a-zA-Z']+", recognized_text.strip().lower())
        alts_text = " ".join(stt_alternatives or []).lower()
        
        # Robust sequence matcher alignment to prevent word shift when user skips words!
        matcher = difflib.SequenceMatcher(None, clean_ref_words, spoken_words)
        opcodes = matcher.get_opcodes()

        word_scores: List[WordScore] = []
        weak_phonemes_found = set()
        total_phoneme_scores = []
        correctly_pronounced_words = 0

        # Build aligned mapping for each reference word
        ref_to_spoken_map: Dict[int, Optional[str]] = {}
        for tag, i1, i2, j1, j2 in opcodes:
            if tag == 'equal':
                for k in range(i2 - i1):
                    ref_to_spoken_map[i1 + k] = spoken_words[j1 + k]
            elif tag == 'replace':
                # Pair replaced words if possible
                num_replace = min(i2 - i1, j2 - j1)
                for k in range(num_replace):
                    ref_to_spoken_map[i1 + k] = spoken_words[j1 + k]
                for k in range(num_replace, i2 - i1):
                    ref_to_spoken_map[i1 + k] = None # Omitted
            elif tag == 'delete':
                for k in range(i1, i2):
                    ref_to_spoken_map[k] = None # Omitted

        # Now evaluate each word and its phonemes individually
        for idx, ref_w in enumerate(clean_ref_words):
            spoken_w = ref_to_spoken_map.get(idx)
            ref_phonemes = SpeechService._get_phonemes_for_word(ref_w)

            if spoken_w is None:
                # OMISSION (e.g. user skipped this word!)
                phoneme_scores_list = [
                    PhonemeScore(
                        symbol=sym,
                        target_phoneme=t,
                        accuracy_score=0.0,
                        is_correct=False,
                        feedback="Từ này bị bỏ qua (chưa phát âm)."
                    )
                    for t, sym in ref_phonemes
                ]
                word_scores.append(
                    WordScore(
                        word=ref_w,
                        accuracy_score=0.0,
                        error_type="Omission",
                        phonemes=phoneme_scores_list
                    )
                )
                total_phoneme_scores.extend([0.0] * len(ref_phonemes))
                continue

            # Compare Spoken Word vs Target Word at the Phoneme level
            spoken_phonemes = SpeechService._get_phonemes_for_word(spoken_w)
            spoken_symbols = [s for _, s in spoken_phonemes]
            ref_symbols = [s for _, s in ref_phonemes]

            is_exact_word = (spoken_w == ref_w)
            phoneme_scores_list = []
            word_phoneme_accs = []

            for p_idx, (target_p, sym) in enumerate(ref_phonemes):
                is_final_consonant = (p_idx == len(ref_phonemes) - 1) and sym in ["k", "t", "d", "s", "z", "p", "θ", "ð"]
                
                p_acc = 90.0
                feedback = None

                # 1. Acoustic verification for final plosives / fricatives (/k/, /t/, /s/)
                is_omitted_by_acoustic = False
                if is_final_consonant and audio_bytes and len(audio_bytes) > 800:
                    # Check if audio trailing wave actually contains stop burst
                    burst_present = SpeechService._verify_trailing_plosive_burst(audio_bytes, sym)
                    # Check if Google STT alternatives caught a missing tail (e.g. "thin" instead of "think")
                    alt_missing_tail = False
                    if sym == "k" and ("thin" in alts_text or "work " in alts_text or "drink " in alts_text or "sin " in alts_text):
                        alt_missing_tail = True

                    if not burst_present or alt_missing_tail:
                        is_omitted_by_acoustic = True

                if is_exact_word:
                    # Target word matched grammatically, but verify if user swallowed final sound
                    if is_final_consonant and is_omitted_by_acoustic:
                        p_acc = 22.0 # Dropped final plosive /k/!
                        feedback = f"Bạn đã nuốt mất âm cuối /{sym}/ (không có âm bật hơi ở cuống họng) dù hệ thống đoán được từ từ ngữ cảnh! Hãy bật dứt khoát âm /{sym}/."
                        weak_phonemes_found.add(sym)
                    elif is_final_consonant and spoken_symbols and spoken_symbols[-1] != sym:
                        p_acc = 25.0 # Missing final plosive/consonant!
                        feedback = PHONEME_FEEDBACK_GUIDELINES.get(sym, f"Đừng nuốt âm cuối /{sym}/!")
                        weak_phonemes_found.add(sym)
                    else:
                        p_acc = 94.0
                else:
                    # Replaced / imperfect match (e.g. "sink" vs "think", "thin" vs "think")
                    if is_final_consonant and is_omitted_by_acoustic:
                        p_acc = 20.0
                        feedback = f"Bạn đã nuốt mất âm cuối /{sym}/. Hãy bật âm rõ ở cuối từ!"
                        weak_phonemes_found.add(sym)
                    elif sym in spoken_symbols:
                        p_acc = 85.0
                    else:
                        # Phoneme was replaced or omitted
                        p_acc = 30.0
                        weak_phonemes_found.add(sym)
                        
                        # Specific feedback for common substitutions
                        if sym == "θ" and ("s" in spoken_symbols or "t" in spoken_symbols):
                            feedback = "Bạn đã đọc /θ/ thành /s/ hoặc /t/. Đặt nhẹ đầu lưỡi giữa 2 hàm răng!"
                        elif sym == "ð" and "d" in spoken_symbols:
                            feedback = "Bạn đã đọc /ð/ thành /d/. Vị trí lưỡi giống /θ/ và rung thanh quản!"
                        elif is_final_consonant:
                            feedback = f"Bạn đã nuốt mất âm cuối /{sym}/. Hãy bật âm rõ ở cuối từ!"
                        else:
                            feedback = PHONEME_FEEDBACK_GUIDELINES.get(sym, f"Phát âm âm /{sym}/ chưa chuẩn.")

                is_correct = (p_acc >= 75.0)
                phoneme_scores_list.append(
                    PhonemeScore(
                        symbol=sym,
                        target_phoneme=target_p,
                        accuracy_score=round(p_acc, 1),
                        is_correct=is_correct,
                        feedback=feedback
                    )
                )
                word_phoneme_accs.append(p_acc)
                total_phoneme_scores.append(p_acc)

            avg_w_acc = round(sum(word_phoneme_accs) / max(1, len(word_phoneme_accs)), 1)
            err_type = "None"
            if avg_w_acc >= 75.0:
                correctly_pronounced_words += 1
            elif avg_w_acc < 50.0:
                err_type = "Mispronunciation"
            else:
                err_type = "Minor Error"

            word_scores.append(
                WordScore(
                    word=ref_w,
                    accuracy_score=avg_w_acc,
                    error_type=err_type,
                    phonemes=phoneme_scores_list
                )
            )

        completeness = round((len([w for w in word_scores if w.error_type != "Omission"]) / max(1, len(clean_ref_words))) * 100.0, 1)
        accuracy = round(sum(total_phoneme_scores) / max(1, len(total_phoneme_scores)), 1)
        fluency = round((correctly_pronounced_words / max(1, len(clean_ref_words))) * 95.0, 1)
        overall = round((accuracy * 0.6) + (fluency * 0.3) + (completeness * 0.1), 1)

        recommendations = SpeechService._generate_recommendations(weak_phonemes_found)

        return PronunciationAssessmentResponse(
            overall_score=overall,
            accuracy_score=accuracy,
            fluency_score=fluency,
            completeness_score=completeness,
            words=word_scores,
            weak_phonemes=list(weak_phonemes_found),
            recommendations=recommendations
        )

    @staticmethod
    def _build_empty_response(clean_ref_words: List[str], message: str) -> PronunciationAssessmentResponse:
        word_scores = [
            WordScore(
                word=w,
                accuracy_score=0.0,
                error_type="Omission",
                phonemes=[
                    PhonemeScore(
                        symbol=sym,
                        target_phoneme=t,
                        accuracy_score=0.0,
                        is_correct=False,
                        feedback=message
                    )
                    for t, sym in SpeechService._get_phonemes_for_word(w)
                ]
            )
            for w in clean_ref_words
        ]
        return PronunciationAssessmentResponse(
            overall_score=0.0,
            accuracy_score=0.0,
            fluency_score=0.0,
            completeness_score=0.0,
            words=word_scores,
            weak_phonemes=[],
            recommendations=[
                TargetedDrill(
                    phoneme="Notice",
                    drill_title="Lưu ý thu âm",
                    practice_words=[],
                    mouth_guidance=message
                )
            ]
        )

    @staticmethod
    def _build_unrecognized_response(clean_ref_words: List[str], message: str) -> PronunciationAssessmentResponse:
        word_scores = [
            WordScore(
                word=w,
                accuracy_score=20.0,
                error_type="Unclear",
                phonemes=[
                    PhonemeScore(
                        symbol=sym,
                        target_phoneme=t,
                        accuracy_score=20.0,
                        is_correct=False,
                        feedback=message
                    )
                    for t, sym in SpeechService._get_phonemes_for_word(w)
                ]
            )
            for w in clean_ref_words
        ]
        return PronunciationAssessmentResponse(
            overall_score=20.0,
            accuracy_score=20.0,
            fluency_score=20.0,
            completeness_score=30.0,
            words=word_scores,
            weak_phonemes=["θ", "ð"],
            recommendations=SpeechService._generate_recommendations({"θ", "ð"})
        )

    @staticmethod
    def _generate_recommendations(weak_phonemes: set) -> List[TargetedDrill]:
        recommendations: List[TargetedDrill] = []
        for p in weak_phonemes:
            guidance = PHONEME_FEEDBACK_GUIDELINES.get(p, "Luyện tập mở khẩu hình tự nhiên và phát âm dứt khoát.")
            drill_words = [k for k, v in IPA_DICTIONARY.items() if any(sym == p for _, sym in v)]
            if not drill_words:
                drill_words = ["think", "thank", "path"]
            recommendations.append(
                TargetedDrill(
                    phoneme=p,
                    drill_title=f"Luyện tập phát âm chuẩn âm /{p}/",
                    practice_words=drill_words[:5],
                    mouth_guidance=guidance
                )
            )
        return recommendations
