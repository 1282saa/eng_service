// FILE: login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
// [ADDED] 이전 대화에서, 로그인 성공 후 진단 화면으로 이동하기 위해 import.
import 'diagnostic_screen.dart';
import 'signup_screen.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _email = '';
  String _password = '';

  /// 이메일/비밀번호 로그인
  Future<void> _handleLogin() async {
    // [MODIFIED] 유효성 검사
    if (_email.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // [MODIFIED] Firebase Auth 이메일/비밀번호 로그인
      User? user = await _authService.signInWithEmail(_email, _password);
      if (user != null) {
        // [MODIFIED] 로그인 성공 시 → DiagnosticScreen (진단 화면)으로 이동
        // 뒤로가기 시 로그인 화면이 안 나오게 하려면 pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
        );
      } else {
        // 로그인 실패
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패. 이메일/비번 확인.')),
        );
      }
    } catch (e) {
      // [MODIFIED] 로그인 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 오류: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  /// Google 로그인
  Future<void> _handleGoogleLogin() async {
    // [ADDED] 로딩 상태 표시
    setState(() => _isLoading = true);

    try {
      // [MODIFIED] Google 로그인 로직
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        // Google 로그인 성공 → DiagnosticScreen으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
        );
      } else {
        // Google 로그인 실패/취소
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 로그인 실패/취소')),
        );
      }
    } catch (e) {
      // Google 로그인 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 오류: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  /// '가입하기' 버튼 → 회원가입 화면 이동
  void _goSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [MODIFIED] 로그인 화면이므로 뒤로가기 버튼을 없앰
      appBar: AppBar(
        title: const Text('로그인'),
        automaticallyImplyLeading: false, // 뒤로가기 아이콘 비활성화
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // [MODIFIED] 앱 로고/타이틀
                      const Text(
                        'EnglishBoost',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '비즈니스 영어와 토익을 한번에',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // 이메일 입력
                      TextField(
                        onChanged: (v) => _email = v.trim(),
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 입력
                      TextField(
                        onChanged: (v) => _password = v.trim(),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),

                      // 로그인 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google 로그인 버튼
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Google로 계속하기'),
                      ),
                      const SizedBox(height: 24),

                      // 가입하기 안내
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '계정이 없으신가요?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _goSignup,
                            child: const Text('가입하기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
