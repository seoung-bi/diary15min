import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao_user;

import '../component/diary_list.dart';
import '../const/colors.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_YELLOW_COLOR, // 배경 색상 설정
      body: Column(
        children: [
          // 사용자 정의 상단 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            decoration: BoxDecoration(
              color: BLUE_COLOR,
              border: Border.all(color: PRIMARY_COLOR, width: 3.0), // 테두리 설정
              borderRadius: BorderRadius.circular(0.0), // 둥근 테두리
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: Image.asset(
                      'assets/img/bar.png',
                      width: 90.0, // 이미지 너비
                      height: 30.0, // 이미지 높이
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 본문 영역
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Image.asset(
                    'assets/img/logo.png',
                    width: 300.0, // 로고 너비
                    height: 300.0, // 로고 높이
                  ),
                ),
              ),
              Text(
                '------------------ Social Login ------------------',
                textAlign: TextAlign.center, // 텍스트 가운데 정렬
                style: TextStyle(
                  fontSize: 16.0, // 글자 크기
                  fontWeight: FontWeight.bold, // 글자 굵기
                  color: Colors.grey[700], // 텍스트 색상
                ),
              ),
              GestureDetector(
                onTap: () => googleOnLoginPress(context),
                child: Image.asset(
                  'assets/img/google.png',
                  height: 100.0, // 버튼 높이
                  fit: BoxFit.contain,
                ),
              ),
              GestureDetector(
                onTap: () => kakaoOnLoginPress(context),
                child: Image.asset(
                  'assets/img/kakao.png',
                  height: 100.0, // 버튼 높이
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      )
      ],
      ),
    );
  }

  // 구글 로그인 처리
  Future<void> googleOnLoginPress(BuildContext context) async {
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

    try {
      // 구글 계정 로그인
      GoogleSignInAccount? account = await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await account?.authentication;

      if (googleAuth == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 취소')));
        return;
      }

      // Firebase에 인증
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장
      firebase_auth.User? user = result.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? "익명 사용자",
          'photoURL': user.photoURL ?? "",
          'lastLogin': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true)); // 기존 데이터 병합
        print('Firestore에 사용자 정보 저장 성공');
      }

      // 성공 후 화면 전환
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiaryListScreen(),
        ),
      );
    } catch (error) {
      // 구체적인 에러 메시지 처리
      print('구글 로그인 실패: $error');
      String errorMessage = error is firebase_auth.FirebaseAuthException
          ? 'Firebase 인증 실패: ${error.message}'
          : '알 수 없는 에러 발생';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }



  // 카카오 로그인 처리
  Future<void> kakaoOnLoginPress(BuildContext context) async {
    try {
      // 카카오 계정으로 로그인
      kakao_user.OAuthToken token = await kakao_user.UserApi.instance.loginWithKakaoAccount();
      print('로그인 성공 ${token.accessToken}');

      // Firebase 인증 처리
      var providerBuilder = firebase_auth.OAuthProvider("oidc.diary15m");
      var credential = providerBuilder.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      firebase_auth.UserCredential userCredential =
      await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장
      firebase_auth.User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLogin': DateTime.now().toIso8601String(),
        });
        print('사용자 정보 Firestore 저장 성공');
      }

      // 로그인 성공 후 화면 전환
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiaryListScreen(),
        ),
      );
    } catch (error) {
      print('로그인 실패: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $error')),
      );
    }
  }


}
