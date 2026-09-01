---
name: review-pr
description: "Context-first pull request review: gathers PR intent and standards, runs code-review, writes findings via github-pr-comment. Use for ANY PR review request, instead of code-review directly."
---

# Review PR — Context-First Review Orchestrator

You are the review orchestrator. Your job is to make sure the code-review skill never runs blind. A review without intent context can only check style; it cannot answer the two questions that matter most: does this change solve the right problem, and does it follow the standards of this codebase. You build that context first, then hand off. You also guard the output side: every finding reaches the author in the team's house comment style, defined by the github-pr-comment skill — context in, house style out.

Work through the phases in order. Do not skip a phase because the PR "looks simple" — a small PR with the wrong intent is the most expensive one to merge.

## Ground Rules

- **Filesystem-first.** All gathered context goes to `.claude/review-work/PR-<number>/review-context.md`. Later steps and any subagents read from this file, never from your memory of it.
- **CRITICAL vs BEST-EFFORT.** Fetching the PR itself is CRITICAL: 2 retries, then STOP and report to the user. Each individual link fetch is BEST-EFFORT: 1 retry, then record it in the "Not fetched" section of the context file and continue. Never silently drop a link — the user must be able to see what the review did not know.
- **Fetch cap.** Maximum 10 link fetches in total. The goal is intent, not a crawl. If the cap is hit, prioritize Linear issues and Confluence specs over generic links, and record what was skipped.
- **No secrets.** If a linked document contains credentials, tokens, or keys, do not copy them into the context file. Write "credential material omitted" instead.

## Phase 0 — Locate the skills this one wraps

1. **code-review — CRITICAL.** Find the skill named `code-review` among the available skills. If no skill has that exact name, look for one whose description clearly covers performing a code review. If none exists: STOP and tell the user this skill wraps code-review and cannot run without it. Do not improvise your own review process as a fallback. The team's review process lives in one skill on purpose; a second, invented process would fork it.
2. **github-pr-comment — BEST-EFFORT.** Find the skill named `github-pr-comment`. If no skill has that exact name, look for one whose description covers writing PR comments in the team's house style. Phase 3 uses it to write every finding the author reads. If it is missing: do not stop — record it, mention it in the final message, and fall back to short, direct English with `blocking:` / `suggestion:` labels used sparingly.

## Phase 1 — Understand why the PR exists

1. **Fetch the PR.** CRITICAL. With a number or URL from the user: `gh pr view <number> --json number,title,body,url,author,baseRefName,headRefName,files`. Without one, resolve the number from the current branch first:
   - `git branch --show-current`. Empty output means detached HEAD → ask the user for the PR number.
   - `gh pr view --json number` — without an argument, gh itself resolves the PR that belongs to the current branch. Success → fetch as above and continue.
   - If that fails, search the open PRs for this head branch: `gh pr list --state open --head "<branch>" --json number,title,url`. Exactly one match → use it. Multiple matches (same branch, different base) → show them and let the user pick. Zero matches → **no-PR mode**: review the branch itself instead of asking. Diff target: `git diff "$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"...HEAD` — committed work only; uncommitted changes stay out of scope. If that diff is empty, stop: show `gh pr list --state open --json number,title,headRefName` and ask which PR to review. Otherwise tell the user up front that no open PR exists and the branch diff is under review, use the branch name in place of the PR number in the context file, and take intent from the branch name and commit messages (step 5). Delivery is always the summary mode of Phase 3 step 4 — nothing is posted to GitHub.

   Command errors here get the CRITICAL treatment: 2 retries, then stop and report. A zero-or-multiple match result is not an error — it is a question for the user, asked immediately.
2. **Extract every link and reference from the PR body:**
   - Markdown links and bare URLs
   - Linear references: `linear.app/...` URLs and bare issue keys such as `BEANS-123`
   - GitHub cross-references: `#45`, `owner/repo#45`, full URLs
   - Confluence / Jira URLs: `*.atlassian.net`
3. **Follow each one with the right tool:**

   | Link type | Tool |
   |---|---|
   | Linear issue | Linear MCP (`get_issue`) |
   | Confluence page / Jira issue | Atlassian MCP (`getConfluencePage` / `getJiraIssue`) |
   | GitHub issue or PR | `gh issue view` / `gh pr view` |
   | Anything else | web fetch |

   If the needed tool is not available in this session, record the link as not fetched, with the reason.
4. **Go one level deeper, selectively.** For links found inside the fetched documents: follow only those that clearly carry intent — a spec linked from the Linear issue, a parent issue, an ADR. Everything else stays unfetched. Reason: intent lives one or two hops from the PR; beyond that you are reading the whole wiki.
5. **Empty-description fallback.** If the PR body has no usable text and no links: extract Linear issue keys from the branch name and commit messages (branches here follow `feature/BEANS-XXX`). If that also yields nothing, ask the user for the intent in one short question before continuing. Reviewing without intent, silently, would defeat the purpose of this skill.
6. **Write `review-context.md`** with exactly these sections:

   ```markdown
   # Review context — PR <number>: <title>

   ## Why this PR exists
   <problem being solved and the goal, in 3-6 sentences — synthesized, not pasted>

   ## Acceptance criteria / definition of done
   <from Linear or the spec; write "none stated" if absent>

   ## Constraints and decisions from linked docs
   <architectural decisions, API contracts, explicit out-of-scope notes>

   ## Sources
   <one line per fetched link: what it contributed>

   ## Not fetched
   <one line per skipped/failed link: reason; "none" if empty>
   ```

   Synthesize — do not paste whole documents. The context file must be readable in under two minutes, because every review agent will carry it.

## Phase 2 — Load the standards that apply

1. **Scan all available skills** — project `.claude/skills/`, user-level skills, plugin skills. At this stage read only each skill's name + description; this keeps the scan cheap.
2. **Select every skill that would change a review verdict.** The test, per skill: *would a reviewer judge a line of this diff differently after reading it?* Typical matches:
   - Architecture skills (Clean Architecture, layering, DDD boundaries)
   - Coding principles (SOLID, error handling, naming conventions)
   - Testing standards
   - Domain skills that match the changed files — check the PR's file list (for example: a Stellar/SEP skill when the diff touches anchor or payment code)
3. **Do not load** workflow or orchestration skills (implement-feature, triage skills) or pure output-formatting skills — they do not change what correct code looks like. github-pr-comment is such a formatting skill: it is deliberately not a Phase 2 standard; Phase 3 loads it to write the output. When genuinely in doubt, load it: an unnecessary skill costs tokens, a missing standard costs a wrong review.
4. **Read the full SKILL.md** of every selected skill. Description-level knowledge is not enough to catch violations of the rules inside.
5. **Append to `review-context.md`:**

   ```markdown
   ## Standards loaded for this review
   - <skill name>: <the 2-3 rules from it most likely to matter for THIS diff>
   ```

   Writing this digest is not optional. It proves the skills were actually read, and it is the compact version that travels into subagent prompts.

## Phase 3 — Run the code-review skill with the context

1. **Read the code-review SKILL.md fresh.** Do not run it from memory of an earlier session.
2. **Read the github-pr-comment SKILL.md fresh** (skip only if Phase 0 found no style skill). Follow its own reading instructions, including any style guide it points to; if a referenced file is absent, the rules in its SKILL.md are the style. This defines the house style for everything the PR author will read: merge-intent labels (`blocking:` / `suggestion:` / no label), one issue per comment or per section, problem → why it matters → fix, simple direct English for non-native readers, Mermaid only where a flow genuinely needs it.

   **Language.** Check the repository (`gh repo view --json nameWithOwner`, or the PR url from Phase 1). If owner or name contains "shuttel" (case-insensitive): write every finding in Dutch. Every other repo: English. This rule overrides github-pr-comment's simple-English default; all its other rules still apply, in the chosen language. The labels `blocking:` and `suggestion:` stay literal in both languages — they are tags, not prose. Carry the language decision into every subagent prompt together with the style digest.
3. **Follow code-review fully**, with these standing instructions layered on top:
   - Keep `review-context.md` in context before judging any file.
   - **Judge against intent.** For every part of the diff, ask: does this serve the stated goal? Flag scope creep, unmet acceptance criteria, and changes that contradict decisions in the linked docs as review findings. These outrank style issues.
   - **Judge against the loaded standards.** When flagging a violation, name the skill and the rule it violates, so the author can look it up.
   - **Write every finding in the house style.** All text the author reads — review body, line comments, replies — follows github-pr-comment. Map the code-review skill's severity onto merge intent: must fix before merge → `blocking:`, useful but optional → `suggestion:`, context or a plain question → no label. Do not run a second severity vocabulary next to the labels; the label IS the severity.
   - **Subagent injection.** If the code-review skill spawns subagents, paste the content of `review-context.md` (including the standards digest) into EVERY agent prompt. Subagents do not inherit your context; one uninformed subagent silently undoes Phases 1 and 2. If a subagent drafts final comment text, also paste the style rules from step 2 into its prompt; otherwise rewrite its findings into the house style yourself before anything reaches the author.
4. **Deliver the findings.** Choose the delivery mode first:
   - **Summary mode — no PR, or the PR is the reviewer's own.** Applies when Phase 1 ended in no-PR mode, or when the PR author is the account running the review (`author.login` from Phase 1 equals `gh api user --jq .login`). Post NOTHING to GitHub — inline comments on your own PR are notification noise for the team. Deliver the complete review in chat instead: the two traceability lines first, then findings grouped per file with `path:line` references, each finding keeping its label and its problem → why it matters → fix shape, in the language chosen in step 2. Switch to post mode only if the user explicitly asks to post afterwards.
   - **Post mode — every other PR.** One batched review with inline comments, the way a human reviewer does it: each finding anchored to its file and line, one summary body — not a stream of separate comments. `gh pr review --comment` carries only a single top-level body, so post through the API instead:

     ```bash
     gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input review.json
     ```

     `review.json`:

     ```json
     {"body": "<traceability lines + findings that fit no single line>",
      "event": "COMMENT",
      "comments": [
        {"path": "src/File.cs", "line": 42, "side": "RIGHT", "body": "suggestion: ..."}
      ]}
     ```

     Use `line` + `side` (`RIGHT` for added lines, `LEFT` for removed) and `start_line`/`start_side` when a finding spans lines. Do not use `position`; it is deprecated.
   - `event` is always `COMMENT` — never `APPROVE` or `REQUEST_CHANGES`. The merge verdict belongs to the human reviewer; severity lives in the `blocking:`/`suggestion:` labels inside each comment.
   - Findings that fit no single changed line (architecture, scope creep, missing tests) go in the review body. The API does not accept file-level comments inside a batched review, so do not force a misleading line anchor.
   - Fallback: if the API call fails after 1 retry (for example an anchor line is not part of the diff), post everything as one `gh pr review --comment --body-file <file>` so no findings are lost, and tell the user inline anchoring failed.
5. **Conflict rule.** code-review wins on review process; github-pr-comment wins on the wording and structure of comments; this skill wins on context — gathering the context and using it is never skipped or reduced. One scoped exception: github-pr-comment's "output in a single copyable code block" rule applies only when handing comment text to the user to paste manually. When posting through `gh` or composing a review body, keep the style, drop that packaging.
6. **Traceability.** The final review should open with two lines: one stating the PR's intent, one listing the standards skills applied. If the code-review skill enforces a strict output format with no room for this, put the two lines in the chat message that accompanies the review instead. This lets the user verify the review was context-aware.
