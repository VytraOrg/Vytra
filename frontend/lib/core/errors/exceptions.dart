class AppError implements Exception {
  final String message;
  final int? statusCode;

  AppError(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  NetworkError() : super("No internet connection or server unreachable.");
}

class AuthError extends AppError {
  AuthError(String message) : super(message, statusCode: 401);
}

class ServerError extends AppError {
  ServerError({int? statusCode}) : super("Server error occurred. Please try again later.", statusCode: statusCode);
}
