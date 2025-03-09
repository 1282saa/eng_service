// lib/screens/upload_screen.dart

import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ocr_service.dart';
import '../services/tts_service.dart';
import '../services/database_service.dart';
import '../models/track_model.dart';
import 'create_playlist_screen.dart';
import 'playlist_list_screen.dart';
import '../config/dev_keys.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  // 서비스 인스턴스
  final TTSService _ttsService = TTSService();
  final DatabaseService _dbService = DatabaseService();

  // 탭 3개 (Photo, Text, Audio)
  late TabController _tabController;

  // Text 탭: 사용자가 입력한 텍스트
  final TextEditingController _textController = TextEditingController();

  // OCR 결과 텍스트
  String? _photoOcrText;
  // STT 결과 텍스트
  String? _audioSttText;

  // 미리 듣기 상태
  bool _isPlaying = false;

  // 플레이리스트 ID (선택된 경우)
  String? _selectedPlaylistId;
  String? _selectedPlaylistTitle;

  @override
  void initState() {
    super.initState();
    // 탭은 3개
    _tabController = TabController(length: 3, vsync: this);

    // TTS 초기화
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  // 상단 AppBar의 '저장' 아이콘 로직
  Future<void> _saveData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 현재 탭에 따라 저장할 텍스트 결정
    String? textToSave;
    switch (_tabController.index) {
      case 0: // Photo 탭
        textToSave = _photoOcrText;
        break;
      case 1: // Text 탭
        textToSave = _textController.text.trim();
        break;
      case 2: // Audio 탭
        textToSave = _audioSttText;
        break;
    }

    if (textToSave == null || textToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 내용이 없습니다')),
      );
      return;
    }

    // 플레이리스트 선택 또는 생성 대화상자
    await _showPlaylistSelectionDialog(textToSave);
  }

  // 플레이리스트 선택 대화상자
  Future<void> _showPlaylistSelectionDialog(String text) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 플레이리스트 목록 가져오기
    final playlists = await _dbService.getUserPlaylists(userId).first;

    if (!mounted) return;

    // 대화상자로 플레이리스트 선택
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('플레이리스트 선택'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: playlists.isEmpty
              ? const Center(child: Text('플레이리스트가 없습니다.\n새 플레이리스트를 만드세요.'))
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      title: Text(playlist.title),
                      subtitle: Text('${playlist.trackCount}개 항목'),
                      onTap: () {
                        setState(() {
                          _selectedPlaylistId = playlist.id;
                          _selectedPlaylistTitle = playlist.title;
                        });
                        Navigator.pop(context);
                        _showCreateTrackDialog(text);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()),
              ).then((_) => _saveData());
            },
            child: const Text('새 플레이리스트'),
          ),
        ],
      ),
    );
  }

  // 트랙 생성 대화상자
  Future<void> _showCreateTrackDialog(String text) async {
    if (_selectedPlaylistId == null) return;

    final titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('트랙 제목 입력'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '제목',
            hintText: '트랙 제목을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('제목을 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context);
              await _createTrack(title, text);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 트랙 생성
  Future<void> _createTrack(String title, String text) async {
    try {
      final track = Track(
        id: '',
        playlistId: _selectedPlaylistId!,
        title: title,
        text: text,
        audioUrl: null, // 오디오 URL은 나중에 설정
        createdAt: DateTime.now(),
        order: 999, // 임시 순서 (나중에 Firestore에서 조정)
        isFavorite: false,
      );

      await _dbService.addTrack(track);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('트랙이 "${_selectedPlaylistTitle}" 플레이리스트에 추가되었습니다')),
        );

        // 플레이리스트 화면으로 이동

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistListScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  // Photo 탭: 이미지 파일 → OCR
  Future<void> _handlePhotoUpload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image);
      if (picked == null || picked.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("파일 선택이 취소됨")),
        );
        return;
      }

      final file = picked.files.single; // 한 개만 선택 가정
      String recognizedText = "";

      // 1) 웹인지, 모바일(데스크톱)인지
      if (kIsWeb) {
        final fileBytes = file.bytes; // Uint8List?
        if (fileBytes == null) {
          // 웹에서 bytes가 없으면 OCR 불가
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("웹 환경: 파일 bytes가 없습니다.")),
          );
          return;
        }
        // 2) Cloud Vision에 전송
        recognizedText = await callCloudVisionOcr(
          imageBytes: fileBytes,
          apiKey: googleCloudVisionApiKey, // 설정 파일에서 가져오기
        );
      } else {
        // 모바일/데스크톱
        final path = file.path;
        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("파일 경로가 비었습니다.")),
          );
          return;
        }
        // 파일 읽어 Uint8List로 변환
        final rawBytes = await File(path).readAsBytes();

        recognizedText = await callCloudVisionOcr(
          imageBytes: rawBytes,
          apiKey: googleCloudVisionApiKey, // 설정 파일에서 가져오기
        );
      }

      setState(() => _photoOcrText = recognizedText);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사진 업로드 & OCR 완료")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    }
  }

  // Text 탭 로직
  Future<void> _handleTextSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("텍스트를 입력하세요.")),
      );
      return;
    }

    // TTS 미리 듣기
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _ttsService.speak(text);
      setState(() => _isPlaying = false);
    }
  }

  // Audio 탭 로직
  Future<void> _handleAudioUpload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (picked == null || picked.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("오디오 선택 취소됨")),
        );
        return;
      }

      // STT 기능은 아직 구현되지 않았습니다.
      // 여기에 STT API 연동 코드가 필요합니다.

      // 임시 처리
      setState(() {
        _audioSttText = "STT 기능이 아직 구현되지 않았습니다. 이 텍스트는 예시입니다.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오디오 업로드 완료")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("업로드하기"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Photo"),
            Tab(text: "Text"),
            Tab(text: "Audio"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotoTab(),
          _buildTextTab(),
          _buildAudioTab(),
        ],
      ),
    );
  }

  // PHOTO 탭 UI
  Widget _buildPhotoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _handlePhotoUpload,
            icon: const Icon(Icons.photo_camera),
            label: const Text("사진 업로드"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          if (_photoOcrText != null) ...[
            const Text("OCR 결과:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_photoOcrText!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_isPlaying) {
                  await _ttsService.stop();
                  setState(() => _isPlaying = false);
                } else {
                  setState(() => _isPlaying = true);
                  await _ttsService.speak(_photoOcrText!);
                  setState(() => _isPlaying = false);
                }
              },
              icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
              label: Text(_isPlaying ? "중지" : "TTS로 듣기"),
            ),
          ],
        ],
      ),
    );
  }

  // TEXT 탭 UI
  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("텍스트를 입력하거나 붙여넣기"),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "여기에 입력...",
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _handleTextSubmit,
            icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
            label: Text(_isPlaying ? "중지" : "TTS로 듣기"),
          ),
        ],
      ),
    );
  }

  // AUDIO 탭 UI
  Widget _buildAudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _handleAudioUpload,
            icon: const Icon(Icons.mic),
            label: const Text("오디오/동영상 업로드"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          if (_audioSttText != null) ...[
            const Text("STT 변환 결과:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_audioSttText!),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_isPlaying) {
                  await _ttsService.stop();
                  setState(() => _isPlaying = false);
                } else {
                  setState(() => _isPlaying = true);
                  await _ttsService.speak(_audioSttText!);
                  setState(() => _isPlaying = false);
                }
              },
              icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
              label: Text(_isPlaying ? "중지" : "TTS로 듣기"),
            ),
          ],
        ],
      ),
    );
  }
}
