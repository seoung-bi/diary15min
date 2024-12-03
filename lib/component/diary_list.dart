import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../component/diary_detail.dart';
import '../component/diary_form.dart';
import '../const/colors.dart';
import '../component/calendar.dart';
import '../model/diary_model.dart';
import '../screen/login_screen.dart';
import '../component/kakao_profile.dart';
import '../component/google_profile.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({Key? key}) : super(key: key);

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  DateTime selectedDate = DateTime.now(); // 초기 날짜는 오늘로 설정
  String? kakaoNickname; // 카카오톡 닉네임 저장 변수
  String? googleNickname; // 구글 닉네임 저장 변수


  @override
  void initState() {
    super.initState();
    _loadKakaoProfile(); // 카카오톡 프로필 로드
    _loadGoogleProfile(); //구글
  }

  // 카카오톡 프로필 로드
  Future<void> _loadKakaoProfile() async {
    ProfileService_ka profileService_ka = ProfileService_ka();
    String? kaNickname = await profileService_ka.getKakaoNickname();
    setState(() {
      kakaoNickname = kaNickname; // 닉네임을 상태에 저장
    });
  }

  //구글 프로필 로드
  Future<void> _loadGoogleProfile() async {
    ProfileService_go profileService_go = ProfileService_go();
    Map<String, String?> googleProfile = await profileService_go.getGoogleProfile();

    setState(() {
      // Map에서 구글 닉네임을 가져와서 상태에 저장
      googleNickname = googleProfile['googleEmail'];
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GRAY_COLOR,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 1.2),
              color: GRAY_COLOR,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ' ${kakaoNickname ?? googleNickname ?? '사용자'}\'s Diary',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: DARK_VIOLET_COLOR,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await _logout(context); // 로그아웃 함수 호출
                    },
                  ),
                ],
              ),
            ),
            // 나머지 화면 (일기 목록 등)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 날짜 선택기
                    Container(
                      width: double.infinity,
                      height: 400.0,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: WHITE_COLOR,
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: [
                              BoxShadow(
                                color: VIOLET_COLOR,
                                spreadRadius: 1,
                                blurRadius: 50,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: DiaryCalendar(
                            selectedDate: selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                            diaryDates: {},
                          ),
                        ),
                      ),
                    ),
                    // 일기 내용 스트림 빌더
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('diaries')
                          .where('date', isEqualTo: _formatDate(selectedDate))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(80.0),
                              child: Opacity(
                                opacity: 0.5,
                                child: Text(
                                  "앗! 일기가 없어요.",
                                  style: TextStyle(
                                    color: DARK_VIOLET_COLOR,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final diaries = snapshot.data!.docs
                            .map((e) => DiaryModel.fromJson(
                          json: e.data() as Map<String, dynamic>,
                        ))
                            .toList();

                        final diary = diaries.first;

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DiaryDetailScreen(
                                      diaryId: diary.id, selectedDate: selectedDate),
                                ),
                              );

                              if (result == true) {
                                setState(() {});
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: LIGHT_VIOLET_COLOR,
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    diary.title, // 제목 표시
                                    style: const TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                      color: DARK_VIOLET_COLOR,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, // 제목이 길어지면 "..."으로 처리
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    diary.content, // 내용 표시
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: DARK_VIOLET_COLOR,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16.0),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        color: LIGHT_YELLOW_COLOR,
                                        borderRadius: BorderRadius.circular(12.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4.0,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "                                상세                                ",
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w400,
                                          color: DARK_VIOLET_COLOR,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('diaries')
            .where('date', isEqualTo: _formatDate(DateTime.now())) // 오늘 날짜에 해당하는 일기만 가져옴
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(); // 로딩 중일 때 버튼 숨기기
          }

          final hasDiary = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          if (!hasDiary) {
            return FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('오늘의 일기 작성 !'),
              onPressed: () {
                final today = DateTime.now();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiaryFormScreen(
                        selectedDate: today), // 오늘 날짜로 일기 작성
                  ),
                ).then((_) {
                  setState(() {
                    // 상태 갱신을 위해 호출
                  });
                });
              },
            );
          }

          return Container(); // 오늘 날짜에 일기가 있으면 버튼 숨기기
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  // 이미지를 크게 보기 위한 처리
  void _viewImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Firebase 및 Google 로그아웃
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LogScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }

    try {
      // Firebase 로그아웃
      await FirebaseAuth.instance.signOut();
      print('Firebase 로그아웃 성공');

      // Kakao 로그아웃
      await UserApi.instance.logout();
      print('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }
}