class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed. Please log in again.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Unable to reach the server. Please try again.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Invalid data provided.']);
}

class SubscriptionException extends AppException {
  const SubscriptionException([super.message = 'This feature requires a premium subscription.']);
}

class QuotaException extends AppException {
  const QuotaException([super.message = 'Free tier limit reached. Upgrade to premium.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Content not found.']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'File upload failed.']);
}
