import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notion_theme.dart';
import '../../core/api_service.dart';
import '../../core/discipline_state.dart';

class LessonModel {
  final String id;
  final String title;
  final String category;
  final String level;
  final String icon;
  final String description;
  final String theory;
  final String commonMistakes;
  final String mouthDiagramUrl;
  final String diagramCaption;
  final List<SentenceModel> sentences;

  LessonModel({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.icon,
    required this.description,
    required this.theory,
    required this.commonMistakes,
    required this.mouthDiagramUrl,
    required this.diagramCaption,
    required this.sentences,
  });
}

class SentenceModel {
  final String id;
  final String text;
  final String ipa;
  final String focusPhonemes;

  SentenceModel({
    required this.id,
    required this.text,
    required this.ipa,
    required this.focusPhonemes,
  });
}

final List<LessonModel> tenLessons = [
  LessonModel(
    id: '1',
    title: 'Âm Răng Xát Vô Thanh /θ/',
    category: 'Cặp Âm Răng',
    level: 'Level 1',
    icon: '👅',
    description:
        'Chinh phục âm Th vô thanh xuất hiện trong think, thank, path.',
    theory: 'Đặt nhẹ đầu lưỡi ở giữa hai hàm răng trên và dưới (lưỡi đưa ra khoảng 0.5cm). Đẩy luồng hơi nhẹ và đều qua khe giữa răng và lưỡi. Chú ý: Dây thanh quản TUYỆT ĐỐI KHÔNG rung.',
    commonMistakes: 'Người Việt hay rụt lưỡi vào trong và phát âm thành âm /s/ (thay vì "think" thì nói "sink") hoặc thành âm /t/ (thành "tink").',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Voiceless_dental_fricative_%28close%29.svg/320px-Voiceless_dental_fricative_%28close%29.svg.png',
    diagramCaption: 'Sơ đồ khẩu hình âm /θ/: Đầu lưỡi đặt nhẹ kẹp giữa 2 hàm răng, đẩy luồng hơi êm.',
    sentences: [
      SentenceModel(
        id: '1_1',
        text: 'I think that this is the best path.',
        ipa: '/aɪ θɪŋk ðæt ðɪs ɪz ðə bɛst pæθ/',
        focusPhonemes: '/θ/ & /ð/',
      ),
      SentenceModel(
        id: '1_2',
        text: 'Thank you for thirty thoughtful gifts.',
        ipa: '/θæŋk juː fɔːr ˈθɜːrti ˈθɔːtfəl gɪfts/',
        focusPhonemes: '/θ/',
      ),
      SentenceModel(
        id: '1_3',
        text: 'Nothing is worth more than good health.',
        ipa: '/ˈnʌθɪŋ ɪz wɜːrθ mɔːr ðæn gʊd hɛlθ/',
        focusPhonemes: '/θ/',
      ),
      SentenceModel(
        id: '1_4',
        text: 'Open your mouth and take a deep breath.',
        ipa: '/ˈoʊpən jɔːr maʊθ ænd teɪk ə diːp brɛθ/',
        focusPhonemes: '/θ/',
      ),
    ],
  ),
  LessonModel(
    id: '2',
    title: 'Âm Răng Xát Hữu Thanh /ð/',
    category: 'Cặp Âm Răng',
    level: 'Level 1',
    icon: '🎯',
    description: 'Phân biệt âm Th rung trong this, that, they, father.',
    theory: 'Vị trí răng và đầu lưỡi đặt hoàn toàn giống âm /θ/. Điểm khác biệt duy nhất: Bạn phải RUNG mạnh dây thanh quản khi đẩy hơi ra, tạo tiếng rè nhẹ ở cổ họng.',
    commonMistakes: 'Thường bị phát âm nhầm thành âm /d/ (nói "that" thành "đát", "this" thành "đít").',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Voiced_dental_fricative_%28close%29.svg/320px-Voiced_dental_fricative_%28close%29.svg.png',
    diagramCaption: 'Sơ đồ khẩu hình âm /ð/: Vị trí lưỡi kẹp giữa 2 răng kèm rung mạnh dây thanh quản.',
    sentences: [
      SentenceModel(
        id: '2_1',
        text: 'They love their father and mother.',
        ipa: '/ðeɪ lʌv ðɛər ˈfɑːðər ænd ˈmʌðər/',
        focusPhonemes: '/ð/',
      ),
      SentenceModel(
        id: '2_2',
        text: 'This is better than that other option.',
        ipa: '/ðɪs ɪz ˈbɛtər ðæn ðæt ˈʌðər ˈɒpʃən/',
        focusPhonemes: '/ð/',
      ),
      SentenceModel(
        id: '2_3',
        text: 'Together they walk through the weather.',
        ipa: '/təˈgɛðər ðeɪ wɔːk θruː ðə ˈwɛðər/',
        focusPhonemes: '/ð/',
      ),
      SentenceModel(
        id: '2_4',
        text: 'Breathe deeply and feel the fresh air.',
        ipa: '/briːð ˈdiːpli ænd fiːl ðə frɛʃ ɛər/',
        focusPhonemes: '/ð/',
      ),
    ],
  ),
  LessonModel(
    id: '3',
    title: 'Phụ Âm Bật Cuối /t/ & /d/',
    category: 'Âm Đuôi Cốt Lõi',
    level: 'Level 1',
    icon: '⚡',
    description:
        'Khắc phục triệt để lỗi nuốt âm đuôi t/d làm biến đổi nghĩa từ.',
    theory: 'Chạm chắc đầu lưỡi vào chân răng hàm trên, giữ hơi trong miệng rồi bật dứt khoát đầu lưỡi xuống. Âm /t/ bật hơi gió, âm /d/ rung thanh quản.',
    commonMistakes: 'Nuốt hẳn âm cuối, khiến người bản ngữ không phân biệt được thời quá khứ (walk vs walked, need vs needed).',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Voiceless_alveolar_plosive.svg/320px-Voiceless_alveolar_plosive.svg.png',
    diagramCaption: 'Sơ đồ khẩu hình âm /t/ & /d/: Đầu lưỡi áp sát chân răng trên nén hơi rồi bật mạnh.',
    sentences: [
      SentenceModel(
        id: '3_1',
        text: 'She works hard and loves cold drinks.',
        ipa: '/ʃiː wɜːrks hɑːrd ænd lʌvz koʊld drɪŋks/',
        focusPhonemes: '/d/ & /t/',
      ),
      SentenceModel(
        id: '3_2',
        text: 'He walked fast past the lost post.',
        ipa: '/hiː wɔːkt fæst pæst ðə lɔːst poʊst/',
        focusPhonemes: '/t/',
      ),
      SentenceModel(
        id: '3_3',
        text: 'I decided to start a great project.',
        ipa: '/aɪ dɪˈsaɪdɪd tuː stɑːrt ə greɪt ˈprɒdʒɛkt/',
        focusPhonemes: '/t/ & /d/',
      ),
      SentenceModel(
        id: '3_4',
        text: 'The red boat sailed across the wide lake.',
        ipa: '/ðə rɛd boʊt seɪld əˈkrɒs ðə waɪd leɪk/',
        focusPhonemes: '/t/ & /d/',
      ),
    ],
  ),
  LessonModel(
    id: '4',
    title: 'Cặp Phụ Âm Xát /s/ & /z/',
    category: 'Âm Đuôi Cốt Lõi',
    level: 'Level 1',
    icon: '🔔',
    description: 'Phát âm chuẩn âm đuôi s/es số nhiều và chia động từ.',
    theory: 'Hai hàm răng khép hờ, khóe môi kéo nhẹ sang hai bên. Đẩy luồng hơi sắc nét qua kẽ răng. Âm /s/ không rung, âm /z/ rung mạnh dây thanh.',
    commonMistakes: 'Thêm /s/ bừa bãi vào giữa các từ, hoặc quên hoàn toàn âm /s/, /z/ ở cuối từ.',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Voiceless_alveolar_fricative.svg/320px-Voiceless_alveolar_fricative.svg.png',
    diagramCaption: 'Sơ đồ âm /s/ & /z/: Hai hàm răng khép hờ, đẩy luồng hơi sắc nét qua kẽ răng.',
    sentences: [
      SentenceModel(
        id: '4_1',
        text: 'These roses smell so sweet in the sun.',
        ipa: '/ðiːz ˈroʊzɪz smɛl soʊ swiːt ɪn ðə sʌn/',
        focusPhonemes: '/s/ & /z/',
      ),
      SentenceModel(
        id: '4_2',
        text: 'His cousins always visit on Sundays.',
        ipa: '/hɪz ˈkʌzənz ˈɔːlweɪz ˈvɪzɪt ɒn ˈsʌndeɪz/',
        focusPhonemes: '/z/',
      ),
      SentenceModel(
        id: '4_3',
        text: 'She places seven books on the desk.',
        ipa: '/ʃiː ˈpleɪsɪz ˈsɛvən bʊks ɒn ðə dɛsk/',
        focusPhonemes: '/s/ & /z/',
      ),
      SentenceModel(
        id: '4_4',
        text: 'The noise outside causes a lot of stress.',
        ipa: '/ðə nɔɪz ˌaʊtˈsaɪd ˈkɔːzɪz ə lɒt ɒv strɛs/',
        focusPhonemes: '/s/ & /z/',
      ),
    ],
  ),
  LessonModel(
    id: '5',
    title: 'Âm Chu Môi /ʃ/ & /ʒ/',
    category: 'Phụ Âm Nâng Cao',
    level: 'Level 2',
    icon: '👄',
    description: 'Phát âm chuẩn âm s nặng trong she, shop, vision, casual.',
    theory: 'Chu tròn môi về phía trước như đang ra hiệu "suỵt". Thân lưỡi nâng lên gần vòm họng trên và xì hơi đều. Âm /ʒ/ phát âm tương tự nhưng rung cổ họng.',
    commonMistakes:
        'Phát âm /ʃ/ thành /s/ nhẹ thông thường (nói "she" thành "si").',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Voiceless_postalveolar_fricative.svg/320px-Voiceless_postalveolar_fricative.svg.png',
    diagramCaption: 'Sơ đồ âm /ʃ/ & /ʒ/: Chu tròn môi về phía trước, thân lưỡi nâng sát vòm họng trên.',
    sentences: [
      SentenceModel(
        id: '5_1',
        text: 'She sells seashells by the seashore.',
        ipa: '/ʃiː sɛlz ˈsiːˌʃɛlz baɪ ðə ˈsiːˌʃɔːr/',
        focusPhonemes: '/ʃ/ & /s/',
      ),
      SentenceModel(
        id: '5_2',
        text: 'It is a pleasure to measure this vision.',
        ipa: '/ɪt ɪz ə ˈplɛʒər tuː ˈmɛʒər ðɪs ˈvɪʒən/',
        focusPhonemes: '/ʒ/',
      ),
      SentenceModel(
        id: '5_3',
        text: 'Should we finish shopping before dinner?',
        ipa: '/ʃʊd wiː ˈfɪnɪʃ ˈʃɒpɪŋ bɪˈfɔːr ˈdɪnər/',
        focusPhonemes: '/ʃ/',
      ),
      SentenceModel(
        id: '5_4',
        text: 'He wore casual clothes on the special occasion.',
        ipa: '/hiː wɔːr ˈkæʒuəl kloʊðz ɒn ðə ˈspɛʃəl əˈkeɪʒən/',
        focusPhonemes: '/ʃ/ & /ʒ/',
      ),
    ],
  ),
  LessonModel(
    id: '6',
    title: 'Cặp Âm Tắc Xát /tʃ/ & /dʒ/',
    category: 'Phụ Âm Nâng Cao',
    level: 'Level 2',
    icon: '🎪',
    description: 'Luyện âm ch và j trong chair, church, job, judge.',
    theory: 'Kết hợp giữa bật âm /t/ và xát âm /ʃ/. Đầu lưỡi chạm vòm miệng giữ hơi rồi giật nhanh xuống đồng thời chu môi. Âm /tʃ/ không rung, âm /dʒ/ rung thanh quản.',
    commonMistakes: 'Nói âm /dʒ/ thành âm "d" hoặc "gi" tiếng Việt (nói "job" thành "dóp").',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Voiceless_postalveolar_affricate.svg/320px-Voiceless_postalveolar_affricate.svg.png',
    diagramCaption: 'Sơ đồ âm /tʃ/ & /dʒ/: Nén hơi sau nướu răng rồi giật bật hơi kết hợp xát nhẹ.',
    sentences: [
      SentenceModel(
        id: '6_1',
        text: 'The teacher checked each student in the gym.',
        ipa: '/ðə ˈtiːtʃər tʃɛkt iːtʃ ˈstjuːdənt ɪn ðə dʒɪm/',
        focusPhonemes: '/tʃ/ & /dʒ/',
      ),
      SentenceModel(
        id: '6_2',
        text: 'George enjoyed his new job in the village.',
        ipa: '/dʒɔːrdʒ ɪnˈdʒɔɪd hɪz njuː dʒɒb ɪn ðə ˈvɪlɪdʒ/',
        focusPhonemes: '/dʒ/',
      ),
      SentenceModel(
        id: '6_3',
        text: 'Choose your challenge and reach your goal.',
        ipa: '/tʃuːz jɔːr ˈtʃælɪndʒ ænd riːtʃ jɔːr goʊl/',
        focusPhonemes: '/tʃ/ & /dʒ/',
      ),
      SentenceModel(
        id: '6_4',
        text: 'Which juice did the cheerful judge drink?',
        ipa: '/wɪtʃ dʒuːs dɪd ðə ˈtʃɪərfʊl dʒʌdʒ drɪŋk/',
        focusPhonemes: '/tʃ/ & /dʒ/',
      ),
    ],
  ),
  LessonModel(
    id: '7',
    title: 'Nguyên Âm Đối Lập /iː/ & /ɪ/',
    category: 'Nguyên Âm',
    level: 'Level 2',
    icon: '✨',
    description:
        'Phân biệt nguyên âm dài và ngắn (sheep vs ship, sleep vs slip).',
    theory: 'Âm /iː/: Cười mỉm, khóe miệng kéo dãn rộng sang hai bên, ngân dài âm. Âm /ɪ/: Miệng mở tự nhiên hơi hờ hững, phát âm ngắn gọn dứt khoát.',
    commonMistakes: 'Đọc cả hai âm đều giống âm "i" tiếng Việt, dẫn đến việc hiểu sai từ nghiêm trọng.',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Close_front_unrounded_vowel.svg/320px-Close_front_unrounded_vowel.svg.png',
    diagramCaption: 'Sơ đồ âm /iː/ vs /ɪ/: Lưỡi đưa cao phía trước, căng cơ miệng (/iː/) vs thả lỏng (/ɪ/).',
    sentences: [
      SentenceModel(
        id: '7_1',
        text: 'Do not slip while the sheep sleep on the ship.',
        ipa: '/duː nɒt slɪp waɪl ðə ʃiːp sliːp ɒn ðə ʃɪp/',
        focusPhonemes: '/iː/ & /ɪ/',
      ),
      SentenceModel(
        id: '7_2',
        text: 'Please leave a little bit of green tea.',
        ipa: '/pliːz liːv ə ˈlɪtəl bɪt ɒv griːn tiː/',
        focusPhonemes: '/iː/ & /ɪ/',
      ),
      SentenceModel(
        id: '7_3',
        text: 'He sits in his seat and eats his meal.',
        ipa: '/hiː sɪts ɪn hɪz siːt ænd iːts hɪz miːl/',
        focusPhonemes: '/iː/ & /ɪ/',
      ),
      SentenceModel(
        id: '7_4',
        text: 'This big city has sixteen clean streets.',
        ipa: '/ðɪs bɪg ˈsɪti hæz ˈsɪksˈtiːn kliːn striːts/',
        focusPhonemes: '/iː/ & /ɪ/',
      ),
    ],
  ),
  LessonModel(
    id: '8',
    title: 'Nguyên Âm Đối Lập /æ/ & /e/',
    category: 'Nguyên Âm',
    level: 'Level 2',
    icon: '🍏',
    description: 'Chinh phục âm a bẹt trong cat, man, bad khác với bed, men.',
    theory: 'Âm /æ/: Hạ cằm sâu, mở miệng rộng tối đa theo chiều dọc, cuống lưỡi hạ thấp. Âm /e/: Mở miệng vừa phải như nói chữ e thông thường.',
    commonMistakes: 'Phát âm /æ/ thành âm "e" (nói "man" nghe như "men", "bad" nghe như "bed").',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Near-open_front_unrounded_vowel.svg/320px-Near-open_front_unrounded_vowel.svg.png',
    diagramCaption: 'Sơ đồ âm /æ/: Hạ cằm sâu tối đa theo chiều dọc, lưỡi đặt thấp dưới đáy khoang miệng.',
    sentences: [
      SentenceModel(
        id: '8_1',
        text: 'The fat cat sat on the black mat.',
        ipa: '/ðə fæt kæt sæt ɒn ðə blæk mæt/',
        focusPhonemes: '/æ/',
      ),
      SentenceModel(
        id: '8_2',
        text: 'Send ten men to set up the red tent.',
        ipa: '/sɛnd tɛn mɛn tuː sɛt ʌp ðə rɛd tɛnt/',
        focusPhonemes: '/e/',
      ),
      SentenceModel(
        id: '8_3',
        text: 'That man has a bad habit of sleeping late.',
        ipa: '/ðæt mæn hæz ə bæd ˈhæbɪt ɒv ˈsliːpɪŋ leɪt/',
        focusPhonemes: '/æ/',
      ),
      SentenceModel(
        id: '8_4',
        text: 'Can you pack the red bag for the trip?',
        ipa: '/kæn juː pæk ðə rɛd bæg fɔːr ðə trɪp/',
        focusPhonemes: '/æ/ & /e/',
      ),
    ],
  ),
  LessonModel(
    id: '9',
    title: 'Cặp Phụ Âm Uốn Lưỡi /r/ & /l/',
    category: 'Âm Khó Đặc Thù',
    level: 'Level 3',
    icon: '🌪️',
    description: 'Sửa tật nhầm lẫn l/r và phát âm chuẩn âm r uốn lưỡi kiểu Mỹ.',
    theory: 'Âm /r/: Uốn nhẹ đầu lưỡi về sau nhưng TUYỆT ĐỐI KHÔNG CHẠM vào vòm miệng. Âm /l/: Đầu lưỡi CHẠM CHẮC vào chân răng trên.',
    commonMistakes:
        'Để lưỡi chạm vòm miệng khi nói /r/, hoặc phát âm /r/ thành /l/.',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Alveolar_approximant.svg/320px-Alveolar_approximant.svg.png',
    diagramCaption: 'Sơ đồ âm /r/ & /l/: /r/ đầu lưỡi uốn cong không chạm vòm; /l/ đầu lưỡi chạm chặt chân răng trên.',
    sentences: [
      SentenceModel(
        id: '9_1',
        text: 'Red lorries roll rapidly along the road.',
        ipa: '/rɛd ˈlɒriz roʊl ˈræpɪdli əˈlɒŋ ðə roʊd/',
        focusPhonemes: '/r/ & /l/',
      ),
      SentenceModel(
        id: '9_2',
        text: 'The leader wrote really clear rules.',
        ipa: '/ðə ˈliːdər roʊt ˈrɪəli klɪər ruːlz/',
        focusPhonemes: '/r/ & /l/',
      ),
      SentenceModel(
        id: '9_3',
        text: 'Real leaders listen and learn every day.',
        ipa: '/rɪəl ˈliːdərz ˈlɪsən ænd lɜːrn ˈɛvri deɪ/',
        focusPhonemes: '/r/ & /l/',
      ),
      SentenceModel(
        id: '9_4',
        text: 'Larry loves reading stories under the bright light.',
        ipa: '/ˈlæri lʌvz ˈriːdɪŋ ˈstɔːriz ˈʌndər ðə braɪt laɪt/',
        focusPhonemes: '/r/ & /l/',
      ),
    ],
  ),
  LessonModel(
    id: '10',
    title: 'Phụ Âm Cuống Họng /k/ & /g/',
    category: 'Âm Đuôi Cốt Lõi',
    level: 'Level 3',
    icon: '🎯',
    description:
        'Khắc phục triệt để lỗi nuốt âm đuôi /k/ (think, like, work, pack).',
    theory: 'Nâng cuống lưỡi lên chạm sát vào ngạc mềm (vòm họng mềm phía sau) để chặn luồng hơi, sau đó giật cuống lưỡi bật hơi mạnh dứt khoát. Âm /k/ bật hơi không rung, /g/ rung thanh quản.',
    commonMistakes: 'Nuốt hẳn âm /k/ ở cuối từ (nói "think" thành "thin", "work" thành "wor"), làm biến đổi nghĩa hoàn toàn.',
    mouthDiagramUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Voiceless_velar_plosive.svg/320px-Voiceless_velar_plosive.svg.png',
    diagramCaption: 'Sơ đồ âm /k/ & /g/: Cuống lưỡi nâng áp sát ngạc mềm phía sau, nén hơi rồi bật dứt khoát.',
    sentences: [
      SentenceModel(
        id: '10_1',
        text: 'She works hard and loves cold drinks.',
        ipa: '/ʃiː wɜːrks hɑːrd ænd lʌvz koʊld drɪŋks/',
        focusPhonemes: '/k/ & /s/',
      ),
      SentenceModel(
        id: '10_2',
        text: 'I think you can make a great cake.',
        ipa: '/aɪ θɪŋk juː kæn meɪk ə greɪt keɪk/',
        focusPhonemes: '/k/',
      ),
      SentenceModel(
        id: '10_3',
        text: 'The big dog chased the black frog in the park.',
        ipa: '/ðə bɪg dɒg tʃeɪst ðə blæk frɒg ɪn ðə pɑːrk/',
        focusPhonemes: '/k/ & /g/',
      ),
      SentenceModel(
        id: '10_4',
        text: 'Please speak clearly when you talk on the phone.',
        ipa: '/pliːz spiːk ˈklɪərli wɛn juː tɔːk ɒn ðə foʊn/',
        focusPhonemes: '/k/',
      ),
    ],
  ),
];

String? curriculumLessonIdForPhoneme(String phoneme) {
  const lessonIdsByPhoneme = {
    'θ': '1',
    'ð': '2',
    't': '3',
    'd': '3',
    's': '4',
    'z': '4',
    'ʃ': '5',
    'ʒ': '5',
    'tʃ': '6',
    'dʒ': '6',
    'iː': '7',
    'ɪ': '7',
    'æ': '8',
    'e': '8',
    'ɛ': '8',
    'r': '9',
    'l': '9',
    'k': '10',
    'g': '10',
  };
  return lessonIdsByPhoneme[phoneme];
}

class CurriculumScreen extends StatefulWidget {
  final Function(String sentence, String ipa)? onSelectSentence;
  final String? initialLessonId;

  const CurriculumScreen({
    super.key,
    this.onSelectSentence,
    this.initialLessonId,
  });

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  LessonModel? _selectedLesson;
  Map<String, double> _sentenceBestScores = {};
  Set<String> _passedSentenceIds = {};

  @override
  void initState() {
    super.initState();
    _selectedLesson = _lessonForId(widget.initialLessonId);
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant CurriculumScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLessonId != oldWidget.initialLessonId) {
      setState(() => _selectedLesson = _lessonForId(widget.initialLessonId));
    }
  }

  LessonModel? _lessonForId(String? lessonId) {
    if (lessonId == null) return null;
    for (final lesson in tenLessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  Future<void> _loadProgress() async {
    // 1. Load from local cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('lesson_progress_cache');
      if (localJson != null) {
        final Map<String, dynamic> map = jsonDecode(localJson);
        setState(() {
          _sentenceBestScores = map.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          );
          _passedSentenceIds = _sentenceBestScores.entries
              .where((e) => e.value >= 80.0)
              .map((e) => e.key)
              .toSet();
        });
      }
    } catch (_) {}

    // 2. Sync from backend SQLite database
    try {
      final items = await ApiService.getLessonProgress();
      if (items.isNotEmpty && mounted) {
        setState(() {
          for (var it in items) {
            _sentenceBestScores[it.sentenceId] = it.bestScore;
            if (it.isPassed || it.bestScore >= 80.0) {
              _passedSentenceIds.add(it.sentenceId);
            }
          }
        });

        // Update local cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'lesson_progress_cache',
            jsonEncode(_sentenceBestScores),
          );
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) debugPrint('Lesson progress refresh failed.');
    }
  }

  void _onSentencePracticeFinished(
    String sentenceId,
    double score,
    bool isPassed,
  ) {
    setState(() {
      final oldBest = _sentenceBestScores[sentenceId] ?? 0.0;
      if (score > oldBest) {
        _sentenceBestScores[sentenceId] = score;
      }
      if (isPassed || score >= 80.0) {
        _passedSentenceIds.add(sentenceId);
      }
    });

    // Save to local cache
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString(
            'lesson_progress_cache',
            jsonEncode(_sentenceBestScores),
          );
        })
        .catchError((_) {});
  }

  bool _isLessonCompleted(LessonModel lesson) {
    return lesson.sentences.every((s) => _passedSentenceIds.contains(s.id));
  }

  void _openPracticeModal(SentenceModel sentence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LessonPracticeModal(
        lesson: _selectedLesson!,
        sentence: sentence,
        currentBestScore: _sentenceBestScores[sentence.id] ?? 0.0,
        isCurrentlyPassed: _passedSentenceIds.contains(sentence.id),
        onPracticeComplete: (score, isPassed) {
          _onSentencePracticeFinished(sentence.id, score, isPassed);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotionColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      if (_selectedLesson != null)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: NotionColors.textMain,
                          ),
                          onPressed: () =>
                              setState(() => _selectedLesson = null),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLesson == null
                                  ? 'Lộ Trình Phát Âm Chuẩn'
                                  : _selectedLesson!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _selectedLesson == null
                                  ? '10 bài học chuẩn IPA • Đạt ≥ 80 điểm để vượt qua mỗi câu'
                                  : '${_selectedLesson!.category} • ${_selectedLesson!.level}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_selectedLesson == null) ...[
                    // 10 Lessons List View
                    ...tenLessons.map((lesson) {
                      final isDone = _isLessonCompleted(lesson);
                      final passedCount = lesson.sentences
                          .where((s) => _passedSentenceIds.contains(s.id))
                          .length;
                      final hasAttempted = lesson.sentences.any(
                        (s) => _sentenceBestScores.containsKey(s.id),
                      );
                      final progress = passedCount / lesson.sentences.length;
                      final status = isDone
                          ? 'Đã hoàn thành'
                          : (hasAttempted ? 'Đang học' : 'Chưa học');
                      final statusColor = isDone
                          ? NotionColors.tagGreenText
                          : (hasAttempted
                                ? NotionColors.tagAmberText
                                : NotionColors.textMuted);
                      final statusBackground = isDone
                          ? NotionColors.tagGreenBg
                          : (hasAttempted
                                ? NotionColors.tagAmberBg
                                : NotionColors.surfaceSubtle);

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLesson = lesson),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NotionColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDone
                                    ? NotionColors.tagGreenText.withAlpha(120)
                                    : NotionColors.border,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lesson.title,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: NotionColors.textMain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBackground,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              status,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lesson.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 5,
                                                backgroundColor:
                                                    NotionColors.surfaceSubtle,
                                                color: isDone
                                                    ? NotionColors.tagGreenText
                                                    : NotionColors.textMain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '$passedCount/${lesson.sentences.length} câu đạt',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: NotionColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: NotionColors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    // Detailed Lesson View
                    // 1. Mouth Placement Diagram & Theory
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NotionColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NotionColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'LÝ THUYẾT & SƠ ĐỒ KHẨU HÌNH CHUẨN',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: NotionColors.textMain,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedLesson!.theory,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: NotionColors.textMain,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Anatomical Cross-section Diagram
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NotionColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: NotionColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    _selectedLesson!.mouthDiagramUrl,
                                    height: 140,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 140,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, _, _) =>
                                        _MouthDiagramFallback(
                                          title: _selectedLesson!.title,
                                          caption:
                                              _selectedLesson!.diagramCaption,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedLesson!.diagramCaption,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: NotionColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Common Mistakes Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NotionColors.tagAmberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠️',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lỗi thường gặp: ${_selectedLesson!.commonMistakes}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: NotionColors.tagAmberText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Fixed Sentences Practice List
                    Builder(
                      builder: (context) {
                        final passedCount = _selectedLesson!.sentences
                            .where((s) => _passedSentenceIds.contains(s.id))
                            .length;
                        final progress =
                            passedCount / _selectedLesson!.sentences.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Câu luyện tập',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: NotionColors.textMain,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$passedCount/${_selectedLesson!.sentences.length} câu đạt',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đạt ≥ 80/100 để hoàn thành từng câu.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: NotionColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor: NotionColors.surfaceSubtle,
                                color: NotionColors.textMain,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    ..._selectedLesson!.sentences.map((sent) {
                      final isPassed = _passedSentenceIds.contains(sent.id);
                      final bestScore = _sentenceBestScores[sent.id] ?? 0.0;
                      final hasAttempted = _sentenceBestScores.containsKey(
                        sent.id,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NotionColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPassed
                                ? NotionColors.tagGreenText.withAlpha(120)
                                : NotionColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sent.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMain,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sent.ipa,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                    color: NotionColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isPassed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NotionColors.tagGreenBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: NotionColors.tagGreenText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Đã đạt · ${bestScore.toStringAsFixed(0)}/100',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: NotionColors.tagGreenText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (hasAttempted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NotionColors.tagAmberBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Cần luyện · cao nhất ${bestScore.toStringAsFixed(0)}/100 (cần ≥ 80)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: NotionColors.tagAmberText,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NotionColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: NotionColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      'Chưa luyện · chưa có điểm',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: NotionColors.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NotionColors.tagGreyBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    sent.focusPhonemes,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: NotionColors.tagGreyText,
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPassed
                                          ? NotionColors.surfaceSubtle
                                          : NotionColors.textMain,
                                      foregroundColor: isPassed
                                          ? NotionColors.textMain
                                          : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: BorderSide(
                                          color: isPassed
                                              ? NotionColors.border
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    icon: Icon(
                                      isPassed
                                          ? Icons.replay_rounded
                                          : Icons.mic_rounded,
                                      size: 14,
                                    ),
                                    label: Text(
                                      isPassed
                                          ? 'Luyện Lại'
                                          : (hasAttempted
                                                ? 'Luyện Tiếp'
                                                : 'Bắt Đầu Luyện'),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => _openPracticeModal(sent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MouthDiagramFallback extends StatelessWidget {
  final String title;
  final String caption;

  const _MouthDiagramFallback({required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: NotionColors.surfaceSubtle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          return Row(
            children: [
              SizedBox(
                width: isCompact ? 96 : 145,
                height: 112,
                child: CustomPaint(painter: _MouthDiagramPainter()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NotionColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      maxLines: isCompact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: NotionColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Minh hoạ thay thế khi ảnh trực tuyến không tải được',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: NotionColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MouthDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 145;
    final scaleY = size.height / 112;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final outline = Paint()
      ..color = NotionColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mouthFill = Paint()..color = Colors.white;
    final tongue = Paint()
      ..color = NotionColors.tagRedText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final airflow = Paint()
      ..color = NotionColors.tagBlueText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cavity = Path()
      ..moveTo(28, 38)
      ..quadraticBezierTo(75, 17, 119, 32)
      ..quadraticBezierTo(133, 44, 119, 60)
      ..quadraticBezierTo(81, 80, 34, 70)
      ..close();
    canvas.drawPath(cavity, mouthFill);
    canvas.drawPath(cavity, outline);
    canvas.drawLine(const Offset(78, 31), const Offset(119, 36), outline);
    canvas.drawLine(const Offset(76, 63), const Offset(119, 58), outline);
    canvas.drawLine(const Offset(45, 67), const Offset(101, 55), tongue);

    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(91 + i * 7.0, 33, 6, 9),
          const Radius.circular(1),
        ),
        Paint()..color = NotionColors.border,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(91 + i * 7.0, 55, 6, 8),
          const Radius.circular(1),
        ),
        Paint()..color = NotionColors.border,
      );
    }

    canvas.drawLine(const Offset(12, 49), const Offset(77, 49), airflow);
    canvas.drawLine(const Offset(77, 49), const Offset(68, 44), airflow);
    canvas.drawLine(const Offset(77, 49), const Offset(68, 54), airflow);

    final labelStyle = TextStyle(
      color: NotionColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    _drawLabel(canvas, 'hơi', const Offset(12, 35), labelStyle);
    _drawLabel(canvas, 'lưỡi', const Offset(49, 77), labelStyle);
    _drawLabel(canvas, 'răng', const Offset(105, 68), labelStyle);
    canvas.restore();
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MouthDiagramPainter oldDelegate) => false;
}

// Dedicated Lesson Sentence Practice Modal
class _LessonPracticeModal extends StatefulWidget {
  final LessonModel lesson;
  final SentenceModel sentence;
  final double currentBestScore;
  final bool isCurrentlyPassed;
  final Function(double score, bool isPassed) onPracticeComplete;

  const _LessonPracticeModal({
    required this.lesson,
    required this.sentence,
    required this.currentBestScore,
    required this.isCurrentlyPassed,
    required this.onPracticeComplete,
  });

  @override
  State<_LessonPracticeModal> createState() => _LessonPracticeModalState();
}

class _LessonPracticeModalState extends State<_LessonPracticeModal> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isPlayingTts = false;

  AssessmentResultModel? _result;
  String? _statusMessage;
  late double _bestScore;
  late bool _isPassed;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _bestScore = widget.currentBestScore;
    _isPassed = widget.isCurrentlyPassed;

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingTts = false);
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playTts() async {
    try {
      setState(() => _isPlayingTts = true);
      final url = ApiService.getTtsUrl(widget.sentence.text);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
        _statusMessage = "Đang phân tích âm học và bắt lỗi nuốt âm...";
      });

      Uint8List? audioBytes;
      try {
        final path = await _audioRecorder.stop();
        if (path != null && path.isNotEmpty) {
          if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
            final res = await http.get(Uri.parse(path));
            audioBytes = res.bodyBytes;
          } else {
            final file = await http
                .get(Uri.parse(path))
                .timeout(const Duration(seconds: 2))
                .catchError((_) => http.Response('', 404));
            if (file.statusCode == 200) audioBytes = file.bodyBytes;
          }
        }
      } catch (e) {
        debugPrint('Error retrieving audio: $e');
      }

      if (audioBytes == null || audioBytes.length < 400) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage =
              "Không nhận được âm thanh. Vui lòng nói to và rõ hơn.";
        });
        return;
      }

      try {
        final assessment = await ApiService.assessPronunciation(
          referenceText: widget.sentence.text,
          audioBytes: audioBytes,
        );

        final score = assessment.overallScore;
        final newlyPassed = (score >= 80.0) || _isPassed;
        final newBest = (score > _bestScore) ? score : _bestScore;

        // Persist to backend SQLite
        await ApiService.recordLessonProgress(
          lessonId: widget.lesson.id,
          sentenceId: widget.sentence.id,
          sentenceText: widget.sentence.text,
          score: score,
        );

        // Sync streak
        if (assessment.streakInfo != null) {
          DisciplineState.syncFromBackend(
            curStreak: assessment.streakInfo!['current_streak'] ?? 0,
            longest: assessment.streakInfo!['longest_streak'] ?? 0,
            freezes: assessment.streakInfo!['freeze_days_available'] ?? 0,
          );
        }
        await DisciplineState.refreshDailyActivity();

        if (mounted) {
          setState(() {
            _result = assessment;
            _bestScore = newBest;
            _isPassed = newlyPassed;
            _isAnalyzing = false;
            _statusMessage = null;
          });

          widget.onPracticeComplete(newBest, newlyPassed);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _statusMessage = "Lỗi khi phân tích phát âm: $e";
          });
        }
      }
    } else {
      // Start Recording
      try {
        final hasPerm = await _audioRecorder.hasPermission();
        if (!hasPerm) {
          setState(
            () => _statusMessage = "Vui lòng cấp quyền micro để luyện nói.",
          );
          return;
        }

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        );
        await _audioRecorder.start(config, path: '');
        setState(() {
          _isRecording = true;
          _statusMessage =
              "Đang thu âm... Hãy đọc to và dứt khoát các âm cuối.";
          _result = null;
        });
      } catch (e) {
        setState(() => _statusMessage = "Không thể bật micro: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NotionColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luyện Câu Bài Học #${widget.sentence.id}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NotionColors.textMain,
                      ),
                    ),
                    Text(
                      'Ngưỡng hoàn thành: ≥ 80 điểm',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: NotionColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: NotionColors.textMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fixed Sentence Box (NOT EDITABLE)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NotionColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NotionColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NotionColors.tagBlueBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CÂU CỐ ĐỊNH CỦA BÀI HỌC',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: NotionColors.tagBlueText,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _isPlayingTts ? null : _playTts,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: NotionColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: NotionColors.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isPlayingTts
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: NotionColors.textMain,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.volume_up_rounded,
                                        size: 13,
                                        color: NotionColors.textMain,
                                      ),
                                const SizedBox(width: 4),
                                Text(
                                  _isPlayingTts
                                      ? 'Đang đọc...'
                                      : 'Nghe đọc mẫu',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: NotionColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sentence.text,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: NotionColors.textMain,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sentence.ipa,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: NotionColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mic Center
            Center(
              child: Column(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isAnalyzing ? null : _toggleRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? NotionColors.tagRedBg
                              : (_isAnalyzing
                                    ? NotionColors.tagAmberBg
                                    : NotionColors.textMain),
                          border: Border.all(
                            color: _isRecording
                                ? NotionColors.tagRedText
                                : NotionColors.border,
                            width: _isRecording ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NotionColors.tagAmberText,
                                  ),
                                )
                              : Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  size: 26,
                                  color: _isRecording
                                      ? NotionColors.tagRedText
                                      : Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRecording
                        ? 'Đang thu âm... Chạm để dừng & chấm'
                        : (_isAnalyzing
                              ? 'Đang chấm điểm phát âm...'
                              : 'Chạm micro để đọc câu này'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _isRecording
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _isRecording
                          ? NotionColors.tagRedText
                          : NotionColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null && !_isAnalyzing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NotionColors.tagAmberBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: NotionColors.tagAmberText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Assessment Outcome & Pass Threshold Verification
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.overallScore >= 80.0
                      ? NotionColors.tagGreenBg
                      : NotionColors.tagAmberBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.overallScore >= 80.0
                        ? NotionColors.tagGreenText.withAlpha(120)
                        : NotionColors.tagAmberText.withAlpha(120),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _result!.overallScore >= 80.0
                              ? '🎉 ĐẠT CHUẨN (PASSED)'
                              : '⚠️ CHƯA ĐẠT (CẦN ≥ 80)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _result!.overallScore >= 80.0
                                ? NotionColors.tagGreenText
                                : NotionColors.tagAmberText,
                          ),
                        ),
                        Text(
                          'Điểm lần này: ${_result!.overallScore.toStringAsFixed(0)}/100',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _result!.overallScore >= 80.0
                                ? NotionColors.tagGreenText
                                : NotionColors.tagAmberText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.overallScore >= 80.0
                          ? 'Chúc mừng bạn đã phát âm chuẩn xác câu này! Tiến trình bài học đã được ghi nhận.'
                          : 'Điểm cao nhất của bạn: ${_bestScore.toStringAsFixed(0)}/100. Hãy luyện lại để vượt qua mốc 80!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _result!.overallScore >= 80.0
                            ? NotionColors.tagGreenText
                            : NotionColors.tagAmberText,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Words breakdown
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _result!.words.map((w) {
                        final isGood = w.accuracyScore >= 75.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isGood
                                ? Colors.white
                                : NotionColors.tagRedBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isGood
                                  ? NotionColors.tagGreenText.withAlpha(80)
                                  : NotionColors.tagRedText,
                            ),
                          ),
                          child: Text(
                            w.word,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isGood
                                  ? NotionColors.tagGreenText
                                  : NotionColors.tagRedText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
