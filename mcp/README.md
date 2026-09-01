# MCP servers

`servers.json` holds the shape of every MCP server. It never holds a secret.
Every secret and every machine path is a `${VAR}` placeholder.

Real values live in `~/.claude/mcp.env`, which git ignores.

Apply the template with:

```bash
bash scripts/apply-mcp.sh --dry-run   # show the plan
bash scripts/apply-mcp.sh             # write ~/.claude.json
```

## Variables to define in `~/.claude/mcp.env`

| Variable | Used by | Where to get it |
|---|---|---|
| `MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN` | `moneybird-middelkamp-development` | Moneybird, administration Middelkamp Development, personal API token |
| `MONEYBIRD_HOLDING_42_TOKEN` | `moneybird-holding-42` | Moneybird, administration Holding 42, personal API token |
| `GBRAIN_TOKEN` | `gbrain` | the hosted GBrain deployment |
| `TRELLO_API_KEY` | `trello` | Trello developer settings |
| `TRELLO_TOKEN` | `trello` | Trello developer settings |
| `TRELLO_MCP_PATH` | `trello` | path to `dist/index.js` in the local Trello-Desktop-MCP checkout |

## Servers

### pencil
- **Purpose:** design work in the Pencil desktop app.
- **Transport:** stdio, a binary inside `/Applications/Pencil.app`.
- **Secrets:** none.
- **Where to check:** the Pencil app release notes.
- **Last checked:** 2026-09-01.

### moneybird-middelkamp-development
- **Warning: this endpoint is read AND write.** A request can create or change
  a real invoice, contact or ledger entry. Treat every write as a real
  bookkeeping action, not a test.
- **Purpose:** bookkeeping for the Middelkamp Development administration.
- **Transport:** http, `https://moneybird.com/mcp/v1/read_write`.
- **Secrets:** `MONEYBIRD_MIDDELKAMP_DEVELOPMENT_TOKEN`, sent as `Authorization: Bearer <token>`.
- **Where to check:** https://developer.moneybird.com/
- **Last checked:** 2026-09-01.

### moneybird-holding-42
- **Warning: this endpoint is read AND write**, same as above.
- **Purpose:** bookkeeping for the Holding 42 administration.
- **Transport:** http, same endpoint as above. The token selects the administration.
- **Secrets:** `MONEYBIRD_HOLDING_42_TOKEN`.
- **Where to check:** https://developer.moneybird.com/
- **Last checked:** 2026-09-01.

### trello
- **Purpose:** read and write Trello boards and cards.
- **Transport:** stdio, `node <TRELLO_MCP_PATH>`.
- **Secrets:** `TRELLO_API_KEY`, `TRELLO_TOKEN`.
- **Where to check:** the local Trello-Desktop-MCP checkout and its upstream repo.
- **Last checked:** 2026-09-01.

### vercel-private
- **Purpose:** deployments, logs, and project data on Vercel.
- **Transport:** http, `https://mcp.vercel.com`. It uses OAuth, so no token file.
- **Secrets:** none on disk. Authorise it in an interactive session.
- **Where to check:** https://vercel.com/docs/mcp
- **Last checked:** 2026-09-01.

### gbrain
- **Purpose:** the personal knowledge brain.
- **Transport:** http, `https://hosted-gbrain-production.up.railway.app/mcp`.
- **Secrets:** `GBRAIN_TOKEN`.
- **Where to check:** the local `hosted-gbrain` repo.
- **Last checked:** 2026-09-01.

### wispr-flow
- **Purpose:** dictation history from the Wispr Flow app.
- **Transport:** http, `https://api.wisprflow.ai/connect/mcp`. It uses OAuth.
- **Secrets:** none on disk. Authorise it in an interactive session.
- **Where to check:** https://wisprflow.ai
- **Last checked:** 2026-09-01.
