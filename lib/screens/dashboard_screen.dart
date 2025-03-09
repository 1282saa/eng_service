// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'learning_screen.dart';
import 'upload_screen.dart';
import 'playlist_list_screen.dart';
import 'playlist_detail_screen.dart';
import '../services/database_service.dart';
import '../models/playlist_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onTabTap(int index) {
    setState(() {
      _tabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EnglishBoost'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // 사용자 프로필 화면 (구현 필요)
            },
          ),
        ],
      ),

      // ※ ① 탭에 따라 바뀌는 본문
      body: _buildTabContents(),

      // ※ ② 하단 탭바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _onTabTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '추천 학습'),
          BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play), label: '플레이리스트'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 학습'),
        ],
      ),

      // ※ ③ 여기서 FAB를 추가하여 UploadScreen으로 이동
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 업로드 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabContents() {
    // 탭 인덱스(_tabIndex)에 따라 다른 위젯 반환
    switch (_tabIndex) {
      case 0:
        return _buildRecommended();
      case 1:
        return _buildPlaylists();
      case 2:
        return _buildMyLearning();
      default:
        return _buildRecommended();
    }
  }

  Widget _buildRecommended() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('추천 학습 탭 예시'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningScreen()),
              );
            },
            child: const Text('학습 시작하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylists() {
    if (_userId.isEmpty) {
      return const Center(child: Text('로그인이 필요합니다'));
    }

    return StreamBuilder<List<Playlist>>(
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
                const Text('아직 플레이리스트가 없습니다'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PlaylistListScreen()),
                    );
                  },
                  child: const Text('플레이리스트 만들기'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '내 플레이리스트',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PlaylistListScreen()),
                      );
                    },
                    child: const Text('전체보기'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount:
                    playlists.length > 5 ? 5 : playlists.length, // 최대 5개만 표시
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        playlist.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${playlist.trackCount}개 항목'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyLearning() {
    return const Center(child: Text('내 학습 탭 (진행도, 통계 등)'));
  }
}
