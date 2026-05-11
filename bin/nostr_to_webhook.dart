import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:nostr_to_webhook/dm_relays.dart';

void main(List<String> arguments) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final nsec = env['NSEC'];
  final webhookUrl = env['WEBHOOK_URL'];

  if (nsec == null || nsec.isEmpty) {
    stderr.writeln('Missing NSEC in .env');
    exit(1);
  }
  if (webhookUrl == null || webhookUrl.isEmpty) {
    stderr.writeln('Missing WEBHOOK_URL in .env');
    exit(1);
  }

  print('WEBHOOK_URL: $webhookUrl');

  final ndk = Ndk(
    NdkConfig(eventVerifier: Bip340EventVerifier(), cache: MemCacheManager()),
  );

  final privkey = Nip19.decode(nsec);
  final pubkey = Bip340.getPublicKey(privkey);

  ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privkey);
  print('Logged in as ${Nip19.encodePubKey(pubkey)}');

  final dmRelays = await fetchDmRelays(ndk, pubkey);

  if (dmRelays.isEmpty) {
    stderr.writeln('No DM relay list (kind 10050) found for this account.');
    await ndk.destroy();
    exit(1);
  }

  print('DM relays:');
  for (final r in dmRelays) {
    print('  - $r');
  }

  await ndk.destroy();
}
