// lib/screens/edit_track_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/track_model.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';

class EditTrackScreen extends StatefulWidget {
  final String playlistId;
  final Track? track; // 새 트랙이면 null, 수정이면 기존 트랙

  const EditTrackScreen({
    Key? key,
    required this.playlistId,
    this.track,
  }) : super(key: key);

  @override
  State<EditTrackScreen> createState() => _EditTrackScreenState();
}

class _EditTrackScreenState extends State<EditTrackScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TTSService _ttsService = TTSService();
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _text = '';
  bool _isLoading = false;

  // TTS 미리 듣기용
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTrackData();
  }

  void _initTrackData() {
    if (widget.track != null) {
      _title = widget.track!.title;
      _text = widget.track!.text;
    }
  }

  // 트랙 저장 (생성 또는 업데이트)
  Future<void> _saveTrack() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
        return;
      }

      if (widget.track == null) {
        // 새 트랙 생성
        final track = Track(
          id: '',
          playlistId: widget.playlistId,
          title: _title,
          text: _text,
          audioUrl: null, // 오디오 URL은 나중에 설정
          createdAt: DateTime.now(),
          order: 999, // 임시 순서 (나중에 Firestore에서 조정)
          isFavorite: false,
        );

        await _dbService.addTrack(track);
      } else {
        // 기존 트랙 업데이트
        final updatedTrack = widget.track!.copyWith(
          title: _title,
          text: _text,
        );

        await _dbService.updateTrack(updatedTrack);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('트랙이 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TTS로 미리 듣기
  Future<void> _previewWithTTS() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _ttsService.speak(_text);
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.track != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '트랙 수정' : '새 트랙'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '트랙 제목을 입력하세요',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
              onSaved: (value) => _title = value?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _text,
              decoration: const InputDecoration(
                labelText: '텍스트',
                hintText: '학습할 텍스트를 입력하세요',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '텍스트를 입력해주세요';
                }
                return null;
              },
              onSaved: (value) => _text = value?.trim() ?? '',
              maxLines: 10,
            ),
            const SizedBox(height: 24),

            // TTS 미리 듣기 버튼
            OutlinedButton.icon(
              onPressed: _text.isNotEmpty ? _previewWithTTS : null,
              icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
              label: Text(_isPlaying ? '중지' : 'TTS로 미리 듣기'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // 저장 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTrack,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditing ? '트랙 업데이트' : '트랙 생성'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
