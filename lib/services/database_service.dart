// lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

/// Firestore 관련 데이터 처리를 모아둔 서비스 클래스
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────
  // (1) 사용자 프로필 저장/업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> saveUserProfile(
      String userId, Map<String, dynamic> userData) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(userData, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────
  // (2) 사용자 프로필 가져오기
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  // ─────────────────────────────────────────────────────────
  // (3) 진단 테스트 결과 저장
  // ─────────────────────────────────────────────────────────
  Future<void> saveDiagnosticResults(
      String userId, Map<String, dynamic> results) async {
    await _db.collection('users').doc(userId).collection('diagnostics').add({
      'timestamp': FieldValue.serverTimestamp(),
      ...results,
    });
  }

  // ─────────────────────────────────────────────────────────
  // (4) 학습 콘텐츠 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLearningContents(
      String category, String level) async {
    final snapshot = await _db
        .collection('contents')
        .where('category', isEqualTo: category)
        .where('level', isEqualTo: level)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────
  // (5) 학습 진행 상황 저장
  // ─────────────────────────────────────────────────────────
  Future<void> saveProgress(
      String userId, String contentId, int progress) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(contentId)
        .set({
      'progress': progress,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────
  // (6) 사용자의 학습 진행 상황 가져오기
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final snapshot =
        await _db.collection('users').doc(userId).collection('progress').get();

    final Map<String, dynamic> progress = {};
    for (var doc in snapshot.docs) {
      progress[doc.id] = doc.data();
    }

    return progress;
  }

  // ─────────────────────────────────────────────────────────
  // (7) 플레이리스트 생성
  // ─────────────────────────────────────────────────────────
  Future<String> createPlaylist(Playlist playlist) async {
    final docRef =
        await _db.collection('playlists').add(playlist.toFirestore());
    return docRef.id;
  }

  // ─────────────────────────────────────────────────────────
  // (8) 플레이리스트 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updatePlaylist(Playlist playlist) async {
    await _db
        .collection('playlists')
        .doc(playlist.id)
        .update(playlist.toFirestore());
  }

  // ─────────────────────────────────────────────────────────
  // (9) 플레이리스트 삭제
  // ─────────────────────────────────────────────────────────
  Future<void> deletePlaylist(String playlistId) async {
    // 플레이리스트 삭제 전에 관련된 모든 트랙도 삭제
    final tracks = await _db
        .collection('tracks')
        .where('playlistId', isEqualTo: playlistId)
        .get();

    // 배치 작업으로 트랙들 모두 삭제
    final batch = _db.batch();
    for (var doc in tracks.docs) {
      batch.delete(doc.reference);
    }

    // 플레이리스트 자체도 삭제
    batch.delete(_db.collection('playlists').doc(playlistId));

    // 배치 커밋
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────
  // (10) 사용자의 플레이리스트 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Playlist>> getUserPlaylists(String userId) {
    return _db
        .collection('playlists')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Playlist.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────────────────
  // (11) 트랙 추가
  // ─────────────────────────────────────────────────────────
  Future<String> addTrack(Track track) async {
    // 트랙 추가
    final docRef = await _db.collection('tracks').add(track.toFirestore());

    // 플레이리스트의 트랙 수 업데이트
    await _db.collection('playlists').doc(track.playlistId).update({
      'trackCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // ─────────────────────────────────────────────────────────
  // (12) 트랙 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updateTrack(Track track) async {
    await _db.collection('tracks').doc(track.id).update(track.toFirestore());
  }

  // ─────────────────────────────────────────────────────────
  // (13) 트랙 삭제
  // ─────────────────────────────────────────────────────────
  Future<void> deleteTrack(Track track) async {
    // 트랙 삭제
    await _db.collection('tracks').doc(track.id).delete();

    // 플레이리스트의 트랙 수 감소
    await _db.collection('playlists').doc(track.playlistId).update({
      'trackCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────
  // (14) 플레이리스트의 트랙 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Track>> getPlaylistTracks(String playlistId) {
    return _db
        .collection('tracks')
        .where('playlistId', isEqualTo: playlistId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Track.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────────────────
  // (15) 즐겨찾기 트랙 목록 가져오기
  // ─────────────────────────────────────────────────────────
  Stream<List<Track>> getFavoriteTracks(String userId) {
    return _db
        .collection('tracks')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Track.fromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────────────────
  // (16) 트랙 순서 업데이트
  // ─────────────────────────────────────────────────────────
  Future<void> updateTrackOrder(List<Track> tracks) async {
    final batch = _db.batch();

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      batch.update(_db.collection('tracks').doc(track.id), {'order': i});
    }

    await batch.commit();
  }
}
