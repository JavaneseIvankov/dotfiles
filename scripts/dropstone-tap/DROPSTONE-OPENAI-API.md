# Dropstone OpenAI-compatible endpoint — request conventions

Captured live against `dropstone` CLI **1.0.67** (2026-11-07, free-tier account). All statements below are observed behaviour, not vendor docs.

---

## 1. Base URL

```
https://api.dropstone.io
```

| Env var | Default | Used for |
|---|---|---|
| `DROPSTONE_BASE_URL` | `https://api.dropstone.io` | API: chat, jobs, account, share, remote |
| `DROPSTONE_WEB_URL` | `https://dropstone.io` | browser login page (`/login?callback=…`) |

`chat.dropstone.io` (share/remote web UI) is a hardcoded constant, not configurable by env. Edge = Cloudflare in front of Railway-hosted Express; every response carries `server: cloudflare`, `x-railway-request-id`, `ratelimit-remaining` (≈20000 / 900 s window).

---

## 2. Auth

```
authorization: Bearer <jwt>
```

JWT obtained via `POST /api/auth/cli-token {code, code_verifier}` (PKCE S256 browser handoff), stored at `~/.local/share/dropstone-cli/auth.json` → `dropstone.key`.
Claims: `{id, email, name, imageUrl, provider:"github", iat, exp}`; 7-day expiry, no refresh token.

```json
401 {"error":"Access denied. Authentication token required.","authenticate":"Bearer realm=\"Dropstone Server\""}
403 {"error":"Invalid token format. Please log in again.","authenticate":"Bearer realm=\"Dropstone Server\", error=\"invalid_token\""}
```

No `x-api-key`, no `openai-organization`. This is an account token, not an OpenAI key gateway.

---

## 3. Headers

| Header | Required | Notes |
|---|---|---|
| `content-type: application/json` | yes | body-parser rejects otherwise |
| `authorization: Bearer <jwt>` | yes | 401/403 above |
| `user-agent` | yes, effectively | omitting it → Cloudflare `403 {"error code":1010}` before auth runs. `curl/8.x`, `python-requests/2.x`, `dropstone/1.0.67` all pass; bare `Python-urllib/3.13` blocked |

Optional CLI telemetry tags (no server-side validation — garbage values still return 200):

```
x-dropstone-client: cli
x-dropstone-surface: cli          # cli | web | vscode
x-dropstone-project: global       # constant, even inside a git repo (verified)
x-dropstone-session: ses_<…>
x-dropstone-request: msg_<…>
```

---

## 4. Endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/v1/chat/completions` | chat; OpenAI body; three response modes |
| `GET` | `/v1/jobs/{uuid}` | poll background job |
| `POST` | `/v1/jobs/{uuid}/cancel` | cancel background job |
| `GET` | `/api/models/public` | model catalogue (no auth, gzip, ~3.1 KB) |
| `GET` | `/account` | user + quota (`freeRequestsUsed/Limit`, `creditBalance`, `improveDropstone`) |

Per-turn sidecars the CLI calls with the same prompt text (not part of the chat API):

```
POST /api/memory/context  {"query": "<prompt + system reminder + date>"}
POST /api/skills/suggest  {"query": "<same>", "surface": "cli"}
```

---

## 5. `POST /v1/chat/completions` — request body

### Canonical (what the CLI sends)

```json
{
  "model": "dropstone-fast",
  "max_tokens": 65536,
  "messages": [
    {"role": "system", "content": "…"},
    {"role": "user", "content": [{"type": "text", "text": "…"}]}
  ],
  "tools": [{"type": "function", "function": {"name": "bash", "description": "…", "parameters": {"type": "object", "properties": {…}, "required": ["command", "description"]}}}],
  "tool_choice": "auto",
  "stream": true,
  "stream_options": {"include_usage": true},
  "background": true
}
```

Measured sizes: title-generation call 3,313 B; real agent turn 124,946 B (58,397 B system prompt + 27 tool schemas).

### Messages

- `role`: `system` | `user` | `assistant` | `tool`.
- `content`: string **or** part array. Parts seen: `{"type":"text","text":"…"}`, `{"type":"image_url","image_url":{"url":"data:image/png;base64,…"}}` (vision verified).
- Tool call / result: standard `assistant.tool_calls[]` and `{"role":"tool","tool_call_id","content"}`.
- CLI collapses prompt + injected system-reminder + date into **one** `user` message with multiple text parts.

### Tools

Plain OpenAI function tools, `parameters` = JSON Schema, `additionalProperties:false` accepted. CLI ships 27, e.g. `bash {command, timeout, workdir, run_in_background, description}` (requires `description`), `read {filePath, offset, limit}`, `glob {pattern, path}`.

### `background` — the one non-OpenAI field

| `background` | `stream` | Response |
|---|---|---|
| absent / `false` | `false` | `200` blocking `chat.completion` JSON |
| absent / `false` | `true` | `200` `text/event-stream` SSE |
| `true` | either | `202` `dropstone.job` ack → poll `/v1/jobs/{id}` |

Default synchronous. `background:true` is the CLI's path for every real turn (progress rendering + cancel), and `stream`/`stream_options` are then inert.

### Param acceptance (probed, `dropstone-fast`)

| Param | Behaviour |
|---|---|
| `max_tokens` | honoured |
| `temperature`, `top_p`, `stop`, `presence_penalty`, `frequency_penalty`, `seed` | accepted, passed through |
| `n` | **ignored** — always 1 choice |
| `response_format: {type:"json_object"}` | **ignored** — prose returned |
| `reasoning_effort` | accepted; output populates `reasoning_content` |
| `parallel_tool_calls`, `tool_choice:"auto"\|"required"` | accepted |
| `user`, `metadata`, unknown keys | accepted, no effect (no strict validation) |

### Model ids

Alias names come from `GET /api/models/public`; the response echoes the **upstream** id instead.

| Alias | `model` echoed in response | Notes |
|---|---|---|
| `dropstone-fast` (default) | `deepseek-ai/DeepSeek-V4.1-Flash-1017` | 1M ctx / 65,536 max_tokens, `credits:0` |
| `dropstone-fast-1.7` | `deepseek-ai/DeepSeek-V4-Flash-0731` | prior Fast |
| `dropstone-pro` | `deepseek-ai/DeepSeek-V4.1-Flash-1017` | on free tier resolves to same upstream as fast — recheck on paid plan |
| `dropstone-heavy` | — | `402 model_plan_required` |

Job ack uses a third spelling: `"model":"dropstone/deepseek-v4.1-flash"` (provider-prefixed alias). Match on the alias you sent, never on echoed `model`.

Raw upstream ids also accepted (from `allowedModels`): `openai/gpt-4o-mini`, `openai/gpt-5`, `openai/gpt-5.2-codex`, `openai/o3-mini`, `openai/text-embedding-3-small`, `anthropic/claude-sonnet-4.6`, `anthropic/claude-opus-4-6`, `anthropic/claude-opus-4-5-20251101`, `google/gemini-3`, `google/gemini-2.0-flash-001`, `deepseek/deepseek-v3.2`, `deepseek/deepseek-v3.2-speciale`, `deepseek/deepseek-r1`, `moonshotai/kimi-k2.5`, `dropstone/deepseek-v4-flash-0731`, `dropstone/glm-5.2`, `dropstone/kimi-k3`, `dropstone/deepseek-v4.1-flash`, `dropstone/deepseek-v4.1-flash-pro`, `dropstone/kimi-k3.1-pro`, `dropstone/qwen3.5-35b-a3b`.

Unknown model → `403`:

```json
{"error":"Model not available","message":"The model \"nope-model\" is not available. Please use one of our curated models.","allowedModels":[…],"suggestedModel":"dropstone-fast"}
```

---

## 6. Response shapes

### A. Blocking — `200 application/json`

```json
{
  "service_tier": "default",
  "id": "chatcmpl-RmAwfaaqEilxWFWd2hJkkPo0",
  "object": "chat.completion",
  "created": 1794026229,
  "model": "deepseek-ai/DeepSeek-V4.1-Flash-1017",
  "choices": [{
    "index": 0,
    "message": {"role": "assistant", "content": "1, 2, 3.", "reasoning_content": null, "name": null, "tool_calls": null},
    "finish_reason": "stop",
    "logprobs": null
  }],
  "usage": {
    "prompt_tokens": 8, "completion_tokens": 9, "total_tokens": 17,
    "estimated_cost": 0.00000343,
    "prompt_tokens_details": {"cached_tokens": 0, "cache_write_tokens": null},
    "completion_tokens_details": {"reasoning_tokens": 0}
  }
}
```

Extras vs OpenAI: `service_tier`, `message.reasoning_content`, `usage.estimated_cost`, `usage.prompt_tokens_details.cache_write_tokens`.

Tool call:

```json
{"choices":[{"index":0,"message":{"role":"assistant","content":"","tool_calls":[{"id":"chatcmpl-tool-a572e7621753303f","type":"function","function":{"name":"get_time","arguments":"{\"tz\": \"Asia/Tokyo\"}"}}]},"finish_reason":"tool_calls"}]}
```

Tool ids are prefixed `chatcmpl-tool-`, not `call_`.

### B. Streaming — `200 text/event-stream`

Headers: `content-type: text/event-stream`, `cache-control: no-cache`, `transfer-encoding: chunked`.

```
data: {"service_tier":null,"id":"chatcmpl-RcAeoMSrvlHPRugDdAXqwtQQ","object":"chat.completion.chunk","created":1794026230,"model":"deepseek-ai/DeepSeek-V4.1-Flash-1017","choices":[{"index":0,"delta":{"role":"assistant","content":""},"finish_reason":null}]}
data: {…"delta":{"role":null,"content":"1"},"finish_reason":null}
data: {…"delta":{"role":null,"content":", 2, 3."},"finish_reason":"stop"}
data: {…"choices":[],"usage":{"prompt_tokens":8,…,"estimated_cost":…}}
data: [DONE]
```

Order: role chunk (`service_tier:null`) → content deltas (`role:null`) → final delta with `finish_reason` → **usage-only chunk with `choices: []`** (only when `stream_options.include_usage`) → `data: [DONE]`. No `id:` lines, no comments, no heartbeats.

### C. Background job — `202 application/json`

Ack (truncated — no `content`, `tool_calls`, `usage`):

```json
{"id":"5fe7076b-eb67-4460-a650-297461458f3c","object":"dropstone.job","status":"running","model":"dropstone/deepseek-v4.1-flash","created":1794026230}
```

`GET /v1/jobs/{id}` (running):

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
  "error": null, "error_code": null, "error_status": null,
  "retryable": false,
  "usage": {"prompt_tokens": null, "completion_tokens": null},
  "created": 1794025057,
  "finished": null
}
```

Terminal:

```json
{"status":"done","content":"Reply with ok","finish_reason":"stop","tool_calls":[],
 "usage":{"prompt_tokens":743,"completion_tokens":4,"prompt_tokens_details":{"cached_tokens":64}},
 "finished":1794025059}
```

`status`: `running` | `done` | `cancelled` (errors set `error` + `error_code` + `error_status` + `retryable`). Cancelled job → `status:"cancelled"`, `error:"Cancelled"`, `finish_reason:null`.

Polling convention: **~600 ms fixed interval** (measured 0.59 / 0.61 / 0.69 s), one poller per job, two jobs in flight per turn (title + agent). No `retry-after`, no backoff, no long-poll/`since` param, whole job object returned each time (no delta stream).

### D. Cancel

```
POST /v1/jobs/{uuid}/cancel  -> 200 {"id":"66daffa1-…","status":"cancelling"}   (then cancelled)
DELETE /v1/jobs/{uuid}       -> 404 {"error":"Endpoint not found","path":"…","method":"DELETE","timestamp":"…"}
```

---

## 7. Error catalogue (verbatim)

```json
400 {"error":{"message":"Unexpected token '\"', \"\"not-json\"\" is not valid JSON","type":"entity.parse.failed"}}
401 {"error":"Access denied. Authentication token required.","authenticate":"Bearer realm=\"Dropstone Server\""}
403 {"error":"Invalid token format. Please log in again.","authenticate":"Bearer realm=\"Dropstone Server\", error=\"invalid_token\""}
403 {"error":"Model not available","message":"…","allowedModels":[…],"suggestedModel":"dropstone-fast"}
402 {"error":"model_plan_required","message":"Dropstone Heavy requires a paid Dropstone plan (Pro or Max). …"}
404 {"error":"job_not_found","message":"Job not found"}
404 {"error":"Endpoint not found","path":"/v1/jobs/<id>","method":"DELETE","timestamp":"…"}
403 {"error code":1010}          // Cloudflare, request never reaches the app
```

Two dialects: app-level `{"error":"<snake_code>","message":"…"}` and Express/body-parser `{"error":{"message":…,"type":…}}`. `messages: []` hangs (>40 s, no response) — treat as undefined.

---

## 8. Per-turn sequence

```
1  GET  /api/models/public                      catalogue (cached per run)
2  GET  /account                                quota display
3  POST /v1/chat/completions  background:true   title generation
4  POST /api/memory/context  {query}
5  POST /api/skills/suggest  {query, surface}
6  POST /v1/chat/completions  background:true   real turn (58 KB system + 27 tools)
7  GET  /v1/jobs/{id}  … every ~600 ms
8  (opt) POST /api/share {sessionID, platform} -> 201 {id, url, secret}
   (opt) POST /api/share/{id}/sync {secret, data:[{type,data}]} -> {ok, truncated}
```

---

## 9. curl recipes

```bash
TOKEN=$(jq -r '.dropstone.key' ~/.local/share/dropstone-cli/auth.json)
UA='user-agent: dropstone/1.0.67'

# blocking
curl -sS https://api.dropstone.io/v1/chat/completions -H "authorization: Bearer $TOKEN" \
  -H 'content-type: application/json' -H "$UA" \
  -d '{"model":"dropstone-fast","messages":[{"role":"user","content":"hi"}],"max_tokens":64}'

# streaming
curl -sN https://api.dropstone.io/v1/chat/completions -H "authorization: Bearer $TOKEN" \
  -H 'content-type: application/json' -H "$UA" \
  -d '{"model":"dropstone-fast","messages":[{"role":"user","content":"count to 5"}],"stream":true,"stream_options":{"include_usage":true},"max_tokens":64}'

# job mode
JOB=$(curl -sS https://api.dropstone.io/v1/chat/completions -H "authorization: Bearer $TOKEN" \
  -H 'content-type: application/json' -H "$UA" \
  -d '{"model":"dropstone-fast","background":true,"messages":[{"role":"user","content":"hi"}]}' | jq -r .id)
curl -sS https://api.dropstone.io/v1/jobs/$JOB -H "authorization: Bearer $TOKEN" -H "$UA"
curl -sS -X POST https://api.dropstone.io/v1/jobs/$JOB/cancel -H "authorization: Bearer $TOKEN" -H "$UA"
```

---

## 10. Gotchas

1. Not a drop-in OpenAI proxy: `authorization: Bearer <dropstone JWT>` only, and the real turn path (`background:true`) is a job API.
2. `user-agent` is load-bearing; default `Python-urllib/*` is blocked by Cloudflare 1010 before auth.
3. `model` echo mismatch across modes — alias in, upstream id out, provider-prefixed alias in job acks.
4. `n`, `response_format`, `logprobs` are accepted but ignored — no structured output support found.
5. Streaming emits a final usage-only chunk with `choices: []`; strict OpenAI parsers indexing `choices[0]` break under `include_usage`.
6. Tool ids use `chatcmpl-tool-` prefix; `finish_reason:"tool_calls"`.
7. Thinking text lives in `reasoning_content` (not `reasoning`), `null` for non-reasoning models.
8. `usage.estimated_cost` (float USD) appears in sync, SSE-usage and terminal job payloads.
9. `service_tier` present everywhere; `null` on first SSE chunk.
10. No streaming for job mode — polling the whole object is the only channel; the CLI does it at ~600 ms.
