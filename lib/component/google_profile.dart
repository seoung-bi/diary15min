import 'package:firebase_auth/firebase_auth.dart';

class ProfileService_go {
  // 구글 프로필 정보 가져오는 메소드
  Future<Map<String, String?>> getGoogleProfile() async {
    Map<String, String?> googleProfile = {};

    try {
      // FirebaseAuth에서 로그인된 사용자의 정보 가져오기
      User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        for (final providerProfile in firebaseUser.providerData) {
          // 구글 프로바이더인 경우 처리
          if (providerProfile.providerId == 'google.com') {
            final name = providerProfile.displayName; // 사용자 이름
            final emailAddress = providerProfile.email; // 이메일

            // 구글 계정의 프로필 정보 저장
            googleProfile['googleName'] = name;
            googleProfile['googleEmail'] = emailAddress;
          }
        }
      } else {
        print('구글 사용자 정보가 없습니다.');
      }
    } catch (error) {
      print('구글 프로필 정보 요청 실패: $error');
    }

    return googleProfile;  // 구글 프로필 정보를 포함하는 Map 반환
  }
}
