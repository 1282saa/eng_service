// lib/services/tts_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // 앱 내 TTS 초기화
  Future<void> initialize() async {
    if (!_isInitialized) {
      // 영어 음성으로 설정
      await _flutterTts.setLanguage('en-US');

      // 음성 속도 설정 (1.0이 기본값)
      await _flutterTts.setSpeechRate(0.9);

      // 음량 설정 (0.0 ~ 1.0)
      await _flutterTts.setVolume(1.0);

      // 음성 피치 설정 (1.0이 기본값)
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
    }
  }

  // 텍스트를 즉시 TTS로 읽기
  Future<void> speak(String text) async {
    await initialize();
    await _flutterTts.speak(text);
  }

  // TTS 멈추기
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  // 재생 속도 변경
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  // Google Cloud TTS를 사용하여 오디오 파일 생성 (서버가 필요하거나 클라우드 함수를 통해 호출)
  Future<String?> generateAudioFile(String text, String apiKey) async {
    // 실제 구현에서는 Firebase Storage에 저장하거나 클라우드 함수를 호출하는 방식으로 변경 필요
    try {
      final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': text},
          'voice': {'languageCode': 'en-US', 'name': 'en-US-Standard-D'},
          'audioConfig': {'audioEncoding': 'MP3'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // base64 인코딩된 오디오 데이터
        final audioContent = data['audioContent'];

        // Firebase Storage에 업로드하는 로직이 필요함
        // TODO: 오디오 데이터를 Firebase Storage에 업로드

        return "generated_audio_url.mp3"; // 실제 구현에서는 업로드된 URL 반환
      } else {
        if (kDebugMode) {
          print('Cloud TTS 오류: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS 생성 오류: $e');
      }
      return null;
    }
  }

  // 텍스트를 문장 단위로 분할
  List<String> splitIntoSentences(String text) {
    // 간단한 문장 분할 로직 (마침표, 물음표, 느낌표 기준)
    RegExp exp = RegExp(r'[.!?]+\s+');
    List<String> sentences = text.split(exp);

    // 마지막에 문장 부호가 있는 경우 처리
    if (sentences.isNotEmpty && sentences.last.trim().isEmpty) {
      sentences.removeLast();
    }

    // 빈 문장 제거
    return sentences.where((s) => s.trim().isNotEmpty).toList();
  }

  // 자원 해제
  void dispose() {
    _flutterTts.stop();
  }
}
