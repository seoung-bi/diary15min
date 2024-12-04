import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 SDK import

class ProfileService_ka {
  Future<String?> getKakaoNickname() async {
    try {
      User kauser = await UserApi.instance.me();
      return kauser.kakaoAccount?.profile?.nickname;
    } catch (error) {
      print('사용자 정보 요청 실패 $error');
      return null;
    }
  }
}