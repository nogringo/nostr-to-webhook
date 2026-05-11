import 'package:ndk/ndk.dart';

/// Fetches the NIP-17 DM relay list (kind 10050) for [pubkey] and returns the
/// `relay` tag values from the most recent event. The query is run against the
/// user's NIP-65 write relays (outbox), which is where the kind 10050 event is
/// expected to have been published. Returns an empty list when no kind 10050
/// event is found.
Future<List<String>> fetchDmRelays(Ndk ndk, String pubkey) async {
  final userRelayList = await ndk.userRelayLists.getSingleUserRelayList(pubkey);
  final writeRelays = userRelayList?.relays.entries
          .where((e) => e.value.isWrite)
          .map((e) => e.key)
          .toList() ??
      const <String>[];
  if (writeRelays.isEmpty) return const <String>[];

  final response = ndk.requests.query(
    filter: Filter(kinds: [10050], authors: [pubkey], limit: 1),
    explicitRelays: writeRelays,
  );
  final events = await response.future;
  if (events.isEmpty) return const <String>[];
  events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return events.first.getTags('relay');
}
