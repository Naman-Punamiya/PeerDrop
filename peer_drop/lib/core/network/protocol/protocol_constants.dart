import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProtocolConstants {
  const ProtocolConstants._();

  static int get defaultUdpPort => int.parse(dotenv.env['UDP_PORT']!);
  static int get defaultTcpPort => int.parse(dotenv.env['TCP_PORT']!);

  static const String discover = 'discover';
  static const String discoverResponse = 'discover_response';

  static const String hello = 'hello';
  static const String helloAck = 'hello_ack';

  static const String transferRequest = 'transfer_request';
  static const String transferAccept = 'transfer_accept';
  static const String transferReject = 'transfer_reject';
  static const String transferComplete = 'transfer_complete';
}
