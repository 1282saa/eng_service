// lib/services/stt_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// STT(Speech-to-Text) 관련 기능을 처리하는 서비스 클래스
class STTService {
  // Google Cloud Speech-to-Text API를 사용하여 오디오를 텍스트로 변환
  Future<String?> transcribeAudio({
    required List<int> audioBytes,
    required String apiKey,
    String languageCode = 'en-US',
  }) async {
    try {
      // 오디오 데이터를 base64로 인코딩
      final base64Audio = base64Encode(audioBytes);
      
      // API 엔드포인트
      final url = Uri.parse(
        'https://speech.googleapis.com/v1/speech:recognize?key=$apiKey',
      );
      
      // API 요청 본문
      final requestBody = {
        'config': {
          'languageCode': languageCode,
          'enableAutomaticPunctuation': true,
          'model': 'default',
          'encoding': 'MP3', // 오디오 인코딩 형식에 맞게 조정 필요
          'sampleRateHertz': 16000, // 오디오 샘플 레이트에 맞게 조정 필요
        },
        'audio': {
          'content': base64Audio,
        },
      };
      
      // API 요청 전송
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      // 응답 처리
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 결과 추출
        if (data.containsKey('results') && data['results'].isNotEmpty) {
          final results = data['results'] as List;
          
          // 모든 결과 텍스트 합치기
          final transcriptions = results
              .map((result) => result['alternatives'][0]['transcript'] as String)
              .join(' ');
          
          return transcriptions;
        } else {
          // 결과가 없는 경우
          return '';
        }
      } else {
        // API 오류 처리
        if (kDebugMode) {
          print('Cloud Speech-to-Text API 오류: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('STT 처리 오류: $e');
      }
      return null;
    }
  }
  
  // 파일에서 바이트 읽기 (웹과 모바일/데스크톱 모두 대응)
  Future<List<int>?> readAudioFile(dynamic file) async {
    try {
      if (kIsWeb) {
        // 웹에서는 파일 객체에서 직접 바이트 읽기
        if (file is Uint8List) {
          return file.toList();
        } else {
          if (kDebugMode) {
            print('웹: 지원되지 않는 파일 형식');
          }
          return null;
        }
      } else {
        // 모바일/데스크톱에서는 File 객체에서 읽기
        if (file is File) {
          return await file.readAsBytes();
        } else if (file is String) {
          // 파일 경로가 문자열로 제공된 경우
          final audioFile = File(file);
          return await audioFile.readAsBytes();
        } else {
          if (kDebugMode) {
            print('모바일/데스크톱: 지원되지 않는 파일 형식');
          }
          return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('오디오 파일 읽기 오류: $e');
      }
      return null;
    }
  }
  
  // 음성 파일을 텍스트로 변환 (통합 메서드)
  Future<String?> convertAudioToText({
    required dynamic audioFile,
    required String apiKey,
    String languageCode = 'en-US',
  }) async {
    try {
      // 파일에서 바이트 읽기
      final audioBytes = await readAudioFile(audioFile);
      if (audioBytes == null) {
        return null;
      }
      
      // 바이트를 텍스트로 변환
      return await transcribeAudio(
        audioBytes: audioBytes,
        apiKey: apiKey,
        languageCode: languageCode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('오디오-텍스트 변환 오류: $e');
      }
      return null;
    }
  }
}