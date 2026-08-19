class NetworkException implements Exception {
  final String errorMessage;
  final dynamic underlyingCause;

  const NetworkException(this.errorMessage, [this.underlyingCause]);

  @override
  String toString() {
    if (underlyingCause != null) {
      return 'NetworkException: $errorMessage (Cause: $underlyingCause)';
    }
    return 'NetworkException: $errorMessage';
  }
}

class DiscoveryException extends NetworkException {
  const DiscoveryException(super.errorMessage, [super.underlyingCause]);

  @override
  String toString() {
    if (underlyingCause != null) {
      return 'DiscoveryException: $errorMessage (Cause: $underlyingCause)';
    }
    return 'DiscoveryException: $errorMessage';
  }
}

class ConnectionException extends NetworkException {
  const ConnectionException(super.errorMessage, [super.underlyingCause]);

  @override
  String toString() {
    if (underlyingCause != null) {
      return 'ConnectionException: $errorMessage (Cause: $underlyingCause)';
    }
    return 'ConnectionException: $errorMessage';
  }
}

class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException(super.errorMessage, [super.underlyingCause]);

  @override
  String toString() {
    if (underlyingCause != null) {
      return 'NetworkTimeoutException: $errorMessage (Cause: $underlyingCause)';
    }
    return 'NetworkTimeoutException: $errorMessage';
  }
}
