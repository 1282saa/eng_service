// FILE: lib/services/ocr_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Google Cloud Vision API를 통해 OCR 처리
Future<String> callCloudVisionOcr({
  required List<int> imageBytes,
  required String apiKey,
}) async {
  // 1) base64 인코딩
  final base64Image = base64Encode(imageBytes);

  // 2) API 엔드포인트 (images:annotate)
  final url = Uri.parse(
    'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
  );

  // 3) 요청 바디
  final requestBody = {
    "requests": [
      {
        "image": {"content": base64Image},
        "features": [
          {"type": "TEXT_DETECTION"} // or DOCUMENT_TEXT_DETECTION
        ]
      }
    ]
  };

  // 4) POST 요청
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    // 5) 결과 파싱
    final Map<String, dynamic> jsonData = jsonDecode(response.body);
    final firstRes = jsonData["responses"][0];
    if (firstRes == null) {
      return "No response from Vision API";
    }
    final annotation = firstRes["fullTextAnnotation"];
    if (annotation == null) {
      return "No text found";
    }
    final ocrText = annotation["text"] as String? ?? "";
    return ocrText.trim();
  } else {
    // 6) 오류
    return "Cloud Vision Error: ${response.statusCode} / ${response.body}";
  }
}
