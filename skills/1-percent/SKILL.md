---
name: 1-percent
description: "Audit and slim down a repo's AI-agent setup for current Claude models: CLAUDE.md and AGENTS.md as a short index, rules and skills written for older models, missing verification checks, shouted rules that belong in hooks, skills that add nothing, and subagent sprawl. Use when the user says '/1-percent', 'optimize my Claude setup', 'audit my CLAUDE.md', 'clean up my skills', 'is my agent config outdated', or asks to apply current Claude Code best practices to a repo. Not for reviewing application code."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-15"
---

# 1-percent

Newer models need less instruction, not more. Most agent setups carry rules written to fix what older models got wrong, and those rules now cost tokens, get followed less, and sometimes make the result worse. This skill finds that weight in a repo, proposes cuts and replacements, and applies them after one approval.

The guiding idea: leave Claude alone until it makes a real mistake, then add the smallest thing that fixes that mistake. Prefer, in order: nothing, a runnable check, a hook, one line of instruction, a skill.

## 1. Inventory

Find every file that instructs an agent in this repo. Search; do not assume locations:

- `CLAUDE.md` and `AGENTS.md` at any depth, `CLAUDE.local.md`, `.claude/rules/`, `.cursor/rules/`, `.github/copilot-instructions.md`
- `.claude/skills/`, `skills/`, `.claude/commands/`, `.claude/agents/`
- `.claude/settings.json`, `.claude/settings.local.json`, hook scripts they reference, git hooks (`.githooks/`, `.husky/`, `core.hooksPath`)
- Output styles, and plugin manifests and lists (`.claude-plugin/`, `plugins.md`)
- Any file that those files point to, through `@path` imports or plain paths

Also include the files that load every session from outside the repo: `~/.claude/CLAUDE.md`, the active output style, and `~/.claude/settings.json`. Audit them, but label each finding "outside repo" so the user knows the fix lands elsewhere. If the repo itself is a config repo that installs those files, treat its copies as in scope.

Record each file's line count and how it is reached: always loaded, imported, pointed at, or invoked as a skill. "Always loaded" means every CLAUDE.md on the path, user memory, the output style, and every skill description. If the host may not load a file on its own (an `AGENTS.md` with no `CLAUDE.md` importing it, for example), say so instead of assuming. Note the project's own check commands: test, lint, typecheck, build, from `package.json`, `Makefile`, `justfile`, CI config, or scripts.

## 2. Audit

Check every item below. Each finding needs a file and line you read in this session and a concrete fix. Do not flag a line that is fine; an empty section is a valid result.

### A. CLAUDE.md is an index, not a manual

- **Length.** Target under 200 lines per CLAUDE.md file. Longer files cost more context and get followed less.
- **Content.** Keep only what is always true and that Claude cannot guess: (1) tools and commands it cannot infer, (2) where this project does things differently from the usual way, (3) gotchas it got wrong more than once, (4) boundaries (what it must not touch or send). Everything else either goes, or moves to its own file with a pointer.
- **Pointers.** Write a pointer as a backticked path plus when to open it: ``Read `docs/client-brief.md` before any client work.`` Flag each `@path` import: imports are expanded into context at launch, every session. Keep an import only when that content is needed in nearly every session.
- **One level deep.** Point at every reference file directly from CLAUDE.md or SKILL.md. Files reached only through another file may be read partially (for example only the first 100 lines).
- **Contents list.** A pointed-at file over 100 lines gets a short table of contents at the top, so a partial read still shows what is inside.
- **Rot.** Paths that do not exist, commands that no longer run, and counts or lists of skills, commands, or files in READMEs, inventories, and manifests that no longer match the directory. Propose a test that compares those lists with the directory, so this rot cannot come back.
- **Conflicts.** Instructions that contradict each other across user memory, CLAUDE.md, AGENTS.md, rules, output styles, skills, and saved memories ("ask before deciding" in one place, "decide and report" in another). Read the always-loaded files together, as the model does, and quote both sides.

### B. Instructions written for older models

- **Plan-first rituals** ("always start in plan mode", "write a plan and wait for approval before coding"). Replace them with a brief pattern for tasks: the task, the guardrails, and what done looks like. After big changes, ask for a diagram or a one-page summary of what changed and what was assumed. Keep a plan step only where the project truly needs sign-off before work starts.
- **Thinking keywords as standing rules** ("ultrathink", "always think harder"). The effort setting controls the thinking budget; the recommended default (medium on Opus 5.5) fits most work. Remove the keywords and flag any effort override in settings or env that has no stated reason.
- **Self-check prompts** ("double-check your work", "re-read before answering", "verify carefully"). Current models check their own work unprompted; these lines add cost without improving results. Remove them, and replace them with a runnable check (section C) where one is missing. Keep a checklist that names specific known failure points ("every cell has a reason, every `file:line` was read"): that is a correction, not a generic re-check.
- **Shouting** (CRITICAL, IMPORTANT, MUST, NEVER in capitals, or stacked emphasis). Newer models over-apply emphasized rules. Sort each one:
  - Claude does it anyway → delete.
  - It must never happen (sending email, pushing to main, touching prod, editing a generated file) → a `PreToolUse` hook or a `permissions.deny` rule, which blocks it whatever the model decides. Then delete the line.
  - Otherwise → rewrite it as a plain, calm instruction that gives the reason.
- **Delegation overreach.** Hand-built orchestrators, routing files, or "use subagents for everything" for small jobs. Current models delegate readily on their own, which multiplies cost and time on small tasks. Replace it with a written cap ("Use at most N subagents; do small tasks inline"). `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` limits only how many run at once, not the total.

### C. Verification Claude can run

A check Claude can run turns a supervised session into one you can walk away from.

- Is there one command that proves the work is done (tests, lint, typecheck, build), and does CLAUDE.md name it? If it is missing, propose one: usually a script or make target that chains the existing checks. Deterministic beats a checklist; a checklist doc (style guide, brand voice) still beats nothing.
- For a recurring task with a clear done state, propose a `/goal` line built on that check. The goal judge does not run commands or read files; it only sees what Claude has shown in the conversation. So the condition must name the check and require its output to be shown, say what must not change, and include a stop clause:
  `/goal scripts/check.sh passes and its output is shown; templates/ unchanged; or stop after 15 turns`

### D. Skills earn their place

- **Corrections, not manuals.** A good skill mostly lists what Claude gets wrong without it. Flag skills that restate default behavior, explain general practice Claude already knows (textbook definitions, generic best practice), or document an imagined process. Point at the lines that are textbook and the lines that are real corrections, and propose cutting it down to the corrections. Flag word-for-word paragraphs repeated across skills.
- **Overlapping triggers.** Skills whose descriptions fire on the same requests ("any code change", "writing or refactoring code"), so several load at once and their advice competes. Propose narrowing the descriptions with "Use when" and "Not for" lines, or merging the skills.
- **Duplicate installs.** The same plugin or skill installed from two sources, or an installed skill that duplicates a local one.
- **Measure before you delete.** Judgment flags a skill; evidence removes it. Recommend `/skill-doctor` (context cost and usage per skill; it flags never-used ones), `claude plugin eval .` for a plugin (runs each case with and without the plugin and scores the difference), and the skill-creator skill for a single skill. A skill whose score equals the no-skill baseline only costs tokens.
- **Shape.** References one level deep, a contents list in references over 100 lines, and a description that says when to use it.
- **Heavy steps.** A skill step that does broad research or pulls large MCP or connector output should say to run that step in a subagent, so the main context stays clean.
- **Tested on the right model.** A skill tuned on one model may need more or less on another. A metadata label is not evidence: count only eval files, eval results, or a commit message that describes test runs. Without that evidence, add the skill to the eval recommendation; do not report it as a defect.

### E. Automation candidates

Name recurring manual work the repo shows (release notes, dependency bumps, report generation, triage) that could run as a scheduled routine (`/schedule`) or a loop (`/loop`) once it has a check from section C. Suggest only; do not set any up.

## 3. Report

Open with one line: the total instruction lines always loaded today and after the proposed changes. Then one table per section that has findings, numbered across all sections so the user can exclude items by number:

| # | File:line | Finding | Fix |
|---|---|---|---|
| 1 | `CLAUDE.md:42` | "ALWAYS double-check your changes" | Delete; `npm run check` already covers it (C) |

End with the list of edits you will make, grouped by file, plus the items you recommend but will not do yourself (evals, `/skill-doctor`, `/goal` lines, routines). Ask once for approval, and let the user exclude items by number.

## 4. Apply

Change only what was approved. When you move content out of CLAUDE.md, move it verbatim into the new file and add the pointer in the same edit, so nothing is lost. A new hook gets a one-line comment saying which rule it replaced. Keep the repo's commit and test conventions.

## 5. Verify

- Run the project's checks and any instruction-file tests it has.
- Recount the lines of every always-loaded file, and confirm that every pointer and import resolves.
- Test each new hook once by triggering the blocked action in a way that is safe, and show that it was blocked.
- Suggest `/doctor prompt-audit` as a second opinion on outdated or conflicting instructions.

Report the before and after line counts, what changed, and what is left for the user.

## Sources

Re-check these before you change this skill; the details move fast.

- Opus 5 prompting guide (self-verification, delegation): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
- Effort defaults: https://platform.claude.com/docs/en/build-with-claude/effort
- Memory and CLAUDE.md (200 lines, imports): https://code.claude.com/docs/en/memory.md
- Skill authoring (evaluation first, one level deep, contents list): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- `/goal`: https://code.claude.com/docs/en/goal.md
- Hooks: https://code.claude.com/docs/en/hooks-guide.md
- Plugin evals: https://code.claude.com/docs/en/plugin-evals.md
- Subagents: https://code.claude.com/docs/en/sub-agents.md
