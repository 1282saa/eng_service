// lib/models/track_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final String id;
  final String playlistId;
  final String title;
  final String text;
  final String? audioUrl;
  final DateTime createdAt;
  final int order;
  final bool isFavorite;

  Track({
    required this.id,
    required this.playlistId,
    required this.title,
    required this.text,
    this.audioUrl,
    required this.createdAt,
    required this.order,
    this.isFavorite = false,
  });

  // Firestore에서 데이터 변환
  factory Track.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Track(
      id: doc.id,
      playlistId: data['playlistId'] ?? '',
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      audioUrl: data['audioUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      order: data['order'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  // Firestore에 저장할 데이터
  Map<String, dynamic> toFirestore() {
    return {
      'playlistId': playlistId,
      'title': title,
      'text': text,
      'audioUrl': audioUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'order': order,
      'isFavorite': isFavorite,
    };
  }

  // 객체 복사 (with 수정)
  Track copyWith({
    String? title,
    String? text,
    String? audioUrl,
    int? order,
    bool? isFavorite,
  }) {
    return Track(
      id: id,
      playlistId: playlistId,
      title: title ?? this.title,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
