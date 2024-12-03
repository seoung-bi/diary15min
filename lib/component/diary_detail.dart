import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../const/colors.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;
  final DateTime selectedDate;

  const DiaryDetailScreen({
    Key? key,
    required this.diaryId,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _DiaryDetailScreenState createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // selectedDate를 원하는 형식으로 포맷
    String formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: GRAY_COLOR,
      appBar: AppBar(
        backgroundColor: GRAY_COLOR,
        title: Text(formattedDate),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // Firebase에서 데이터 삭제
                await FirebaseFirestore.instance
                    .collection('diaries')
                    .doc(widget.diaryId)
                    .delete();

                // 삭제 후 돌아오면서 DiaryListScreen 새로고침
                Navigator.pop(context, true); // true를 전달
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('diaries')
              .doc(widget.diaryId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text("일기 정보를 찾을 수 없습니다."),
              );
            }

            var diaryData = snapshot.data!.data() as Map<String, dynamic>;

            List<String> imageUrls = [];
            var imageUrlData = diaryData['imageUrl'];

            // 콤마로 구분된 문자열을 배열로 변환
            if (imageUrlData is String) {
              imageUrls = imageUrlData.split(',').map((url) => url.trim()).toList();
            }

            String writeTime = "${diaryData['timerMin']} : ${diaryData['timerSec']}";
            String title = diaryData['title'] ?? 'No Title'; // 제목 가져오기

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    writeTime,
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: DARK_VIOLET_COLOR),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,  // 제목 표시
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: DARK_VIOLET_COLOR),
                  ),
                ),
                // 이미지 슬라이드 공간
                if (imageUrlData.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      height: 200.0, // 슬라이드 높이
                      child: PageView.builder(
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _viewImage(imageUrls[index]),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(imageUrls[index]),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity, // 가로 공간을 화면 전체로 확장
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: WHITE_COLOR,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          diaryData['content'] ?? '',
                          style: TextStyle(color: DARK_VIOLET_COLOR),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 이미지를 크게 보기 위한 처리 (예: 다른 화면으로 이동)
  void _viewImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,  // BoxFit.contain으로 수정하여 이미지 비율을 유지하면서 화면에 맞게 크기를 조정
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}