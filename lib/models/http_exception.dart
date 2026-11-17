/// An error returned by Firebase, with a message a person can read.
class HttpException implements Exception {
  HttpException(this.message);

  final String message;

  /// Turns Firebase Auth error codes into friendly messages.
  factory HttpException.fromAuthCode(String code) {
    final message = switch (code) {
      'EMAIL_EXISTS' => 'This email address is already registered.',
      'INVALID_EMAIL' => 'This is not a valid email address.',
      'WEAK_PASSWORD' ||
      'WEAK_PASSWORD : Password should be at least 6 characters' =>
        'This password is too weak. Use at least 6 characters.',
      'EMAIL_NOT_FOUND' ||
      'INVALID_PASSWORD' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        'Wrong email or password.',
      'USER_DISABLED' => 'This account has been disabled.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' =>
        'Too many attempts. Please wait a moment and try again.',
      _ => 'Authentication failed. Please try again.',
    };
    return HttpException(message);
  }

  @override
  String toString() => message;
}
