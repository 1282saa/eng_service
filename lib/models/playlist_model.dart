// lib/models/playlist_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;
  final String category;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
    this.category = 'General',
  });

  // Firestore에서 데이터 변환
  factory Playlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Playlist(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      trackCount: data['trackCount'] ?? 0,
      category: data['category'] ?? 'General',
    );
  }

  // Firestore에 저장할 데이터
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'trackCount': trackCount,
      'category': category,
    };
  }

  // 객체 복사 (with 수정)
  Playlist copyWith({
    String? title,
    String? description,
    int? trackCount,
    String? category,
  }) {
    return Playlist(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      trackCount: trackCount ?? this.trackCount,
      category: category ?? this.category,
    );
  }
}
