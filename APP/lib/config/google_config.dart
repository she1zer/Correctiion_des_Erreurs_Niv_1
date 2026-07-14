/// Configuration Google OAuth pour Gmail (ISITEK — projet appisitek).
class GoogleConfig {
  GoogleConfig._();

  static const String projectId = 'appisitek';

  /// Client OAuth Android — com.isitek.app
  static const String androidClientId =
      '836819597580-c537hvi362f0igkps035m6rtc1b2rish.apps.googleusercontent.com';

  /// Client OAuth Web — serverClientId requis pour Gmail API sur Android.
  static const String webClientId =
      '836819597580-e9c0h1anr51t4ecprl01vbr8lguj5sdh.apps.googleusercontent.com';

  static const String gmailReadonlyScope =
      'https://www.googleapis.com/auth/gmail.readonly';
}
