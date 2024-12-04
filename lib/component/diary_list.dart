import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../component/diary_detail.dart';
import '../component/diary_form.dart';
import '../const/colors.dart';
import '../component/calendar.dart';
import '../model/diary_model.dart';
import '../screen/login_screen.dart';
import '../component/kakao_profile.dart';
import '../component/google_profile.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_user;

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
      googleNickname = googleProfile['googleName'];
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_YELLOW_COLOR,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: BLUE_COLOR, // 배경 색상
                border: Border.all( // 테두리 설정
                  color: PRIMARY_COLOR, // 테두리 색상
                  width: 2.0, // 테두리 두께
                ),
                borderRadius: BorderRadius.circular(0.0), // 테두리 둥글게 처리
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Spacer(), // 왼쪽 여백 추가
                      Text(
                        '     ${kakaoNickname ?? googleNickname ?? '사용자'}\'s Diary',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: PRIMARY_COLOR,
                        ),
                      ),
                      Spacer(), // 오른쪽 여백 추가
                      GestureDetector(
                        onTap: () async {
                          await _logout(context); // 로그아웃 함수 호출
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0.0), // 이미지 위쪽 여백 추가
                          child: Image.asset(
                            'assets/img/logout.png', // 이미지 경로
                            width: 30.0, // 원하는 너비
                            height: 30.0, // 원하는 높이
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 나머지 화면 (일기 목록 등)
            Expanded(
              child: SingleChildScrollView(
                //달력
                child: Column(
                  children: [
                    // 날짜 선택기
                    Container(
                      width: double.infinity,
                      height: 380.0,
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: WHITE_COLOR,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all( // 검정 테두리 추가
                              color: PRIMARY_COLOR, // 테두리 색상
                              width: 2.0, // 테두리 두께
                            ),
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

                        //no dairy
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/img/empty.png', // 이미지 경로
                                    width: 200.0, // 원하는 너비
                                    height: 200.0, // 원하는 높이
                                  ),
                                ],
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
                          padding: const EdgeInsets.all(13.0),
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


                            //일기o
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(13.0),
                              decoration: BoxDecoration(
                                color: DARK_PINK_COLOR,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: Colors.black, // 테두리 색상
                                  width: 2.0, // 테두리 두께
                                ),
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
                                      color: PRIMARY_COLOR,
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
                                      color: PRIMARY_COLOR,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 15.0),

                                  //상세
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        color: YELLOW_COLOR, // 배경색
                                        borderRadius: BorderRadius.circular(20.0), // 테두리 모서리 둥글게
                                        border: Border.all(
                                          color: PRIMARY_COLOR, // 테두리 색상
                                          width: 2.0, // 테두리 두께
                                        ),
                                      ),
                                      child: Text(
                                        "                             상  세                             ",
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: PRIMARY_COLOR,
                                        ),
                                      ),
                                    ),
                                  )
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
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: PRIMARY_COLOR, // 테두리 색상
                  width: 2.0, // 테두리 두께
                ),
                borderRadius: BorderRadius.circular(18.0), // 모서리 둥글게
              ),
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text(
                  '오늘의 일기 작성 !',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // 글씨 굵게
                    fontSize: 14.0, // 글씨 크기 조절
                  ),
                ),
                backgroundColor: YELLOW_COLOR, // 버튼 배경 색상 변경
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
              ),
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
      // Firebase 인증된 사용자 삭제
      firebase_auth.User? firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Firestore에서 사용자 정보 삭제
        await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).delete();
        print('Firebase 사용자 정보 Firestore 삭제 성공');

        // Firebase Authentication에서 사용자 계정 삭제
        await firebaseUser.delete();
        print('Firebase 사용자 계정 삭제 성공');
      }

      // Firebase 및 Google 로그아웃
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      print('Google 로그아웃 성공');

      // Kakao 로그아웃
      try {
        await kakao_user.UserApi.instance.logout();
        print('Kakao 로그아웃 성공');
      } catch (error) {
        print('카카오 로그아웃 실패: $error');
      }

      // 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LogScreen()),
            (route) => false, // 모든 이전 화면을 제거하고 로그인 화면으로 이동
      );
    } catch (error) {
      print('로그아웃 실패: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $error')),
      );
    }
  }

}