// lib/screens/player_screen.dart

import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../services/tts_service.dart';

class PlayerScreen extends StatefulWidget {
  final Playlist playlist;
  final List<Track> tracks;
  final int initialIndex;

  const PlayerScreen({
    Key? key,
    required this.playlist,
    required this.tracks,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final TTSService _ttsService = TTSService();

  late int _currentIndex;
  bool _isPlaying = false;
  bool _isRepeatEnabled = false;
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initPlayer();
  }

  void _initPlayer() async {
    await _ttsService.initialize();
    // 첫 트랙 자동 재생
    _playCurrentTrack();
  }

  void _playCurrentTrack() async {
    if (_currentIndex < 0 || _currentIndex >= widget.tracks.length) return;

    final track = widget.tracks[_currentIndex];

    setState(() => _isPlaying = true);
    await _ttsService.setSpeechRate(_playbackRate);
    await _ttsService.speak(track.text);

    // TTS 재생이 끝났을 때
    setState(() => _isPlaying = false);

    // 반복 모드이면 현재 트랙 다시 재생, 아니면 다음 트랙
    if (_isRepeatEnabled) {
      _playCurrentTrack();
    } else {
      _playNextTrack();
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      _playCurrentTrack();
    }
  }

  void _playNextTrack() {
    if (_currentIndex < widget.tracks.length - 1) {
      setState(() => _currentIndex++);
      _playCurrentTrack();
    }
  }

  void _playPreviousTrack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _playCurrentTrack();
    }
  }

  void _toggleRepeat() {
    setState(() => _isRepeatEnabled = !_isRepeatEnabled);
  }

  void _changePlaybackRate() {
    final rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('재생 속도'),
        content: SizedBox(
          height: 200,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: rates.length,
            itemBuilder: (context, index) {
              final rate = rates[index];
              return ListTile(
                title: Text('${rate}x'),
                selected: rate == _playbackRate,
                onTap: () {
                  setState(() => _playbackRate = rate);
                  _ttsService.setSpeechRate(rate);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = widget.tracks[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.title),
      ),
      body: Column(
        children: [
          // 현재 트랙 정보
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Text(
                  currentTrack.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '트랙 ${_currentIndex + 1}/${widget.tracks.length}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // 텍스트 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                currentTrack.text,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ),
          ),

          // 재생 컨트롤
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 재생 속도
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _changePlaybackRate,
                      icon: const Icon(Icons.speed),
                      label: Text('${_playbackRate}x'),
                    ),
                  ],
                ),

                // 재생 컨트롤 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isRepeatEnabled ? Icons.repeat_one : Icons.repeat,
                        color: _isRepeatEnabled ? Colors.blue : Colors.grey,
                      ),
                      onPressed: _toggleRepeat,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: _currentIndex > 0 ? _playPreviousTrack : null,
                    ),
                    FloatingActionButton(
                      onPressed: _togglePlayPause,
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: _currentIndex < widget.tracks.length - 1
                          ? _playNextTrack
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        currentTrack.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        color: currentTrack.isFavorite ? Colors.amber : null,
                      ),
                      onPressed: () {
                        // 즐겨찾기 토글 기능 (구현 필요)
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
