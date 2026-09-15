class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => cause != null ? '$message: $cause' : message;
}

class DiscoveryException extends AppException {
  const DiscoveryException(super.message, [super.cause]);
}

class ConnectionException extends AppException {
  const ConnectionException(super.message, [super.cause]);
}

class HandshakeException extends AppException {
  const HandshakeException(super.message, [super.cause]);
}

class FramingException extends AppException {
  const FramingException(super.message, [super.cause]);
}

class TransferException extends AppException {
  const TransferException(super.message, [super.cause]);
}

class ChecksumException extends AppException {
  const ChecksumException(super.message, [super.cause]);
}

class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}
