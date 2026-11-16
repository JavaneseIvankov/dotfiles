# dropstone-tap

Wraps the Dropstone CLI in a local MITM proxy so every HTTP(S) request it makes
is logged: method, URL, headers, request payload, status, response headers and
body (gzip/br decoded, SSE bodies included).

## Use

```bash
dropstone-tap run -m dropstone/dropstone-fast "why is my build slow"
dropstone-tap            # normal TUI, fully proxied
dropstone-tap --redact run "..."                # mask Authorization/cookie/api-key values
dropstone-tap --hosts api.dropstone.io run "..."   # only log that host
dropstone-tap --filter '/v1/' run "..."            # only log matching URLs
dropstone-tap -o ./capture run "..."               # explicit output dir
```

Every run writes to `~/.dropstone-tap/runs/<timestamp>/`:

| file | content |
|---|---|
| `flows.jsonl` | one JSON line per request / response / error event |
| `bodies/` | raw bodies that are not textual (binary, images) |
| `summary.txt` | `id status METHOD URL (bytes)` list |
| `mitm.log` | proxy stderr |

## Inspect

```bash
dropstone-tap-show                      # newest run, pretty
dropstone-tap-show ~/.dropstone-tap/runs/20261107-041736
dropstone-tap-show -i 5                 # one flow, full detail
dropstone-tap-show --url '/v1/chat' -b 9000
dropstone-tap-show -H                   # headers only
jq -c 'select(.event=="request") | {id,method,url}' flows.jsonl
```

## How it works

1. Starts `mitmdump` on a random loopback port with `tap_addon.py`.
2. Exports `HTTPS_PROXY`/`HTTP_PROXY`/`ALL_PROXY` (Dropstone is a Bun binary and
   honours them) plus `NODE_EXTRA_CA_CERTS`/`SSL_CERT_FILE` so the generated
   mitmproxy CA is trusted by Dropstone and every child process (npm, LSP, MCP).
3. `NO_PROXY` keeps loopback traffic (its own server, `dropstone serve`) direct.
4. Runs Dropstone in the foreground, forwards the exit code, stops the proxy,
   writes the summary.

CA lives in `~/.dropstone-tap/mitm/mitmproxy-ca-cert.pem`. Delete that dir to
regenerate. Nothing system-wide is installed and no trust store is modified —
the CA is only injected into the wrapped process environment.

## Notes

- Logs contain real credentials (Bearer tokens, prompts). Run dirs are created
  with `umask 077` (600 files). Use `--redact` when sharing.
- Certificate pinning would break MITM. Dropstone does not pin today; if a
  future version does, nothing here can decrypt it without patching the binary.
- WebSocket frames are tunnelled and not logged (HTTP requests to the same host
  still are).
- `--max-body N` caps captured bytes per body (default 1 MiB); larger bodies are
  truncated and flagged with `body_truncated`.

## Requirements

`mitmdump` (`uv tool install mitmproxy`) — already installed at
`~/.local/bin/mitmdump`. Falls back to `uvx --from mitmproxy` if missing.
