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
      backgroundColor: LIGHT_YELLOW_COLOR,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // 앱바의 높이를 80으로 조정
        child: Column(
          children: [
            AppBar(
              backgroundColor: BLUE_COLOR,
              title: Container(
                padding: const EdgeInsets.all(0.0), // 내부 여백 추가
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 20.0, // 글씨 크기 조절
                    fontWeight: FontWeight.bold,
                    color: PRIMARY_COLOR, // 텍스트 색상
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () async {
                      // Firebase에서 데이터 삭제
                      await FirebaseFirestore.instance
                          .collection('diaries')
                          .doc(widget.diaryId)
                          .delete();

                      // 삭제 후 돌아오면서 DiaryListScreen 새로고침
                      Navigator.pop(context, true); // true를 전달
                    },
                    child: Icon(
                      Icons.delete,  // 삭제 아이콘
                      color: YELLOW_COLOR,  // 아이콘 색상 (원하는 색상으로 변경 가능)
                      size: 30.0,  // 아이콘 크기
                    ),
                  ),
                )
              ],
            ),
            // 앱바 하단에 선 추가
            Container(
              height: 3.0,
              color: PRIMARY_COLOR, // 선 색상
            ),
          ],
        ),
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
                //소요시간
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    writeTime,
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: PRIMARY_COLOR),
                  ),
                ),
                //제목
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,  // 제목 표시
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PRIMARY_COLOR),
                  ),
                ),

                // 이미지 슬라이드 공간
                if (imageUrlData.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      width: 400.0,
                      height: 250.0, // 슬라이드 높이
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
                                borderRadius: BorderRadius.circular(10.0),
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
                    padding: const EdgeInsets.all(13.0),
                    child: Container(
                      width: double.infinity, // 가로 공간을 화면 전체로 확장
                      padding: EdgeInsets.all(13.0),
                      decoration: BoxDecoration(
                        color: WHITE_COLOR,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: PRIMARY_COLOR, // 테두리 색상
                          width: 2.0, // 테두리 두께
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          diaryData['content'] ?? '',
                          style: TextStyle(
                            color: PRIMARY_COLOR,
                            fontSize: 18.0, // 글자 크기 조정
                          ),
                        ),
                      ),
                    ),
                  )

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
