// lib/utils/error_utils.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 오류 메시지를 사용자 친화적으로 변환하는 유틸리티 클래스
class ErrorUtils {
  /// Firebase Auth 오류 메시지를 사용자 친화적인 메시지로 변환
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return '이미 사용 중인 이메일 주소입니다.';
        case 'invalid-email':
          return '올바르지 않은 이메일 형식입니다.';
        case 'weak-password':
          return '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 사용해주세요.';
        case 'user-not-found':
          return '해당 이메일을 가진 사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          return '비밀번호가 올바르지 않습니다.';
        case 'user-disabled':
          return '이 계정은 비활성화 되었습니다. 관리자에게 문의하세요.';
        case 'operation-not-allowed':
          return '이 작업은 허용되지 않습니다.';
        case 'too-many-requests':
          return '너무 많은 요청이 있었습니다. 잠시 후 다시 시도해주세요.';
        default:
          return error.message ?? '인증 오류가 발생했습니다.';
      }
    } else if (error is Exception) {
      return '오류: ${error.toString()}';
    }
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// Firebase Firestore/Storage 오류 메시지를 사용자 친화적인 메시지로 변환
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return '접근 권한이 없습니다.';
        case 'not-found':
          return '요청한 문서를 찾을 수 없습니다.';
        case 'already-exists':
          return '이미 존재하는 문서입니다.';
        case 'failed-precondition':
          return '작업을 완료할 수 없습니다. 전제 조건 실패.';
        case 'aborted':
          return '작업이 중단되었습니다.';
        case 'out-of-range':
          return '범위를 벗어났습니다.';
        case 'unavailable':
          return '서비스를 일시적으로 사용할 수 없습니다. 나중에 다시 시도해주세요.';
        case 'data-loss':
          return '데이터가 손실되었습니다.';
        case 'unauthenticated':
          return '인증되지 않았습니다. 다시 로그인해주세요.';
        default:
          return error.message ?? '데이터베이스 오류가 발생했습니다.';
      }
    } else if (error is Exception) {
      return '오류: ${error.toString()}';
    }
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// 네트워크 오류 메시지를 사용자 친화적인 메시지로 변환
  static String getNetworkErrorMessage(dynamic error) {
    if (error is Exception) {
      if (error.toString().contains('SocketException') ||
          error.toString().contains('Connection refused')) {
        return '네트워크 연결에 문제가 있습니다. 인터넷 연결을 확인해주세요.';
      }
      if (error.toString().contains('TimeoutException')) {
        return '서버 응답 시간이 초과되었습니다. 나중에 다시 시도해주세요.';
      }
      return '오류: ${error.toString()}';
    }
    return '알 수 없는 네트워크 오류가 발생했습니다.';
  }

  /// TTS, OCR, STT 오류 메시지를 사용자 친화적인 메시지로 변환
  static String getAPIErrorMessage(dynamic error) {
    if (error is Exception) {
      if (error.toString().contains('API key')) {
        return 'API 키 오류가 발생했습니다. 관리자에게 문의하세요.';
      }
      if (error.toString().contains('rate limit')) {
        return 'API 사용량 제한에 도달했습니다. 잠시 후 다시 시도해주세요.';
      }
      return '오류: ${error.toString()}';
    }
    return '알 수 없는 API 오류가 발생했습니다.';
  }

  /// 오류를 로그에 기록하고 사용자에게 보여줄 메시지 반환
  static String logAndGetMessage(dynamic error, {String? customMessage}) {
    // 디버그 모드에서만 로그 출력
    if (kDebugMode) {
      print('오류 발생: $error');
      if (error is StackTrace) {
        print('스택 트레이스: $error');
      }
    }
    
    if (customMessage != null) {
      return customMessage;
    }
    
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else {
      // 기타 오류는 일반 메시지로 처리
      return '오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  /// 오류 스낵바 표시
  static void showErrorSnackBar(BuildContext context, dynamic error, {String? customMessage}) {
    final message = customMessage ?? logAndGetMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 성공 스낵바 표시
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 정보 스낵바 표시
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}