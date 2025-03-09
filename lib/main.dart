// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/api_test_screen.dart'; // API 테스트 화면 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnglishBoost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      // 디버그 메뉴를 포함한 로그인 화면을 홈으로 설정
      home: kDebugMode 
          ? _buildDebugWrapper(const LoginScreen()) 
          : const LoginScreen(),
    );
  }
  
  // 디버그 모드에서만 보이는 플로팅 메뉴 버튼을 추가하는 래퍼
  Widget _buildDebugWrapper(Widget child) {
    return Builder(
      builder: (context) => Scaffold(
        body: child,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          child: const Icon(Icons.bug_report),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.api),
                    title: const Text('API 키 테스트'),
                    onTap: () {
                      Navigator.pop(context); // 바텀 시트 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApiTestScreen()),
                      );
                    },
                  ),
                  // 다른 디버그 옵션들을 필요에 따라 추가
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('앱 정보'),
                    onTap: () {
                      Navigator.pop(context); // 바텀 시트 닫기
                      showAboutDialog(
                        context: context,
                        applicationName: 'EnglishBoost',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.language),
                        children: [
                          const Text('영어 학습을 위한 앱입니다.'),
                          const SizedBox(height: 8),
                          const Text('디버그 모드에서만 볼 수 있는 정보입니다.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}