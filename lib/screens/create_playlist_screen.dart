// lib/screens/create_playlist_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/playlist_model.dart';
import '../services/database_service.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _category = 'General';
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Vocabulary',
    'Grammar',
    'Conversation',
    'Business',
    'TOEIC',
    'Other'
  ];

  Future<void> _createPlaylist() async {
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

      final playlist = Playlist(
        id: '', // Firestore에서 자동 생성됨
        title: _title,
        description: _description,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        trackCount: 0,
        category: _category,
      );

      await _dbService.createPlaylist(playlist);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플레이리스트가 생성되었습니다')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 플레이리스트'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '플레이리스트 이름을 입력하세요',
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
              decoration: const InputDecoration(
                labelText: '설명 (선택사항)',
                hintText: '플레이리스트에 대한 설명을 입력하세요',
              ),
              maxLines: 3,
              onSaved: (value) => _description = value?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '카테고리',
              ),
              value: _category,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value ?? 'General';
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPlaylist,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('플레이리스트 생성'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
