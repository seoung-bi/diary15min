import 'package:diary15min/screen/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase가 이미 초기화된 상태에서 다시 초기화하지 않도록 처리
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase 이미 초기화됨: $e");
  }

  await initializeDateFormatting();

  KakaoSdk.init(
    nativeAppKey: '',
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LogScreen(),  // 앱 실행 시 로그인 화면을 첫 화면으로 설정
    ),
  );
}