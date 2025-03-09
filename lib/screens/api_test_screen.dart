// lib/screens/api_test_screen.dart

import 'package:flutter/material.dart';
import '../utils/api_test_util.dart';
import '../config/dev_keys.dart'; // API 키가 있는 파일

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  Map<String, dynamic>? _visionApiResult;
  Map<String, dynamic>? _speechApiResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 기존 API 키로 초기화
    _apiKeyController.text = googleCloudVisionApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // Vision API 테스트
  Future<void> _testVisionApi() async {
    setState(() {
      _isLoading = true;
      _visionApiResult = null;
    });

    final result = await testVisionApiKey(_apiKeyController.text.trim());

    setState(() {
      _visionApiResult = result;
      _isLoading = false;
    });
  }

  // Speech-to-Text API 테스트
  Future<void> _testSpeechApi() async {
    setState(() {
      _isLoading = true;
      _speechApiResult = null;
    });

    final result = await testSpeechApiKey(_apiKeyController.text.trim());

    setState(() {
      _speechApiResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 키 테스트'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Google Cloud API 키',
                border: OutlineInputBorder(),
                hintText: 'API 키를 입력하세요',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testVisionApi,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Vision API 테스트'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSpeechApi,
                  icon: const Icon(Icons.mic),
                  label: const Text('Speech API 테스트'),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_visionApiResult != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Vision API 테스트 결과:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildResultCard(_visionApiResult!),
            ],
            if (_speechApiResult != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Speech API 테스트 결과:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildResultCard(_speechApiResult!),
            ],
          ],
        ),
      ),
    );
  }

  // 결과 카드 UI 위젯
  Widget _buildResultCard(Map<String, dynamic> result) {
    final isSuccess = result['success'] as bool;
    
    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['message'] as String,
                    style: TextStyle(
                      color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('상태 코드: ${result['statusCode']}'),
            const SizedBox(height: 8),
            const Text('응답 데이터:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result['response'] != null 
                    ? result['response'].toString() 
                    : '응답 없음',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}