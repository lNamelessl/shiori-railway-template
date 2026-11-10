# syntax=docker/dockerfile:1

# Upstream official image (scratch runtime) — digest-pinned. Only the binary
# and its path are used: /usr/bin/shiori.
FROM ghcr.io/go-shiori/shiori:v1.8.0@sha256:d3bdfc1b68b8f267a04cf74d73b8a0e1d99ac71c3a9047375e97202f079eb1f6 AS upstream

# Wrapper runtime: alpine gives us a shell (railway ssh debuggability) plus
# sqlite3 and htpasswd for the first-boot credential seed. Runs as root, so
# Railway's root-owned volume mount needs no chown dance.
FROM alpine:3.21@sha256:bc21487101ae47172509130ee1092cc273a831968d64b617776d1f69c81e42ab

RUN apk add --no-cache ca-certificates tzdata sqlite apache2-utils

COPY --from=upstream /usr/bin/shiori /usr/bin/shiori

ENV SHIORI_DIR=/data
ENV PORT=8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
