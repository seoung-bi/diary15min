import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../component/diary_list.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Image.asset(
                  'assets/img/logo.jpg',
                ),
              ),
            ),
            const SizedBox(height: 50.0),
            GestureDetector(
              onTap: () => googleOnLoginPress(context),
              child: Image.asset(
                'assets/img/google.png',
                height: 50.0, // 버튼 높이 조정
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10.0),
            GestureDetector(
              onTap: () => kakaoOnLoginPress(context),
              child: Image.asset(
                'assets/img/kakao.png',
                height: 50.0, // 버튼 높이 조정
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 구글 로그인 처리
  googleOnLoginPress(BuildContext context) async {
    GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
    try {
      GoogleSignInAccount? account = await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await account?.authentication;

      if (googleAuth == null) {
        // 사용자 인증이 취소되면
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 취소')));
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiaryListScreen(),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: $error')),
      );
    }
  }

  // 카카오 로그인 처리
  Future<void> kakaoOnLoginPress(BuildContext context) async {
    late List<String> hosts;  // hosts 변수 선언

    try {
      // hosts 초기화 예시
      hosts = ['example.com', 'anotherexample.com'];  // 실제 필요한 값으로 초기화

      // 토큰이 있을 경우, 유효성 체크
      if (await AuthApi.instance.hasToken()) {
        try {
          AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          print('토큰 유효성 체크 성공 ${tokenInfo.id} ${tokenInfo.expiresIn}');
        } catch (error) {
          if (error is KakaoException) {
            if (error.isInvalidTokenError()) {
              print('토큰 만료 $error');
            } else {
              print('카카오 토큰 정보 조회 실패: ${error.message}');
            }
          } else {
            print('알 수 없는 오류 $error');
          }
        }
      } else {
        print('발급된 토큰 없음');
      }

      // 카카오 계정으로 로그인
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      print('로그인 성공 ${token.accessToken}');

      // Firebase 인증 처리
      try {
        var providerBuilder = OAuthProvider("oidc.diary15m");
        var credential = providerBuilder.credential(
          idToken: token.idToken,
          accessToken: token.accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        print('Firebase 인증 성공');
      } catch (error) {
        print('Firebase 인증 실패: $error');
        throw error; // Firebase 인증 실패 시 예외 던짐
      }

      // 로그인 성공 후 DiaryListScreen으로 이동
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
