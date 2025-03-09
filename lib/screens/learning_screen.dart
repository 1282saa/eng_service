import 'package:flutter/material.dart';

/// 실제 학습 진행 화면 예시
class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  double progress = 0.3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 화면'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 진행도 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('진행률'),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 16),

            const Text(
              '학습 컨텐츠 예시\n\n비즈니스 이메일 작성 기초 등...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  progress += 0.1;
                  if (progress > 1.0) progress = 1.0;
                });
              },
              child: const Text('진행도 +10%'),
            ),
          ],
        ),
      ),
    );
  }
}
