// lib/screens/playlist_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/playlist_model.dart';
import '../services/database_service.dart';
import 'playlist_detail_screen.dart';
import 'create_playlist_screen.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 플레이리스트'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: _dbService.getUserPlaylists(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          final playlists = snapshot.data ?? [];

          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('아직 플레이리스트가 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreatePlaylistScreen()),
                      );
                    },
                    child: const Text('첫 플레이리스트 만들기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    playlist.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${playlist.trackCount}개 항목 • ${_formatDate(playlist.updatedAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlist),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
