# Plugins and marketplaces

Claude Code downloads plugins itself into `~/.claude/plugins/`. This repo
tracks only the list, so a new machine can be rebuilt.

## Marketplaces

| Name | Source | Auto-update |
|---|---|---|
| `claude-plugins-official` | github `anthropics/claude-plugins-official` | yes |
| `superpowers-marketplace` | github `obra/superpowers-marketplace` | yes |
| `stellar-dev` | github `stellar/stellar-dev-skill` | no |
| `business-coach` | git `https://github.com/jopmiddelkamp/ai-business-coach.git` | no |
| `gitkraken` | local directory, installed by the GitKraken app | no |

Add a marketplace with:

```bash
claude plugin marketplace add <owner>/<repo>
```

## Enabled plugins

```
autofix-bot@claude-plugins-official
business-coach@business-coach
claude-code-setup@claude-plugins-official
code-review@claude-plugins-official
context7@claude-plugins-official
elements-of-style@superpowers-marketplace
frontend-design@claude-plugins-official
gitkraken-hooks@gitkraken
playwright@claude-plugins-official
security-guidance@claude-plugins-official
skill-creator@claude-plugins-official
stellar-dev@stellar-dev
superpowers@claude-plugins-official
superpowers@superpowers-marketplace
superpowers-chrome@superpowers-marketplace
superpowers-dev@superpowers-marketplace
superpowers-developing-for-claude-code@superpowers-marketplace
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
