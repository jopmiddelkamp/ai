# Plugins and marketplaces

Claude Code downloads plugins itself into `~/.claude/plugins/`. This repo
tracks only the list, so a new machine can be rebuilt.

## Marketplaces

| Name | Source | Auto-update |
|---|---|---|
| `claude-plugins-official` | github `anthropics/claude-plugins-official` | yes |
| `superpowers-marketplace` | github `obra/superpowers-marketplace` | yes |
| `ai` | github `jopmiddelkamp/ai`, this repo | yes |
| `gflow` | github `jopmiddelkamp/gflow` | yes |
| `humanizer` | github `blader/humanizer` | yes |
| `stellar-dev` | github `stellar/stellar-dev-skill` | yes |
| `gitkraken` | local directory, installed by the GitKraken app | yes |

Add a marketplace with:

```bash
claude plugin marketplace add <owner>/<repo>
```

## Enabled plugins

```
ai@ai
autofix-bot@claude-plugins-official
claude-code-setup@claude-plugins-official
claude-md-management@claude-plugins-official
code-modernization@claude-plugins-official
code-review@claude-plugins-official
code-simplifier@claude-plugins-official
context7@claude-plugins-official
csharp-lsp@claude-plugins-official
dart-and-flutter@anthropic-plugin-directory
elements-of-style@superpowers-marketplace
expo@claude-plugins-official
frontend-design@claude-plugins-official
gflow@gflow
github@claude-plugins-official
gitkraken-hooks@gitkraken
humanizer@humanizer
kotlin-lsp@claude-plugins-official
mcp-server-dev@claude-plugins-official
microsoft-docs@claude-plugins-official
php-lsp@claude-plugins-official
playground@claude-plugins-official
playwright@claude-plugins-official
ralph-loop@claude-plugins-official
rust-analyzer-lsp@claude-plugins-official
security-guidance@claude-plugins-official
sentry@claude-plugins-official
skill-creator@claude-plugins-official
slack@claude-plugins-official
stellar-dev@stellar-dev
supabase@claude-plugins-official
superpowers-chrome@superpowers-marketplace
superpowers-dev@superpowers-marketplace
superpowers-developing-for-claude-code@superpowers-marketplace
superpowers@claude-plugins-official
swift-lsp@claude-plugins-official
vercel@claude-plugins-official
```

`ai@ai` is this repo. Its manifests sit in `.claude-plugin/`, and it delivers
`skills/`. After a push, refresh it with:

```bash
claude plugin marketplace update ai && claude plugin update ai@ai
```

Install one with:

```bash
claude plugin install <name>@<marketplace>
```

## Refreshing this list

```bash
jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' ~/.claude/settings.json | sort
jq -r 'to_entries[] | "\(.key)\t\(.value.source.repo // .value.source.url // .value.source.path)"' ~/.claude/plugins/known_marketplaces.json
```
