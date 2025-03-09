import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// 대시보드 화면(회원가입 후 곧바로 이동하는 예시)
import 'dashboard_screen.dart';
// 로그인 화면(회원가입 후 다시 로그인하도록 유도하는 예시)
// import 'login_screen.dart';

/// 회원가입 화면
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false; // 가입 처리중에 로딩 표시
  String _email = ''; // 이메일 입력값
  String _password = ''; // 비밀번호 입력값
  String _passwordConfirm = ''; // 비밀번호 확인 입력값

  /// [회원가입] 처리 메서드
  Future<void> _handleSignup() async {
    // 1) 기본 유효성 검사
    if (_email.isEmpty || _password.isEmpty || _passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }
    if (_password != _passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호와 비밀번호 확인이 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2) Firebase Auth 회원가입
      User? user = await _authService.signUpWithEmail(_email, _password);
      // 만약 AuthService의 signUpWithEmail이 없다면, 직접:
      // final cred = await FirebaseAuth.instance
      //   .createUserWithEmailAndPassword(email: _email, password: _password);
      // User? user = cred.user;

      if (user != null) {
        // 가입 성공 → 이미 FirebaseAuth에 로그인된 상태
        // --------------------------------------------
        // (옵션1) 가입 직후 바로 자동 로그인 & 대시보드로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );

        // --------------------------------------------
        // (옵션2) 가입 후 로그인 화면으로 돌아가게 하려면:
        /*
        Navigator.pop(context); // 회원가입 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인 해주세요.')),
        );
        */
      } else {
        // 가입 실패 (null)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 에러 유형별 처리
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 가입된 이메일입니다.')),
        );
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 형식이 올바르지 않습니다.')),
        );
      } else {
        // 기타 에러
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 오류: ${e.message}')),
        );
      }
    } catch (e) {
      // 기타 예외
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar를 둬서 뒤로가기 버튼/화면제목 표시
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 이메일
            TextField(
              onChanged: (val) => _email = val.trim(),
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호
            TextField(
              onChanged: (val) => _password = val.trim(),
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 비밀번호 확인
            TextField(
              onChanged: (val) => _passwordConfirm = val.trim(),
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // 가입하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('가입하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
