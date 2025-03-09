// lib/services/tts_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// TTS(Text-to-Speech) 관련 기능을 처리하는 서비스 클래스
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  
  // TTS 초기화 완료 여부 확인
  bool get isInitialized => _isInitialized;
  
  // TTS 초기화 - 앱 시작 시 한 번만 호출
  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        // 영어 음성으로 설정
        await _flutterTts.setLanguage('en-US');
        
        // 음성 속도 설정 (1.0이 기본값)
        await _flutterTts.setSpeechRate(0.9);
        
        // 음량 설정 (0.0 ~ 1.0)
        await _flutterTts.setVolume(1.0);
        
        // 음성 피치 설정 (1.0이 기본값)
        await _flutterTts.setPitch(1.0);
        
        // 성공적으로 초기화됨
        _isInitialized = true;
        if (kDebugMode) {
          print('TTS 초기화 완료');
        }
      } catch (e) {
        if (kDebugMode) {
          print('TTS 초기화 오류: $e');
        }
        rethrow; // 호출자에게 에러 전파
      }
    }
  }

  // 텍스트를 즉시 TTS로 읽기
  Future<void> speak(String text) async {
    if (text.isEmpty) {
      if (kDebugMode) {
        print('TTS 오류: 빈 텍스트가 전달됨');
      }
      return;
    }
    
    try {
      await initialize();
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('TTS 재생 오류: $e');
      }
      rethrow;
    }
  }

  // TTS 멈추기
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) {
        print('TTS 정지 오류: $e');
      }
      rethrow;
    }
  }

  // 재생 속도 변경
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      if (kDebugMode) {
        print('TTS 속도 변경 오류: $e');
      }
      rethrow;
    }
  }

  // Google Cloud TTS를 사용하여 오디오 파일 생성 및 Firebase Storage에 업로드
  Future<String?> generateAudioFile(String text, String apiKey, String userId) async {
    if (text.isEmpty) {
      if (kDebugMode) {
        print('오디오 파일 생성 오류: 빈 텍스트가 전달됨');
      }
      return null;
    }
    
    try {
      // Google Cloud TTS API 호출
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
        final audioContent = data['audioContent'] as String;
        
        // Base64 디코딩하여 바이너리 데이터로 변환
        final audioBytes = base64Decode(audioContent);
        
        // Firebase Storage에 업로드하기 위한 파일 생성
        final uuid = const Uuid().v4(); // 고유 파일명 생성
        final fileName = 'tts_${uuid}.mp3';
        
        // 웹인 경우와 모바일/데스크톱인 경우 처리 분리
        if (kIsWeb) {
          // 웹에서는 바로 Firebase Storage에 업로드
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('audio')
              .child(userId)
              .child(fileName);
          
          // 업로드
          await storageRef.putData(
            audioBytes,
            SettableMetadata(contentType: 'audio/mpeg'),
          );
          
          // 다운로드 URL 가져오기
          final downloadUrl = await storageRef.getDownloadURL();
          return downloadUrl;
        } else {
          // 모바일/데스크톱에서는 임시 파일로 저장 후 업로드
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(audioBytes);
          
          // Firebase Storage에 업로드
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('audio')
              .child(userId)
              .child(fileName);
          
          // 업로드
          await storageRef.putFile(tempFile);
          
          // 임시 파일 삭제
          await tempFile.delete();
          
          // 다운로드 URL 가져오기
          final downloadUrl = await storageRef.getDownloadURL();
          return downloadUrl;
        }
      } else {
        if (kDebugMode) {
          print('Cloud TTS 오류: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('오디오 파일 생성 오류: $e');
      }
      return null;
    }
  }

  // 텍스트를 문장 단위로 분할 (정규식 개선)
  List<String> splitIntoSentences(String text) {
    if (text.isEmpty) return [];
    
    // 약어 등을 고려한 개선된 정규식
    // Mr., Dr., e.g., i.e. 등의 약어를 예외 처리
    final abbreviations = r'Mr\.|Dr\.|Mrs\.|Ms\.|e\.g\.|i\.e\.|etc\.';
    
    // 문장 끝 패턴 (약어를 제외한 .!? 뒤에 공백이나 줄바꿈이 오는 경우)
    final pattern = RegExp(
      r'(?<!' + abbreviations + r')([.!?])[""")]?(\s|$)',
      caseSensitive: false,
    );
    
    // 텍스트 분할
    List<String> sentences = [];
    int startIndex = 0;
    
    // 패턴 매칭으로 문장 분할
    for (final match in pattern.allMatches(text)) {
      final endIndex = match.end;
      if (endIndex > startIndex) {
        final sentence = text.substring(startIndex, endIndex).trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
        }
        startIndex = endIndex;
      }
    }
    
    // 마지막 부분이 남아 있으면 추가
    if (startIndex < text.length) {
      final lastSentence = text.substring(startIndex).trim();
      if (lastSentence.isNotEmpty) {
        sentences.add(lastSentence);
      }
    }
    
    return sentences;
  }

  // 자원 해제
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) {
        print('TTS 자원 해제 오류: $e');
      }
    }
  }
}