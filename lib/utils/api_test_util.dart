// lib/utils/api_test_util.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Google Cloud Vision API 키가 유효한지 테스트
Future<Map<String, dynamic>> testVisionApiKey(String apiKey) async {
  try {
    // 매우 작은 빈 이미지 데이터(1x1 픽셀)
    final smallImageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    
    // API 엔드포인트
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );

    // 최소한의 요청 본문
    final requestBody = {
      "requests": [
        {
          "image": {"content": base64Encode(smallImageBytes)},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    };

    // API 요청 실행
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    // 응답 처리
    if (kDebugMode) {
      print('Vision API 응답 코드: ${response.statusCode}');
      print('Vision API 응답 본문: ${response.body}');
    }

    return {
      'success': response.statusCode == 200,
      'statusCode': response.statusCode,
      'message': response.statusCode == 200 
          ? 'Vision API 키가 유효합니다.' 
          : 'Vision API 키가 유효하지 않습니다: ${response.body}',
      'response': response.body,
    };
  } catch (e) {
    if (kDebugMode) {
      print('Vision API 테스트 중 오류 발생: $e');
    }
    return {
      'success': false,
      'statusCode': 500,
      'message': '오류 발생: $e',
      'response': null,
    };
  }
}

/// Google Cloud Speech-to-Text API 키가 유효한지 테스트
Future<Map<String, dynamic>> testSpeechApiKey(String apiKey) async {
  try {
    // API 엔드포인트
    final url = Uri.parse(
      'https://speech.googleapis.com/v1/speech:recognize?key=$apiKey',
    );

    // 최소한의 요청 본문 (실제 오디오 없이 구조만 검증)
    final requestBody = {
      'config': {
        'languageCode': 'en-US',
        'sampleRateHertz': 16000,
        'encoding': 'LINEAR16',
      },
      'audio': {
        'content': '', // 빈 컨텐츠로도 API 키 유효성은 확인 가능
      },
    };

    // API 요청 실행
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    // 응답 처리 (400이라도 API 키가 유효하면 다른 오류 메시지 반환)
    if (kDebugMode) {
      print('Speech API 응답 코드: ${response.statusCode}');
      print('Speech API 응답 본문: ${response.body}');
    }

    final responseBody = jsonDecode(response.body);
    final isApiKeyValid = !(responseBody['error'] != null && 
                           responseBody['error']['message'].toString().contains('API key not valid'));

    return {
      'success': isApiKeyValid,
      'statusCode': response.statusCode,
      'message': isApiKeyValid 
          ? 'Speech-to-Text API 키가 유효합니다. (오디오 데이터 관련 오류는 예상됨)' 
          : 'Speech-to-Text API 키가 유효하지 않습니다: ${response.body}',
      'response': response.body,
    };
  } catch (e) {
    if (kDebugMode) {
      print('Speech API 테스트 중 오류 발생: $e');
    }
    return {
      'success': false,
      'statusCode': 500,
      'message': '오류 발생: $e',
      'response': null,
    };
  }
}