// // FILE: home_screen.dart

// /*
//   홈 화면(HomeScreen) 예시 코드

//   주요 기능:
//   1) 화면 상단에 AppBar (타이틀 + 프로필아이콘)
//   2) 하단 오른쪽에 FloatingActionButton(FAB)를 통해 업로드(UploadScreen)로 이동
//   3) "최근 업로드" 목록 (가로 스크롤)
//   4) "내 플레이리스트" 목록 (그리드)

//   ※ 실제로 UploadScreen을 사용하려면:
//      import 'upload_screen.dart';
//      그리고 FAB의 onPressed에서 Navigator.push(...)로 이동하면 됩니다.

//   ※ Firebase Firestore 등에서 실제 데이터를 받아오려면:
//      - DatabaseService 등을 사용하여 목록을 쿼리
//      - setState / FutureBuilder / StreamBuilder 등을 통해 화면에 반영
// */

// import 'package:flutter/material.dart';
// // (1) UploadScreen이 있는 파일을 import해야 합니다.
// //     예: import 'package:my_app/screens/upload_screen.dart';
// //     실제 프로젝트 구조에 맞춰 경로 수정!
// import 'upload_screen.dart'; // 예시

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   // (2) 실제로는 FirebaseAuth.currentUser?.displayName 등을 써서
//   //     로그인한 유저명을 가져올 수 있습니다.
//   //     여기서는 예시로 "홍길동"만 지정
//   final String _userName = "홍길동";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // (3) AppBar 영역
//       appBar: AppBar(
//         title: const Text(
//           "내 지식 플레이리스트",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {
//               // TODO: 프로필 화면 이동 (Settings, Profile 등)
//               // Navigator.push(...);
//             },
//             icon: const Icon(Icons.person_outline),
//           ),
//         ],
//       ),

//       // (4) 우측 하단 + 버튼(FAB): 업로드 화면으로 이동
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // 이 부분에서 업로드 화면(UploadScreen)으로 네비게이트합니다.
//           // push or pushReplacement 중 상황에 따라 결정
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const UploadScreen()),
//           );
//         },
//         child: const Icon(Icons.add),
//       ),

//       // (5) 본문
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // (5-1) "홍길동님, 반갑습니다!" 환영 카드
//             _buildGreetingCard(),
//             const SizedBox(height: 24),

//             // (5-2) 최근 업로드 섹션
//             Text(
//               "최근 업로드",
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//             ),
//             const SizedBox(height: 8),
//             _buildRecentUploadsSection(),
//             const SizedBox(height: 24),

//             // (5-3) 플레이리스트 섹션
//             Text(
//               "내 플레이리스트",
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//             ),
//             const SizedBox(height: 8),
//             _buildPlaylistSection(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────
//   // (A) 환영 카드 빌드
//   // ─────────────────────────────────────────────────────────
//   Widget _buildGreetingCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: Colors.blue, // 배경색
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 유저 이름 표시
//             Text(
//               "$_userName님, 반갑습니다!",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             // 서브 문구
//             const Text(
//               "오늘도 지식을 업로드하고 들어보세요!",
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────
//   // (B) 최근 업로드 섹션 (가로 스크롤)
//   // ─────────────────────────────────────────────────────────
//   Widget _buildRecentUploadsSection() {
//     // 임시 mock data.
//     // 실제 프로젝트에서는 Firestore 등 DB에서 가져오거나
//     // Provider / Riverpod / Bloc 등 상태관리로 로딩 후 표시
//     final recent = [
//       {"title": "영어단어 Day1", "date": "2025-03-07"},
//       {"title": "독서노트(동화책)", "date": "2025-03-06"},
//       {"title": "TED 강연 요약", "date": "2025-03-05"},
//     ];

//     return SizedBox(
//       height: 120, // 세로 길이를 120 고정
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal, // 가로 스크롤
//         itemCount: recent.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemBuilder: (context, index) {
//           final item = recent[index];
//           return GestureDetector(
//             onTap: () {
//               // TODO: 업로드 상세 페이지로 이동
//               // Navigator.push(...);
//             },
//             child: Container(
//               width: 160,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50, // 옅은 파랑 배경
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 업로드 제목
//                   Text(
//                     item["title"] ?? "",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const Spacer(),
//                   // 업로드 날짜
//                   Text(
//                     "작성일: ${item["date"]}",
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────
//   // (C) 플레이리스트 섹션 (2컬럼 그리드)
//   // ─────────────────────────────────────────────────────────
//   Widget _buildPlaylistSection() {
//     // 임시 mock data
//     final playlists = [
//       {"title": "TOEIC 단어", "count": "12개"},
//       {"title": "자기계발 명언", "count": "5개"},
//       {"title": "동화 오디오북", "count": "8개"},
//     ];

//     return GridView.builder(
//       shrinkWrap: true,
//       // 스크롤을 안에서 처리하지 않고, 상위의 SingleChildScrollView에서 처리
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: playlists.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2, // 한 행에 2개씩
//         childAspectRatio: 1.6, // 카드 가로:세로 비율
//         crossAxisSpacing: 12, // 카드 간 가로 여백
//         mainAxisSpacing: 12, // 카드 간 세로 여백
//       ),
//       itemBuilder: (context, index) {
//         final p = playlists[index];
//         return GestureDetector(
//           onTap: () {
//             // TODO: Playlist 상세 페이지로 이동
//             // Navigator.push(...);
//           },
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.purple.shade50,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 플레이리스트 제목
//                 Text(
//                   p["title"] ?? "",
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const Spacer(),
//                 // 플레이리스트 트랙 수
//                 Text(
//                   "트랙 수: ${p["count"]}",
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
