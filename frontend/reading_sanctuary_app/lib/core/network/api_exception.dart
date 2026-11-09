class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  final dynamic details;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode, errorCode: $errorCode): $message';
}

class BadRequestException extends ApiException {
  const BadRequestException(String message, {String? errorCode, dynamic details})
      : super(message: message, statusCode: 400, errorCode: errorCode, details: details);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Authentication required or session expired'])
      : super(message: message, statusCode: 401, errorCode: 'UNAUTHORIZED');
}

class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Access denied'])
      : super(message: message, statusCode: 403, errorCode: 'FORBIDDEN');
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message: message, statusCode: 404, errorCode: 'NOT_FOUND');
}

class ConflictException extends ApiException {
  const ConflictException(String message, {String? errorCode, dynamic details})
      : super(message: message, statusCode: 409, errorCode: errorCode ?? 'CONFLICT', details: details);
}

class PayloadTooLargeException extends ApiException {
  const PayloadTooLargeException([String message = 'File or payload too large'])
      : super(message: message, statusCode: 413, errorCode: 'PAYLOAD_TOO_LARGE');
}

class RateLimitedException extends ApiException {
  const RateLimitedException([String message = 'Too many requests. Please try again later.'])
      : super(message: message, statusCode: 429, errorCode: 'RATE_LIMITED');
}

class ServerException extends ApiException {
  const ServerException([String message = 'Internal server error. Please try again later.'])
      : super(message: message, statusCode: 500, errorCode: 'SERVER_ERROR');
}

class NetworkException extends ApiException {
  const NetworkException([String message = 'Network connection failed. Please check your internet connection.'])
      : super(message: message, statusCode: 0, errorCode: 'NETWORK_ERROR');
}
