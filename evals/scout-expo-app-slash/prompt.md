---
max_turns: 8
allowed_tools: [Skill]
tags: [plugin-scout, slash]
---

/ai:plugin-scout Which plugins should I enable for this repo? I keep every plugin disabled in ~/.claude/settings.json and enable them per repo. Here is what I collected.

Scan output:

```
# Installed plugins

| plugin | user | skills | agents | commands | mcp | hooks | lsp | desc-chars |
|---|---|---|---|---|---|---|---|---|
| code-simplifier@claude-plugins-official | false | 0 | 1 | 0 | - | - | - | 310 |
| expo@claude-plugins-official | false | 24 | 0 | 0 | expo | - | - | 8900 |
| linear@claude-plugins-official | false | 0 | 0 | 0 | linear | - | - | 0 |
| sentry@claude-plugins-official | false | 9 | 0 | 0 | sentry | - | - | 2100 |
| superpowers@claude-plugins-official | false | 14 | 1 | 3 | - | SessionStart | - | 4200 |
| superpowers@superpowers-marketplace | false | 14 | 1 | 3 | - | SessionStart | - | 4200 |
| supabase@claude-plugins-official | false | 2 | 0 | 0 | supabase | - | - | 650 |
| vercel@claude-plugins-official | false | 41 | 3 | 4 | vercel | SessionStart,UserPromptSubmit | - | 12400 |

# This project's settings

.claude/settings.json: missing
.claude/settings.local.json: missing

# Usage in the last 30 sessions

## Plugin components called (count, name)

     14 mcp claude_ai_Linear
      7 skill superpowers:brainstorming
      4 skill expo:expo-router
      3 mcp plugin_supabase_supabase
      2 skill superpowers:writing-plans
```

Repo facts: package.json depends on expo, expo-router, @supabase/supabase-js and @sentry/react-native. There is a supabase/ folder with migrations, an eas.json, and a sentry.properties file. No vercel.json, no Next.js. Almost all files are .ts and .tsx.
