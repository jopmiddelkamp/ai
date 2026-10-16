---
type: llm
---

PASS if the "Plugins to Add" section leaves out vercel, code-simplifier and linear. The linear plugin must stay out because the 14 Linear calls come from the claude.ai connector (mcp claude_ai_Linear), not from the plugin.
FAIL if "Plugins to Add" lists vercel, code-simplifier or linear.
