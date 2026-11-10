Shiori is a self-hosted bookmark manager written in Go: a single binary with an embedded SQLite database, a clean web UI, full-text search, browser extensions, and — the reason people pick it — automatic offline archiving. Every bookmark you save gets a readable single-file copy of the page stored on your volume, so your library survives link rot and read-later service shutdowns.

This template deploys Shiori v1.8.0 (the current upstream release) as **one Railway service with one persistent volume and zero required variables — zero prompts at deploy time.** The official upstream image is digest-pinned, and a thin Alpine wrapper adds a one-time first-boot credential seed plus a shell for `railway ssh` debugging.

Deploy with one click:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/shiori-railway-template)

**First login:** upstream ships a world-known default account (`shiori` / `gopher`). This template neutralizes that before the server ever accepts a request — on first boot the wrapper replaces the default account's password with a per-deploy random one and writes it to `default-creds.txt` in your volume. Read it with `railway ssh -- cat /data/default-creds.txt` (or the dashboard terminal), log in, change the password in the web UI, then delete the file. The seed runs exactly once (marker-guarded) and never re-fires after restarts, redeploys, or a password change.

# Deploy and Host

Deploying provisions one service (Shiori v1.8.0, official image pinned by digest) with one 5 GB volume mounted at `/data` holding the SQLite database, offline page archives, thumbnails, and ebooks. Deploys are healthcheck-gated on `GET /system/liveness` (unauthenticated, dotless) and restart on failure. There are no required variables and no deploy-form prompts; sessions survive restarts because the wrapper generates and persists a session-signing secret on first boot. On Railway's shared vCPU the service idles around 50–80 MB of RAM — the smallest footprint in this template family.

## About Hosting

Shiori keeps everything in `/data`: `shiori.db` (SQLite with WAL), `archive/` (one file per archived page), `thumb/`, and `ebook/`. The embedded database means there is no second service, no database credentials, and nothing to configure — the entire template is the app plus its volume. Search, tagging, and the readable archive viewer all work out of the box, and the REST API is compatible with the official Firefox and Chrome browser extensions. Backups are as simple as copying the `/data` tree. Optional post-deploy variables from upstream's documented list (`SHIORI_DATABASE_URL` for MySQL/Postgres, `SHIORI_HTTP_ACCESS_LOG`, `SHIORI_HTTP_ROOT_PATH`) can be added later without touching the template.

## Why Deploy

Compared with running the upstream Docker image yourself on Railway: the upstream image is built `FROM scratch` — no shell, so `railway ssh` is useless and there is nowhere to run first-boot logic. This template's wrapper keeps the exact upstream binary (pinned by digest, `sha256:d3bdfc1b…` on Alpine 3.21, itself digest-pinned) and adds: (1) the one-time credential seed described above, so the publicly documented `gopher` password is never servable; (2) a persisted session secret so logins survive restarts (upstream regenerates the key every boot and logs everyone out); (3) a real healthcheck route; (4) a shell for debugging. For context on the marketplace: four other Shiori templates exist at publish time — Brody's Projects (9 deploys, requires a Postgres service), A3A (1 deploy, two services), Anton Orel (1 deploy) and Tom (0 deploys) — this one differentiates on single-service SQLite, zero prompts, digest pins, and the pre-serve credential neutralization.

## Common Use Cases

- Replace Pocket, Instapaper, or Raindrop with a private, self-owned reading list whose pages stay readable even when the source dies.
- Research and reference clipping: save, tag, and full-text-search pages; import existing bookmarks via Netscape HTML or Pocket export.
- Team/agency link libraries behind a private Railway URL with per-deploy credentials.
- Long-term archiving of documentation you depend on, with the volume as a single backupable unit.

## Dependencies for

None — the template is self-contained: one service, one volume, embedded SQLite.

### Deployment Dependencies

- A Railway account (Hobby plan or higher) — the deploy provisions the service, volume, and a public domain automatically.
- No databases, no variables, no external services required.
- Optional: the official Shiori browser extensions (Firefox/Chrome) can point at your deployment's REST API after first login.
