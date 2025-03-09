// lib/widgets/base_scaffold.dart
import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final Widget child; // 실제 각 화면의 콘텐츠
  final String? title; // AppBar 제목
  final bool showBackButton; // 뒤로가기 버튼 표시 여부

  /// 추가: 하단 내비게이션 바나 다른 위젯을 넣을 수 있게
  final Widget? bottomNavigationBar;

  const BaseScaffold({
    Key? key,
    required this.child,
    this.title,
    this.showBackButton = true,
    this.bottomNavigationBar, // 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 공통 설정
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: child,
      // 추가
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
