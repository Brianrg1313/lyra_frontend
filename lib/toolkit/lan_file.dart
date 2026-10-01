import 'dart:typed_data';

/// What `/f` answered: the HTTP status and the body (the file, or the refusal as JSON).
typedef LanFileResponse = ({int status, Uint8List body});

/// No address of the master answered a file request: the caller treats it as an unreachable
/// master, like a closed `/rpc`.
class LanFileUnreachable implements Exception {
  const LanFileUnreachable();

  @override
  String toString() => "LanFileUnreachable";
}
