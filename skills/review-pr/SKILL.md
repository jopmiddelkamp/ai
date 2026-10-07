---
name: review-pr
description: "Context-first pull request review that wraps the code-review skill. Use for any request to review a pull request, a PR number or URL, or the current branch before a PR is opened, instead of code-review directly. Triggers on 'review PR', 'review this pull request', 'is this mergeable', 'take a look at PR 42', 'code review my branch', 'check PR X against our rules'."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-07"
---

# Review PR: context in, house style out

A review without intent can only check style. It cannot answer the two questions that matter most: does this change solve the right problem, and does it follow the standards of this codebase? This skill builds that context, hands it to the code-review skill, and makes sure every finding reaches the author in the house comment style. A small PR with the wrong intent is the most expensive one to merge, so run every phase for small PRs too.

## Standing rules

- **Context lives in a file.** Write all gathered context to `.claude/review-work/PR-<number>/review-context.md`. Later steps and subagents read that file, so nothing depends on your memory of it.
- **Retries.** Fetching the PR itself: 2 retries, then stop and report to the user. Each linked document: 1 retry, then record it under "Not fetched" and continue. The user must see what the review did not know.
- **At most 10 link fetches.** The goal is intent, not a crawl. At the cap, prefer issue-tracker and specification links, and record what you skipped.
- **Read-only.** Gathering intent never writes to a vendor. Do not call a tool whose name starts with `create`, `update`, `edit`, `delete`, `add`, `save`, `transition`, or `submit`.
- **No secrets.** If a linked document holds credentials, tokens, or keys, write "credential material omitted" in the context file.
- **English.** Write every finding in English, in every repository.

## Phase 0: find the wrapped skills

- **code-review** (required): the skill named `code-review`, or else one whose description clearly covers performing a code review. If none exists, stop and tell the user this skill cannot run without it. Do not improvise a review process: the team keeps its review process in one skill on purpose.
- **pull-request-comment-style** (optional): the skill with that name, or one whose description covers PR comments in the team's house style. If it is missing, say so in the final message and write each finding as short, direct English: the problem, why it matters, the fix. Every finding then blocks unless it ends with `This is just a suggestion. If you disagree, resolve this comment yourself.`

## Phase 1: why does the PR exist?

1. **Fetch the PR:** `gh pr view <number> --json number,title,body,url,author,baseRefName,headRefName,files`. Without a number from the user, resolve it from the current branch:
   - `gh pr view --json number` finds the PR of the current branch. An empty `git branch --show-current` means detached HEAD: ask for the number.
   - If that fails: `gh pr list --state open --head "<branch>" --json number,title,url`. One match: use it. Several matches (same branch, different base): show them and let the user pick.
   - Zero matches: **no-PR mode.** Review the committed work on the branch, `git diff "$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"...HEAD`, and tell the user up front that no open PR exists. Use the branch name in place of the PR number, take intent from the branch name and commit messages, and deliver in summary mode. If the diff is empty, show `gh pr list --state open --json number,title,headRefName` and ask which PR to review.
2. **Collect every reference in the PR body:** links, bare URLs, issue keys such as `ABC-123`, `#45`, `owner/repo#45`, quoted page titles. Do not assume one vendor.
3. **Resolve each reference with a read tool this session has.**
   - First, an MCP server named after the link's vendor. The vendor is the host without subdomains and suffix: `wiki.acme.atlassian.net` is `atlassian`, `linear.app` is `linear`. Server names can carry a prefix or an account name, such as `claude_ai_Atlassian`, so match loosely and check the tool names. If the session shows no tool list, read `claude mcp list`. From that server, prefer a tool that takes the URL, then a typed getter, then a search by id.
   - No matching server: `gh issue view` or `gh pr view` for GitHub links and `#45` shorthands, a web fetch for other URLs. A bare issue key goes to the one issue-tracker server in the session; with zero or several such servers, record it as not fetched.
   - Never guess the content of a link you could not open. Record it under "Not fetched" with the reason: no matching tool, the tool failed, or the server needs authorization.
4. **One level deeper, selectively.** From the fetched documents, follow only links that carry intent: a linked spec, a parent issue, an architecture decision record. Intent lives one or two hops from the PR; further out you are reading the whole wiki.
5. **Empty description.** Take the issue key from the branch name or the commit messages (`feature/ABC-123-short-title`) and resolve it the same way. If that also yields nothing, ask the user for the intent in one short question before you continue.
6. **Write `review-context.md`.** Every review agent carries this file, so keep it readable in under two minutes. Synthesize; do not paste documents.

   ```markdown
   # Review context — PR <number>: <title>

   ## Why this PR exists
   <problem being solved and the goal, in 3-6 sentences>

   ## Acceptance criteria / definition of done
   <from the tracker issue or the spec; "none stated" if absent>

   ## Constraints and decisions from linked docs
   <architectural decisions, API contracts, explicit out-of-scope notes>

   ## Sources
   <one line per fetched link: what it contributed>

   ## Not fetched
   <one line per skipped or failed link, with the reason; "none" if empty>
   ```

## Phase 2: load the standards that apply

1. Scan the name and description of every available skill: project `.claude/skills/`, user skills, and plugin skills.
2. Select each skill that would make a reviewer judge a line of this diff differently: architecture, coding principles, testing standards, and domain skills that match the changed files. Leave out workflow and orchestration skills and pure output-formatting skills; pull-request-comment-style belongs to Phase 3, not here. When in doubt, load it: an extra skill costs tokens, a missing standard costs a wrong review.
3. Read the full SKILL.md of each selected skill. A description is not enough to catch violations of the rules inside.
4. Append the digest to `review-context.md`. It is the compact form of the standards that travels into subagent prompts.

   ```markdown
   ## Standards loaded for this review
   - <skill name>: <the 2-3 rules from it most likely to matter for this diff>
   ```

## Phase 3: review with the context, write in house style

1. **Read the code-review and pull-request-comment-style SKILL.md files fresh**, and follow code-review with these standing additions for the whole review:
   - **Judge against intent.** Scope creep, unmet acceptance criteria, and contradictions with linked decisions are findings. They outrank style findings.
   - **Judge against the loaded standards.** A finding names the skill and the rule it violates, so the author can look it up.
   - **Report every real finding**, minor ones included. The merge decision line carries the severity, so there is no reason to drop a finding. Map severity onto it: must fix before merge gets no closing line (blocking is the default), useful but optional gets the suggestion line, context or a plain question gets no closing line. Use no second severity vocabulary and no `blocking:` or `severity:` prefix.
   - **Subagents do not inherit your context.** Paste the full `review-context.md` into every subagent prompt; one uninformed subagent undoes Phases 1 and 2. If a subagent drafts comment text, also paste the whole pull-request-comment-style file. Otherwise, rewrite its findings into the house style yourself.
2. **Choose the delivery mode.**
   - **Summary mode:** no-PR mode, or the PR author is you (`author.login` equals `gh api user --jq .login`). Post nothing to GitHub, because comments on your own PR are notification noise for the team. Deliver the review in chat: the convention line, the two traceability lines, then the findings per file with `path:line`, each in house style with its merge decision line. Post only if the user asks afterwards.
   - **Post mode:** every other PR. Post one batched review with inline comments, the way a human reviewer does. `gh pr review --comment` carries only one body, so use the API:

     ```bash
     gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input review.json
     ```

     ```json
     {"body": "<convention line + traceability lines + findings that fit no single line>",
      "event": "COMMENT",
      "comments": [
        {"path": "src/File.cs", "line": 42, "side": "RIGHT", "body": "<finding, plus the suggestion line when it does not block>"}
      ]}
     ```

     Gotchas:
     - Use `line` and `side` (`RIGHT` for added lines, `LEFT` for removed lines), plus `start_line` and `start_side` for a range. `position` is deprecated.
     - `event` is always `COMMENT`. The merge verdict belongs to the human reviewer; the comments only say which findings block.
     - A batched review does not accept file-level comments. Findings that fit no single changed line (architecture, scope creep, missing tests) go in the body, not on a misleading line.
     - If the call fails after 1 retry, often because an anchor line is outside the diff, post everything with `gh pr review --comment --body-file <file>` and tell the user that inline anchoring failed.
3. **Traceability.** The review body opens with the convention line from pull-request-comment-style, then one line with the PR's intent and one line with the standards skills applied. If code-review's output format has no room for this, put the two lines in the chat message. This lets the user verify that the review used the context.

## When skills conflict

code-review wins on review process. pull-request-comment-style wins on the wording and shape of comments; its "single copyable code block" rule applies only to text the user pastes by hand, not to text you post. This skill wins on context: gathering it and using it is never skipped or reduced.
