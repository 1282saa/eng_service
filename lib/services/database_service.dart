// lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

/// Firestore 관련 데이터 처리를 모아둔 서비스 클래스
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 컬렉션 이름 상수화 - 오타 방지
  static const String usersCollection = 'users';
  static const String playlistsCollection = 'playlists';
  static const String tracksCollection = 'tracks';
  static const String diagnosticsCollection = 'diagnostics';
  static const String progressCollection = 'progress';
  static const String contentsCollection = 'contents';

  // ─────────────────────────────────────────────────────────
  // (1) 사용자 프로필 저장/업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> saveUserProfile(
      String userId, Map<String, dynamic> userData) async {
    try {
      await _db
          .collection(usersCollection)
          .doc(userId)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      _logError('saveUserProfile', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (2) 사용자 프로필 가져오기
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection(usersCollection).doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      _logError('getUserProfile', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (3) 진단 테스트 결과 저장
  // ─────────────────────────────────────────────────────────
  Future<void> saveDiagnosticResults(
      String userId, Map<String, dynamic> results) async {
    try {
      await _db.collection(usersCollection).doc(userId).collection(diagnosticsCollection).add({
        'timestamp': FieldValue.serverTimestamp(),
        ...results,
      });
    } catch (e) {
      _logError('saveDiagnosticResults', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (4) 학습 콘텐츠 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLearningContents(
      String category, String level) async {
    try {
      final snapshot = await _db
          .collection(contentsCollection)
          .where('category', isEqualTo: category)
          .where('level', isEqualTo: level)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logError('getLearningContents', e);
      return []; // 오류 시 빈 리스트 반환
    }
  }

  // ─────────────────────────────────────────────────────────
  // (5) 학습 진행 상황 저장
  // ─────────────────────────────────────────────────────────
  Future<void> saveProgress(
      String userId, String contentId, int progress) async {
    try {
      await _db
          .collection(usersCollection)
          .doc(userId)
          .collection(progressCollection)
          .doc(contentId)
          .set({
        'progress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _logError('saveProgress', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (6) 사용자의 학습 진행 상황 가져오기
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      final snapshot =
          await _db.collection(usersCollection).doc(userId).collection(progressCollection).get();

      final Map<String, dynamic> progress = {};
      for (var doc in snapshot.docs) {
        progress[doc.id] = doc.data();
      }

      return progress;
    } catch (e) {
      _logError('getUserProgress', e);
      return {}; // 오류 시 빈 맵 반환
    }
  }

  // ─────────────────────────────────────────────────────────
  // (7) 플레이리스트 생성
  // ─────────────────────────────────────────────────────────
  Future<String> createPlaylist(Playlist playlist) async {
    try {
      final docRef =
          await _db.collection(playlistsCollection).add(playlist.toFirestore());
      return docRef.id;
    } catch (e) {
      _logError('createPlaylist', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (8) 플레이리스트 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updatePlaylist(Playlist playlist) async {
    try {
      await _db
          .collection(playlistsCollection)
          .doc(playlist.id)
          .update(playlist.toFirestore());
    } catch (e) {
      _logError('updatePlaylist', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (9) 플레이리스트 삭제
  // ─────────────────────────────────────────────────────────
  Future<void> deletePlaylist(String playlistId) async {
    try {
      // 먼저 플레이리스트에 속한 모든 트랙 조회
      final tracksQuery = await _db
          .collection(tracksCollection)
          .where('playlistId', isEqualTo: playlistId)
          .get();
          
      // 배치로 트랙들과 플레이리스트 삭제
      final batch = _db.batch();
      
      // 트랙들 삭제
      for (var doc in tracksQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // 플레이리스트 삭제
      batch.delete(_db.collection(playlistsCollection).doc(playlistId));
      
      // 배치 커밋
      await batch.commit();
    } catch (e) {
      _logError('deletePlaylist', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (10) 사용자의 플레이리스트 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Playlist>> getUserPlaylists(String userId) {
    try {
      return _db
          .collection(playlistsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
    } catch (e) {
      _logError('getUserPlaylists', e);
      // 스트림 오류 처리
      return Stream.value([]);
    }
  }

  // ─────────────────────────────────────────────────────────
  // (11) 트랙 추가
  // ─────────────────────────────────────────────────────────
  Future<String> addTrack(Track track) async {
    try {
      // 트랙 추가 및 플레이리스트 업데이트
      final batch = _db.batch();
      
      // 새 트랙 문서 참조 생성
      final trackRef = _db.collection(tracksCollection).doc();
      
      // 플레이리스트 참조
      final playlistRef = _db.collection(playlistsCollection).doc(track.playlistId);
      
      // 트랙 추가
      batch.set(trackRef, track.toFirestore());
      
      // 플레이리스트 트랙 수 증가 및 업데이트 시간 설정
      batch.update(playlistRef, {
        'trackCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 배치 커밋
      await batch.commit();
      
      return trackRef.id;
    } catch (e) {
      _logError('addTrack', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (12) 트랙 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updateTrack(Track track) async {
    try {
      await _db.collection(tracksCollection).doc(track.id).update(track.toFirestore());
      
      // 플레이리스트 업데이트 시간도 함께 갱신
      await _db.collection(playlistsCollection).doc(track.playlistId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logError('updateTrack', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (13) 트랙 삭제
  // ─────────────────────────────────────────────────────────
  Future<void> deleteTrack(Track track) async {
    try {
      // 배치로 처리
      final batch = _db.batch();
      
      // 트랙 삭제
      batch.delete(_db.collection(tracksCollection).doc(track.id));
      
      // 플레이리스트의 트랙 수 감소 및 업데이트 시간 설정
      batch.update(_db.collection(playlistsCollection).doc(track.playlistId), {
        'trackCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 배치 커밋
      await batch.commit();
    } catch (e) {
      _logError('deleteTrack', e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────
  // (14) 플레이리스트의 트랙 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Track>> getPlaylistTracks(String playlistId) {
    try {
      return _db
          .collection(tracksCollection)
          .where('playlistId', isEqualTo: playlistId)
          .orderBy('order')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Track.fromFirestore(doc)).toList());
    } catch (e) {
      _logError('getPlaylistTracks', e);
      // 스트림 오류 처리
      return Stream.value([]);
    }
  }

  // ─────────────────────────────────────────────────────────
  // (15) 즐겨찾기 트랙 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Track>> getFavoriteTracks(String userId) {
    try {
      return _db
          .collection(tracksCollection)
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Track.fromFirestore(doc)).toList());
    } catch (e) {
      _logError('getFavoriteTracks', e);
      // 스트림 오류 처리
      return Stream.value([]);
    }
  }

  // ─────────────────────────────────────────────────────────
  // (16) 트랙 순서 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updateTrackOrder(List<Track> tracks) async {
    try {
      // 배치 처리
      final batch = _db.batch();
      String? playlistId;

      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        batch.update(_db.collection(tracksCollection).doc(track.id), {'order': i});
        
        // 플레이리스트 ID 저장 (모든 트랙은 같은 플레이리스트에 속한다고 가정)
        if (playlistId == null) {
          playlistId = track.playlistId;
        }
      }
      
      // 플레이리스트 업데이트 시간 갱신
      if (playlistId != null) {
        batch.update(_db.collection(playlistsCollection).doc(playlistId), {
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      _logError('updateTrackOrder', e);
      rethrow;
    }
  }
  
  // ─────────────────────────────────────────────────────────
  // (17) 트랙 즐겨찾기 상태 토글
  // ─────────────────────────────────────────────────────────
  Future<void> toggleTrackFavorite(Track track) async {
    try {
      await _db.collection(tracksCollection).doc(track.id).update({
        'isFavorite': !track.isFavorite,
      });
    } catch (e) {
      _logError('toggleTrackFavorite', e);
      rethrow;
    }
  }
  
  // ─────────────────────────────────────────────────────────
  // 내부 에러 로깅 메서드
  // ─────────────────────────────────────────────────────────
  void _logError(String method, dynamic error) {
    if (kDebugMode) {
      print('DatabaseService.$method 오류: $error');
    }
  }
}