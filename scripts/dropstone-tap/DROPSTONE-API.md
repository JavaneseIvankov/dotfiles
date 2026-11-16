# Dropstone CLI — remote & local API findings

Captured with `dropstone-tap` (mitmproxy wrapper) against Dropstone CLI `1.0.67`.
All host names, paths, headers and payload keys below are observed unless marked **(inferred)**.

## 1. Topology

| Host | Role | Observed traffic |
| --- | --- | --- |
| `api.dropstone.io` | control plane + model gateway (Express on Railway behind Cloudflare) | `/v1/chat/completions`, `/v1/jobs/:id`, `/account`, `/api/models/public`, `/api/memory/context`, `/api/skills/suggest`, `/api/share*`, `/api/remote/*`, `/api/auth/cli-token`, `/api/telemetry/*` |
| `dropstone.io` | web app / login page (`DROPSTONE_WEB_URL`) | `/login?callback=…` |
| `chat.dropstone.io` | share viewer + Dropstone Remote surface | share URLs `https://chat.dropstone.io/share/session/:id` |
| `registry.npmjs.org` | optional plugin lookup | `GET /@blankline%2fdropstone-plugin` (404 on this machine) |
| `127.0.0.1:<port>` | `dropstone serve` headless server | session/config/event REST + SSE |

Env overrides in the binary: `DROPSTONE_BASE_URL` (default `https://api.dropstone.io`), `DROPSTONE_WEB_URL` (default `https://dropstone.io`).

Every request carries `user-agent: dropstone/1.0.67` unless noted.

## 2. Auth

- Stored credential: `~/.local/share/dropstone-cli/auth.json` → `{ "dropstone": { "type": "api", "key": "<JWT>", "metadata": { "email": … } } }`.
- JWT claims: `{ id, email, name, imageUrl, provider: "github", iat, exp }` (HS256, 7-day lifetime).
- Wire format: `Authorization: Bearer <JWT>`.

Rejection shapes:

```json
401 {"error":"Access denied. Authentication token required.","authenticate":"Bearer realm=\"Dropstone Server\""}
403 {"error":"Invalid token format. Please log in again.","authenticate":"Bearer realm=\"Dropstone Server\", error=\"invalid_token\""}
```

Public endpoints need no auth: `GET /api/models/public`.

### Login (browser + PKCE)

1. CLI starts a loopback HTTP listener and opens `https://dropstone.io/login?callback=http%3A%2F%2F127.0.0.1%3A<port>%2F…` with `code_challenge_method=S256`.
2. Browser redirects back with `?code=…`; listener extracts `code`.
3. `POST https://api.dropstone.io/api/auth/cli-token` body `{"code":"…","code_verifier":"…"}` → token payload stored into `auth.json` **(response shape inferred: `{type:"api", key:…}`, same shape as the stored entry)**.

Failure telemetry: `event: cli_login_failed`, `stage` ∈ `network|expired|rejected`, `status` = HTTP status. Login timeout message: `Browser sign-in timed out — please try again`.

## 3. Model inference — `POST /v1/chat/completions`

OpenAI-shaped (it is the `@ai-sdk/openai-compatible` provider `dropstone`), but **asynchronous**: the POST returns quickly and the answer is fetched by polling a job.

Headers on every model call:

```
user-agent: dropstone/1.0.67
x-dropstone-client: cli
x-dropstone-surface: cli
x-dropstone-project: global        # constant in 1.0.67, even inside a git repo
x-dropstone-session: ses_<…>
x-dropstone-request: msg_<…>
```

Request body (top-level keys observed):

```json
{
  "model": "dropstone-fast",          // catalogue id, not the upstream id
  "max_tokens": 65536,
  "messages": [ { "role": "system", "content": "…" }, { "role": "user", "content": "…" } ],
  "tools": [ { "type": "function", "function": { "name": "bash", "parameters": { … } } } ],
  "tool_choice": "auto",
  "stream": true,
  "stream_options": { "include_usage": true },
  "background": true
}
```

Observations:
- `messages[].content` is either a plain string or an array of typed parts (`text`, …), i.e. AI-SDK `ModelMessage` semantics.
- Two POSTs per user turn in interactive mode: a tiny **title generator** call (system prompt `You are a title generator…`, ~3.3 KB, no tools) and the real agent call (system prompt ~58 KB, 27 tools, ~125 KB total).
- Tool names observed (27): `bash`, `read`, `glob`, … with JSON-Schema parameters, e.g. `bash{command,timeout,workdir,run_in_background,description}` required `[command,description]`, `read{filePath,offset,limit}`.
- Client model `dropstone-fast` is routed server-side to e.g. `dropstone/deepseek-v4.1-flash` (visible in the job).

### Job polling

`GET /v1/jobs/<uuid>` — same headers, one poll every **~0.6 s** (measured gaps 0.59 / 0.61 / 0.69 s, small jitter).

```json
{
  "id": "60e17522-102a-4772-87e5-c97aa4fb3c0d",
  "object": "dropstone.job",
  "status": "running",
  "model": "dropstone/deepseek-v4.1-flash",
  "reasoning": "",
  "content": "",
  "tool_calls": [],
  "finish_reason": null,
  "error": null, "error_code": null, "error_status": null, "retryable": false,
  "usage": { "prompt_tokens": null, "completion_tokens": null },
  "created": 1794025057,
  "finished": null
}
```

When done: `status:"done"`, populated `content` / `reasoning` / `tool_calls` / `finish_reason:"stop"`, `usage.prompt_tokens_details.cached_tokens`, `finished` timestamp.

Error shapes seen:

```json
404 {"error":"job_not_found","message":"Job not found"}
403 {"error":"Model not available","message":"The model \"nope-model\" is not available. Please use one of our curated models.","allowedModels":[ … ],"suggestions":…}
400 {"error":{"message":"Unexpected token '\"', \"\"not-json\"\" is not valid JSON","type":"entity.parse.failed"}}
```

`allowedModels` shows the upstream catalogue, e.g. `openai/gpt-5.2-codex`, `anthropic/claude-opus-4-6`, `google/gemini-3`, `moonshotai/kimi-k2.5`, `dropstone/deepseek-v4.1-flash-pro`, `dropstone/kimi-k3.1-pro`, `openai/text-embedding-3-small`.

### Catalogue — `GET /api/models/public` (no auth, gzip ~3.1 KB)

```json
{"models":{"dropstone-fast":{"id":"dropstone-fast","name":"Dropstone Fast 1.8","description":"…","provider":"dropstone","category":"free","credits":0,"tier":"free","group":"fast","versionLabel":"Fast 1.8","order":1,"isDefault":true,"contextWindow":1000000,"maxTokens":65536,"efficiency":"green","features":{"supportsImages":true,"supportsThinking":true,"maxTokens":65536}}}}
```

Known ids: `dropstone-fast`, `dropstone-pro`, `dropstone-heavy`, `dropstone-fast-1.7`, … (`category` free|budget, `tier` free|pro, `credits` 0/1/15).

## 4. Retrieval sidecars (called once per user turn)

```json
POST /api/memory/context  {"query":"<prompt text incl. mode reminder + date>"}
POST /api/skills/suggest  {"query":"<same>","surface":"cli"}
```

Both are non-blocking best-effort calls; response bodies are injected context (not modelled here).

## 5. Account — `GET /account`

```json
{"user":{"id":"…","email":"…","name":"…","userName":"…","imageUrl":"…","provider":"github","isActiveSubscription":false,"freeRequestsUsed":11,"freeRequestsLimit":50,"creditBalance":0,"improveDropstone":true}}
```

`improveDropstone` gates telemetry. `isActiveSubscription` gates Remote (see §7).

## 6. Session sharing

Enabled by `run --share` / `share` command.

```json
POST /api/share             {"sessionID":"ses_…","platform":"linux"}
201                         {"id":"<uuid>","url":"https://chat.dropstone.io/share/session/<uuid>","secret":"<48 chars>"}

POST /api/share/<uuid>/sync {"secret":"…","data":[{"type":"session","data":{ …session json… }}, {"type":"message","data":{…}}]}
200                         {"ok":true,"truncated":false}
```

`data[]` is a log of session/message upserts (the client re-syncs on every change; the earlier snapshot is replaced). `truncated` tells the client the batch was clipped.

## 7. Dropstone Remote

`dropstone remote <dir>` registers this machine so the session can be followed/steered from `chat.dropstone.io`.

```json
POST /api/remote/machines
{
  "machineName": "noir",
  "platform": "linux",
  "project": "gitproj",
  "models": {
    "current": {"providerID":"dropstone","modelID":"dropstone-fast"},
    "models": [ {"providerID":"dropstone","modelID":"dropstone-fast","name":"Dropstone Fast 1.8","variants":["low","medium","high","xhigh","max"]} ],
    "agents": [ {"name":"build","description":"…","color":"#06b6d4"}, … ],
    "currentAgent": "build"
  }
}

403 {"error":"Dropstone Remote is included with paid plans. Upgrade to Lite or above to use it.",
     "code":"plan_required","feature":"remote","plan":"free","upgradeTo":"lite",
     "upgradeUrl":"https://www.dropstone.io/pricing/lite"}
```

Other strings in the binary show the runtime channel: remote sessions can be started/stopped from the web (`Remote was turned off from chat.dropstone.io`), consent stored under `remote_consent`, and attachments arriving from the web are injected into the prompt as `[Attached from chat.dropstone.io: name (path)]`.

## 8. Telemetry

Four endpoints, all fire-and-forget with short aborts (4–5 s):

| Endpoint | Auth | Purpose |
| --- | --- | --- |
| `POST /api/telemetry/cli` | none | CLI lifecycle events |
| `POST /api/telemetry/consent` | Bearer | consent toggles |
| `POST /api/telemetry/outcome` | Bearer | task outcome |
| `POST /api/telemetry/trajectory` | Bearer | run trajectory |

`/api/telemetry/cli` body keys observed in the bundle: `platform`, `arch`, `runtime` (`bun 1.x` / `node vX`), `command` (truncated to 32 chars), plus event-specific fields:

- `cli_started`, `cli_first_run` (`attempt_id` uuid, `method`)
- `cli_crashed` (error info + `expected`)
- `cli_login_failed` (`stage`, `status`)

No telemetry POST was observed in normal `run` invocations with `improveDropstone: true`; the calls appear tied to TUI lifecycle, not one-shot `run`.

## 9. Local server — `dropstone serve`

Defaults: `--port 0` (random), `--hostname 127.0.0.1`, flags `--print-logs --log-level --pure --mdns --mdns-domain --cors`. **There is no auth/password flag** in 1.0.67 — the server is loopback-only and unauthenticated.

Endpoints observed:

| Method | Path | Note |
| --- | --- | --- |
| GET | `/config` | provider/config snapshot |
| GET | `/path` | `{home,state,config,worktree,directory}` |
| GET | `/project` | `[{id:"global",worktree,time,sandboxes:[]}]` |
| GET/POST | `/session` | list / create (`{title}`; returns full session object) |
| GET/DELETE | `/session/:id` | fetch / delete (`true`) |
| POST | `/session/:id/message` | body must contain `parts: []` |
| GET | `/event` | SSE stream, per-directory |
| GET | `/global/event` | SSE stream, all directories |

The client scopes a request to a working directory with `x-dropstone-directory: /abs/path` (optional; falls back to server cwd). Session objects carry `id` (`ses_<…>`), `slug`, `projectID`, `directory`, `path`, `title`, `version`, `permission[]`, `time{created,updated}`.

SSE framing differs between the two streams:

```
GET /event         data: {"id":"evt_…","type":"server.connected","properties":{}}
GET /global/event  data: {"payload":{"id":"evt_…","type":"server.connected","properties":{}}}
```

Errors:

```json
400 {"data":{},"error":[{"expected":"array","code":"invalid_type","path":["parts"],"message":"Invalid input: expected array, received undefined"}],"success":false}
503 {"error":"Web UI is not available in this build of Dropstone CLI"}          // any unregistered route
```

## 10. Cross-cutting conventions

- **Two error dialects.** App-level: flat `{"error":"<machine code>","message":"<human>", extra fields…}` (`job_not_found`, `Model not available`, `plan_required`). Framework-level: Express body-parser `{"error":{"message","type":"entity.parse.failed"}}` for malformed JSON, and zod `{data,error[],success:false}` on the local server.
- **Rate limiting.** `ratelimit-remaining` header on every `api.dropstone.io` response, ceiling 20000, reset window ≈ 900 s. Exceeding it is a 429 **(inferred from header semantics)**.
- **Request tracing.** `x-railway-request-id` per response, `x-dropstone-request` (`msg_<…>`) per model call, `x-dropstone-session` (`ses_<…>`) per session — client-side correlation, echoed back by the server logs.
- **ID prefixes.** `ses_` session, `evt_` event, `msg_` message, `prt_` part, bare uuid `job` / share id.
- **Client metadata headers** (used by the CLI when talking to its own server or to the gateway so the server can attribute surface): `x-dropstone-client`, `x-dropstone-surface`, `x-dropstone-project`.
- **Plugin lookup.** On start the CLI asks npm for `@blankline/dropstone-plugin` (`pacote` packument request, `npm-auth-type: web`, `user-agent: npm/undefined node/v26.3.0 linux x64`); 404 is normal and non-fatal.
- **Token accounting.** Usage is server-side only; the CLI reads `usage.prompt_tokens_details.cached_tokens` from the job and mirrors it into local message metadata (`tokens.cache.read`).
- **No WebSockets observed.** All remote interaction is REST + SSE; the mitm proxy saw no WS upgrade on `api.dropstone.io`.

## 11. On-disk layout (for reference)

```
~/.local/share/dropstone-cli/auth.json        credentials
~/.local/state/dropstone-cli/                 state (sessions, messages, snapshots)
~/.config/dropstone-cli/                      config
~/.dropstone/bin/dropstone                    binary (Bun single-file executable)
```

Session JSON stored locally (and shipped to `/api/share/…/sync`) looks like:

```json
{"id":"ses_…","slug":"tidy-forest","projectID":"global","directory":"/tmp/opencode","path":"tmp/opencode","title":"Reply with ok","agent":"build","version":"1.0.67","summary":{"additions":0,"deletions":0,"files":0},"permission":[{"permission":"question","pattern":"*","action":"deny"}],"time":{"created":…,"updated":…}}
```

Message records separate `info` (role/model/usage/cost) from `parts[]` (`text`, `step-start`, `step-finish`, `tool_*`).

## 12. How this was captured, and known gaps

`dropstone-tap` runs the CLI under a loopback mitmproxy (`HTTPS_PROXY` + `NODE_EXTRA_CA_CERTS`), so every HTTPS request, header and body lands in `<run>/flows.jsonl`.

Gaps:

- `POST /api/auth/cli-token` response body — requires completing a real browser login (never run here).
- `/api/telemetry/outcome` and `/api/telemetry/trajectory` payloads — only fire on TUI session end.
- `chat.dropstone.io` web-app API (share viewer, Remote control channel) — not enumerated; would need a browser session.
- WebSocket frames would be invisible to the proxy (none seen here).
- `usage`/billing semantics beyond request counts (`freeRequestsUsed/50`) are not exposed by the API.
