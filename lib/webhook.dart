import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:ndk/ndk.dart' hide Logger;

final _log = Logger('webhook');

/// POSTs [event] as a standard NIP-01 JSON object to [url].
/// Logs the result; never throws.
Future<void> forwardToWebhook(String url, Nip01Event event) async {
  final body = Nip01EventModel.fromEntity(event).toJsonString();
  try {
    final res = await http.post(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      _log.info('webhook ${res.statusCode} for ${event.id}');
    } else {
      _log.warning('webhook ${res.statusCode} for ${event.id}: ${res.body}');
    }
  } catch (e, st) {
    _log.severe('webhook error for ${event.id}', e, st);
  }
}
