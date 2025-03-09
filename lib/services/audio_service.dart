// lib/services/audio_service.dart

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 오디오 재생 관련 기능을 처리하는 서비스 클래스
class AudioPlayerService {
  // AudioPlayer 인스턴스
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 현재 재생 중인 트랙 ID
  String? _currentTrackId;
  
  // 현재 재생 중인 오디오 URL
  String? _currentAudioUrl;
  
  // 플레이어 상태 제공
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  
  // 현재 재생 상태 확인
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  String? get currentTrackId => _currentTrackId;
  String? get currentAudioUrl => _currentAudioUrl;
  
  // 초기화 메서드
  Future<void> initialize() async {
    try {
      // 오류 처리 설정
      _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          if (kDebugMode) {
            print('오디오 플레이어 오류: $e');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('오디오 플레이어 초기화 오류: $e');
      }
      rethrow;
    }
  }
  
  // 오디오 URL로 재생
  Future<void> play(String audioUrl, {String? trackId}) async {
    try {
      // 이미 같은 오디오를 재생 중이면 위치만 처음으로 이동
      if (_currentAudioUrl == audioUrl && _audioPlayer.playing) {
        await _audioPlayer.seek(Duration.zero);
        return;
      }
      
      // 새 오디오 설정
      await _audioPlayer.setUrl(audioUrl);
      
      // 상태 업데이트
      _currentAudioUrl = audioUrl;
      _currentTrackId = trackId;
      
      // 재생 시작
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('오디오 재생 오류: $e');
      }
      rethrow;
    }
  }
  
  // 로컬 asset에서 재생 (예: assets/audio/sample.mp3)
  Future<void> playAsset(String assetPath, {String? trackId}) async {
    try {
      // assets 디렉토리에서 파일 로드
      final file = File(assetPath);
      
      if (kIsWeb) {
        // 웹에서는 URL 사용
        await _audioPlayer.setAsset(assetPath);
      } else {
        // 모바일/데스크톱에서는 파일 경로 사용
        if (assetPath.startsWith('assets/')) {
          // Asset에서 임시 파일로 복사
          final bytes = await rootBundle.load(assetPath);
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_audio.mp3');
          await tempFile.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          await _audioPlayer.setFilePath(tempFile.path);
        } else {
          // 로컬 파일인 경우
          await _audioPlayer.setFilePath(assetPath);
        }
      }
      
      // 상태 업데이트
      _currentAudioUrl = assetPath;
      _currentTrackId = trackId;
      
      // 재생 시작
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('Asset 오디오 재생 오류: $e');
      }
      rethrow;
    }
  }
  
  // 재생 일시정지
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        print('오디오 일시정지 오류: $e');
      }
      rethrow;
    }
  }
  
  // 재생 재개
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('오디오 재개 오류: $e');
      }
      rethrow;
    }
  }
  
  // 정지
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print('오디오 정지 오류: $e');
      }
      rethrow;
    }
  }
  
  // 재생 위치 이동
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      if (kDebugMode) {
        print('오디오 탐색 오류: $e');
      }
      rethrow;
    }
  }
  
  // 재생 속도 변경
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (e) {
      if (kDebugMode) {
        print('재생 속도 변경 오류: $e');
      }
      rethrow;
    }
  }
  
  // 반복 모드 설정
  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await _audioPlayer.setLoopMode(mode);
    } catch (e) {
      if (kDebugMode) {
        print('반복 모드 변경 오류: $e');
      }
      rethrow;
    }
  }
  
  // 볼륨 설정
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      if (kDebugMode) {
        print('볼륨 변경 오류: $e');
      }
      rethrow;
    }
  }
  
  // 자원 해제
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('오디오 플레이어 자원 해제 오류: $e');
      }
    }
  }
}
