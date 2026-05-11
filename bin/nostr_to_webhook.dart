import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:ndk/ndk.dart' hide Logger;
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:nostr_to_webhook/dm_relays.dart';
import 'package:nostr_to_webhook/webhook.dart';

final _log = Logger('nostr_to_webhook');

void main(List<String> arguments) async {
  _setupLogging();

  final env = DotEnv(includePlatformEnvironment: true)..load();

  final nsec = env['NSEC'];
  final webhookUrl = env['WEBHOOK_URL'];

  if (nsec == null || nsec.isEmpty) {
    _log.severe('Missing NSEC in .env');
    exit(1);
  }
  if (webhookUrl == null || webhookUrl.isEmpty) {
    _log.severe('Missing WEBHOOK_URL in .env');
    exit(1);
  }

  _log.info('WEBHOOK_URL: $webhookUrl');

  final ndk = Ndk(
    NdkConfig(eventVerifier: Bip340EventVerifier(), cache: MemCacheManager()),
  );

  final privkey = Nip19.decode(nsec);
  final pubkey = Bip340.getPublicKey(privkey);

  ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privkey);
  _log.info('Logged in as ${Nip19.encodePubKey(pubkey)}');

  final dmRelays = await fetchDmRelays(ndk, pubkey);

  if (dmRelays.isEmpty) {
    _log.severe('No DM relay list (kind 10050) found for this account.');
    await ndk.destroy();
    exit(1);
  }

  _log.info('DM relays: ${dmRelays.join(', ')}');

  final sub = ndk.requests.subscription(
    filter: Filter(kinds: [1059], pTags: [pubkey], limit: 0),
    explicitRelays: dmRelays,
  );
  _log.info('Listening for gift wraps… (Ctrl+C to stop)');

  ProcessSignal.sigint.watch().listen((_) async {
    _log.info('Stopping…');
    await ndk.destroy();
    exit(0);
  });

  await for (final event in sub.stream) {
    _log.info('gift wrap received: ${event.id}');
    await forwardToWebhook(webhookUrl, event);
  }
}

void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    final ts = r.time.toUtc().toIso8601String();
    final out = r.level >= Level.SEVERE ? stderr : stdout;
    out.writeln('$ts [${r.level.name}] ${r.loggerName}: ${r.message}');
    if (r.error != null) out.writeln('  error: ${r.error}');
    if (r.stackTrace != null) out.writeln(r.stackTrace);
  });
}
