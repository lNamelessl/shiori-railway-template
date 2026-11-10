# Shiori — Railway Template

[Shiori](https://github.com/go-shiori/shiori) is a self-hosted bookmark manager with a clean web UI, full-text search, and automatic offline page archiving: every bookmark keeps a readable copy of the page, so your library survives link rot. Single Go binary, embedded SQLite.

This repo is a one-click [Railway](https://railway.com) template: **one service + one volume, zero required variables, zero deploy prompts.**

## Deploy

Click the button, wait for the healthcheck-gated deploy to go green, and open the generated domain.

## First login (important)

Shiori upstream documents a world-known default account (`shiori` / `gopher`). This template **neutralizes it before the server ever accepts a request**: on first boot the wrapper replaces the default account's password with a per-deploy random one and writes the credentials into the volume:

```bash
railway ssh -- cat /data/default-creds.txt
```

(Or run the same command via the Railway dashboard's connected terminal.)

1. Log in with the username `shiori` and the generated password.
2. Change the password in the web UI (account menu).
3. Delete `/data/default-creds.txt`.

The seed is marker-guarded: it runs exactly once and never re-fires on restarts, redeploys, or after you change the password.

## What you get

- **Offline archives** — adding a bookmark downloads the page and stores a single-file copy (`/data/archive/<id>`); read it even when the original page dies.
- **Full-text search** — SQLite FTS over titles and content.
- **Browser extensions** — Firefox/Chrome extensions speak the API directly.
- **Import/export** — Netscape bookmark HTML and Pocket imports; JSON export.
- **Persistence** — everything lives on the `/data` volume: `shiori.db` (+ WAL), `archive/`, `thumb/`, `ebook/`. To back up, copy the volume (or the whole `/data` tree).
- **Sessions survive restarts** — a random session-signing secret is generated once, persisted, and reused on every boot (upstream would invalidate all logins on restart without this).

## Sizing

Measured idle RSS is roughly 50–80 MB; archives are a few hundred KB per page. The template provisions a 5 GB volume (about ten thousand typical archived pages); resize in the Railway dashboard if you archive heavily. No healthcheck-dependent tuning needed — the deploy probes `GET /system/liveness` (unauthenticated, dotless).

## Optional configuration

Zero variables are required. After deploy you can add Shiori's native environment variables to the service (prefix `SHIORI_`), e.g.:

| Variable | Meaning |
|---|---|
| `SHIORI_HTTP_ACCESS_LOG` | request access logging (on by default in v1.8.0) |
| `SHIORI_DATABASE_URL` | use MySQL/Postgres instead of the embedded SQLite (the credential seed then skips itself; manage accounts via the CLI) |
| `SHIORI_HTTP_ROOT_PATH` | serve under a subpath behind a custom reverse proxy |

Full list: [upstream configuration docs](https://github.com/go-shiori/shiori/blob/v1.8.0/docs/Configuration.md).

## Versions and pins

- Upstream: [go-shiori/shiori v1.8.0](https://github.com/go-shiori/shiori/releases/tag/v1.8.0) (2025-09-26) — MIT.
- Image: `ghcr.io/go-shiori/shiori:v1.8.0` pinned to digest `sha256:d3bdfc1b68b8f267a04cf74d73b8a0e1d99ac71c3a9047375e97202f079eb1f6`.
- Wrapper base: `alpine:3.21` pinned to digest `sha256:bc21487101ae47172509130ee1092cc273a831968d64b617776d1f69c81e42ab` (adds a shell for `railway ssh`, plus `sqlite3`/`htpasswd` used only by the one-time seed).

The official upstream image is `FROM scratch` (no shell); this wrapper keeps the exact upstream binary and adds the seed step. Other Railway Shiori templates exist (by Brody's Projects, Tom, A3A, and Anton Orel) — this one's difference: single-service SQLite (no Postgres), zero deploy prompts, digest pins, and per-deploy credentials that replace the upstream default before first serve.

## License

MIT (template wrapper). Shiori itself is MIT, (c) the go-shiori authors.
