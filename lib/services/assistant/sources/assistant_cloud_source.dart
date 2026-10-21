// SERVICES
import 'package:app/toolkit/api.dart';
import '../assistant_line.dart';
import './assistant_source.dart';

/// The panel's assistant on the cloud (`/lyra/v1/harness/assistant`), with
/// the person's own session: what they may not do, it cannot do either.
class AssistantCloudSource implements AssistantSource {
  const AssistantCloudSource();

  /// A run stops at 180 s on the server; the answer is waited for a little
  /// longer than that, never the api's ten seconds.
  static const Duration _answer = Duration(seconds: 200);

  static const String _path = "/harness/assistant/";

  @override
  Future<AssistantBatch> read() async =>
    AssistantBatch.fromJson(await api.get(path: _path, version: "v1"));

  @override
  Future<AssistantBatch> send(String message) async => AssistantBatch.fromJson(
    await api.post(path: _path, version: "v1", data: {"MESSAGE": message}, timeout: _answer)
  );

  @override
  Future<AssistantBatch> confirm(String id, {required bool yes}) async => AssistantBatch.fromJson(
    await api.post(path: "${_path}confirm/", version: "v1", data: {"ID": id, "ANSWER": yes ? "yes" : "no"})
  );

  @override
  Future<void> close() => api.delete(path: _path, version: "v1");
}
