# nostr_to_webhook

Listens for [NIP-17](https://github.com/nostr-protocol/nips/blob/master/17.md)
gift wrap events (kind `1059`) addressed to a Nostr account and forwards each
one as a JSON POST to a webhook.

## Configuration

Copy `.env.example` to `.env` and fill in:

```env
NSEC=nsec1...
WEBHOOK_URL=https://example.com/webhook
```

## Run with Docker Compose

```sh
docker compose up -d
docker compose logs -f
```

`compose.yaml` pulls `ghcr.io/nogringo/nostr-to-webhook:latest`. To build
locally instead, uncomment `build: .` and comment out the `image:` line.
