// lib/screens/playlist_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';
import 'edit_track_screen.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TTSService _ttsService = TTSService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPlaylist,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeletePlaylist,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTrackScreen(playlistId: widget.playlist.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 플레이리스트 정보
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.playlist.description != null &&
                    widget.playlist.description!.isNotEmpty)
                  Text(
                    widget.playlist.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(widget.playlist.category),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.playlist.trackCount} 항목',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 전체 재생 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _playAll(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('전체 재생'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 트랙 목록 제목
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '트랙 목록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 트랙 목록
          Expanded(
            child: StreamBuilder<List<Track>>(
              stream: _dbService.getPlaylistTracks(widget.playlist.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                final tracks = snapshot.data ?? [];

                if (tracks.isEmpty) {
                  return const Center(
                    child: Text('아직 트랙이 없습니다. + 버튼을 눌러 추가하세요.'),
                  );
                }

                return ReorderableListView.builder(
                  itemCount: tracks.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderTracks(tracks, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Dismissible(
                      key: Key(track.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _confirmDeleteTrack(track);
                      },
                      onDismissed: (direction) {
                        _dbService.deleteTrack(track);
                      },
                      child: ListTile(
                        title: Text(
                          track.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          track.text.length > 50
                              ? '${track.text.substring(0, 50)}...'
                              : track.text,
                        ),
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                track.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: track.isFavorite ? Colors.amber : null,
                              ),
                              onPressed: () => _toggleFavorite(track),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle),
                              onPressed: () =>
                                  _playTrack(context, tracks, index),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTrackScreen(
                                playlistId: widget.playlist.id,
                                track: track,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 트랙 순서 변경
  Future<void> _reorderTracks(
      List<Track> tracks, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<Track> reorderedTracks = List.from(tracks);
    final Track movedTrack = reorderedTracks.removeAt(oldIndex);
    reorderedTracks.insert(newIndex, movedTrack);

    await _dbService.updateTrackOrder(reorderedTracks);
  }

  // 플레이리스트 수정
  void _editPlaylist() {
    // EditPlaylistScreen으로 이동
    // 구현 필요
  }

  // 플레이리스트 삭제 확인
  Future<void> _confirmDeletePlaylist() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 삭제'),
        content: const Text('정말로 이 플레이리스트를 삭제하시겠습니까? 포함된 모든 트랙이 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _dbService.deletePlaylist(widget.playlist.id);
      if (mounted) {
        Navigator.pop(context); // 상세 화면 닫기
      }
    }
  }

  // 트랙 삭제 확인
  Future<bool> _confirmDeleteTrack(Track track) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('트랙 삭제'),
        content: const Text('이 트랙을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // 트랙 즐겨찾기 토글
  Future<void> _toggleFavorite(Track track) async {
    final updatedTrack = track.copyWith(isFavorite: !track.isFavorite);
    await _dbService.updateTrack(updatedTrack);
  }

  // 트랙 재생
  void _playTrack(BuildContext context, List<Track> tracks, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          playlist: widget.playlist,
          tracks: tracks,
          initialIndex: index,
        ),
      ),
    );
  }

  // 전체 재생
  void _playAll(BuildContext context) {
    _dbService.getPlaylistTracks(widget.playlist.id).first.then((tracks) {
      if (tracks.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              playlist: widget.playlist,
              tracks: tracks,
              initialIndex: 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('재생할 트랙이 없습니다')),
        );
      }
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
