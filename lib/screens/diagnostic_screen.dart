import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 쓰려면
import '../services/database_service.dart';
import 'dashboard_screen.dart';

/// 진단 테스트 화면
class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  /// Firestore 연동 예시를 위해 DatabaseService 준비
  final DatabaseService _dbService = DatabaseService();

  // 질문 목록 (예시)
  final List<String> questions = [
    '현재 영어 수준을 어떻게 평가하시나요?',
    '영어 학습의 주요 목적은 무엇인가요?',
    '가장 필요한 영어 스킬은 무엇인가요?',
  ];

  // 각 질문별로 몇 가지 보기가 있다고 가정 (여기선 보기 수가 동일하다고 치고, 단순 예시)
  final List<List<String>> options = [
    ['초급', '중급', '고급'],
    ['비즈니스 영어', '토익 점수', '일상 회화'],
    ['이메일 작성', '전화 영어', '프레젠테이션'],
  ];

  // 현재 몇 번째 질문인지
  int currentStep = 0;

  // 사용자가 선택한 답변 인덱스를 저장
  late List<int?> answers;

  @override
  void initState() {
    super.initState();
    // 질문 개수만큼 null로 채운 List 생성
    answers = List.filled(questions.length, null);
  }

  /// 특정 보기(index)를 선택하면 answers[currentStep]에 저장
  void _selectAnswer(int index) {
    setState(() {
      answers[currentStep] = index;
    });
  }

  /// "다음" 혹은 "결과 확인" 버튼 로직
  void _goNext() async {
    // 아직 마지막 질문이 아니라면 다음 질문으로 이동
    if (currentStep < questions.length - 1) {
      setState(() => currentStep++);
    } else {
      // 마지막 질문이었다면 → 진단 결과를 Firestore에 저장 (예시)
      // 실제 앱에서는 현재 사용자의 UID를 FirebaseAuth 등에서 가져와야 합니다.
      final String fakeUserId = 'dummyUserId123'; // 예시용 가짜 유저ID

      // 예시로, answers를 "0=초급, 1=중급, 2=고급" 같은 index로 저장한다고 가정
      // 더 복잡한 데이터(문자열)로 변환해 저장할 수도 있음
      final Map<String, dynamic> diagnosticData = {
        'answers': answers, // 예: [0, 2, 1] 등
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Firestore에 저장 (DatabaseService 이용)
      await _dbService.saveDiagnosticResults(fakeUserId, diagnosticData);

      // 그리고 대시보드 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  /// "이전" 버튼 로직
  void _goPrev() {
    // 첫 질문이 아니라면 이전 질문으로
    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      // 첫번째 질문에서 '이전'을 누르면 그냥 pop() → 이전 화면(Login 등)으로 돌아감
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 질문 텍스트
    final questionText = questions[currentStep];
    // 현재 질문에 대응하는 보기 목록
    final currentOptions = options[currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 진단 테스트'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goPrev, // 이전 단계를 처리
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 단계 표시 (ex: "문항 1/3")
                  Text('문항 ${currentStep + 1} / ${questions.length}'),

                  const SizedBox(height: 12),

                  // 질문 표시
                  Text(
                    questionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // 보기들
                  for (int i = 0; i < currentOptions.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: () => _selectAnswer(i),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: (answers[currentStep] == i)
                              ? Colors.blue.shade50
                              : null,
                          side: BorderSide(
                            color: (answers[currentStep] == i)
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        child: Text(currentOptions[i]),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 하단 버튼들 (이전 / 다음 or 결과확인)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 이전 버튼
                      TextButton(
                        onPressed: _goPrev,
                        child: const Text('이전'),
                      ),

                      // 다음(또는 결과확인) 버튼
                      ElevatedButton(
                        onPressed: _goNext,
                        child: (currentStep < questions.length - 1)
                            ? const Text('다음')
                            : const Text('결과 확인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
