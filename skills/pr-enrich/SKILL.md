---
name: pr-enrich
description: "Follow-up after a pull request is created: read the PR body and its template, carry out every instruction, checklist, and placeholder in it, find or create the linked work item (Trello card, GitHub, Jira, or Linear issue), and update the PR. Use right after any tool opens a PR (gh pr create, gflow, sflow, or bflow finish, az repos pr create, an MCP create-pull-request tool), when a hook says a PR was created, or when the user says '/pr-enrich', 'fill in the PR', 'complete the PR template', 'link a card to this PR'. Not for reviewing a PR or for writing review comments."
metadata:
  optimized-for: "Claude 5.5 models (Opus 5.5, Sonnet 5.5)"
  optimized-on: "2026-10-21"
---

# PR enrich: do what the PR template asks

A PR template is a list of instructions from the team. Tools such as gflow paste it into the body, then leave it. A PR with open placeholders, unticked checklists, and no linked card costs the reviewer time and hides intent. This skill reads the body as a to-do list, does each item, and writes the result back to the PR.

## Standing rules

- **Evidence or leave it open.** Tick a checklist box only after you verified it in this session: a command you ran, a file you read, a diff you checked. Otherwise leave it unticked and list it in the report.
- **Never invent data.** A placeholder you cannot fill from a real source stays open and goes to the user as a question.
- **Keep the template.** Keep headings, order, and HTML comments (`<!-- ... -->`). Replace placeholders and empty sections with content. Do not delete a section because it is hard to fill.
- **Ask before outward writes outside the PR.** Linking a card, commenting on a card, moving a card, and creating a card each need the user's yes. Updating the body of the PR this session just created does not.
- **The user's language for questions, the template's language for the PR.**

## 1. Find the PR

1. Take the PR URL from the output of the tool that created it. gflow prints it next to a banner. Otherwise, on the current branch: `gh pr view --json number,url,title,body,headRefName,baseRefName,isDraft`. On Azure DevOps: `az repos pr list --source-branch "$(git branch --show-current)" --status active`.
2. Skip protected landing PRs of gflow, sflow, or bflow (head branch `landing/*`) and gflow `version/*` PRs. They have an empty body on purpose, unless a `gflow-*.md` template applies.

## 2. Collect the instructions

1. Read the body. If it is empty, look for the template the tool would have used and use that as the instruction list:
   - `.github/pr-templates/<tool>-<key>.md` for `gflow`, `sflow`, or `bflow`, most specific key first (for example `bflow-fix.md`, then `bflow-default.md`)
   - `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, `docs/pull_request_template.md`
   - `.azuredevops/pull_request_template.md`
   - the template folder of any other PR tool in the repo
2. Make a list of every item. Look for:
   - instructions in HTML comments, also with three dashes: `<!-- ... -->`, `<!--- ... -->`
   - placeholders: `{{...}}`, `<...>`, `[...]`, `TODO`, `TBD`, `XXX`, `...`, empty headings, an empty `- ` bullet
   - unfinished links: a URL that ends in `/`, `-`, or `XXX`, such as `issues/` or `browse/BEAN-`
   - checklist boxes: `- [ ]`
   - choice groups: sibling boxes that exclude each other (`Yes` / `No, did not have to`), and boxes nested under one choice, which apply only when that choice is ticked
   - required links: a card, ticket, design, spec, release note, screenshot
3. Sort each item into one class:

| Class | Example | What you do |
|---|---|---|
| fill from the change | summary, motivation, list of changes, breaking changes, migration steps | step 3 |
| verify | "tests pass", "`melos pr` ran successfully", "added migration script: Yes / No" | step 3 |
| pick from the change | "Type of change", the branch prefix (`feature/`, `fix/`) | step 3 |
| linked work item | "Trello card(s):", "GitHub Issue", "Closes #", "Jira:" | step 4 |
| only the user knows | "Tested it myself", "Considered updating the testplan", "approved by design", device screenshots | ask in step 5, with your suggested answer from the diff |
| not applicable | "migration steps" for a change with no migration | write `N/A` with a reason of up to 10 words |

## 3. Fill and verify from the change

Read the real change, not your memory of it: `git log --oneline <base>..HEAD`, `git diff <base>...HEAD --stat`, then the diff of the files that matter.

- Write summaries for a reviewer: why the change exists, what changed, what to look at first, what is out of scope. Short bullets. No marketing words.
- For each verify item, run the check the repo has: the test script, the linter, a `grep` for the forbidden pattern, a look at the docs folder. Tick it only when the check passes. Note the command you ran in the report, not in the PR, unless the template asks for it.
- For a choice group, tick exactly one sibling, the one the diff supports. Example: no file under `release_steps/next/` changed, so tick "No, did not have to" for the migration script. Leave nested boxes of an unticked choice alone.
- A check command can be slow or need a device (`shuttel pr`, `melos pr`). Run it when it is safe to run here. Otherwise ask the user whether it passed.
- If a check fails, leave the box open and tell the user. Do not fix code in this skill unless the user asks.

## 4. Find the linked work item

Run this only when the template asks for a card, ticket, or issue.

### Reach the tracker

Read the tracker through a CLI tool or an MCP server. Never guess a card from memory, and never scrape a web page.

1. Read [trackers.md](trackers.md) in this skill. It maps each known project to its tracker, and each tracker to its routes, with the exact command or tool for every search step and what to do on every failure.
2. Recognize the project from the remote URL and the template. Try its routes in the listed order.
3. If the project, the tracker, or a working route is not in that file, follow its section "Not in this list": find a route yourself, and end the report with the tip to add it.

Use read tools for the search ladder below. Write tools (create, comment, move, attach) are for 4a and 4b, after the user's yes.

### Search ladder

Stop at the first step that gives a confident match.

1. **The user named it.** The conversation or the original task named a card, a URL, or an ID. Use it. Fetch it to confirm it exists and fits.
2. **The branch or commits name it.** An ID or short link in the branch name (`feature/ABC-123-...`) or the commit messages.
3. **Items on the user's name.** The open cards or issues assigned to the user, on the boards or repos of this project.
4. **Open items in the work lanes.** The lanes that hold work to pick up or in progress. [trackers.md](trackers.md) names them per board. For a board it does not list, use names like `To do`, `Ready`, `Doing`, `In progress`, `Sprint`, `Next`, and skip `Done`, `Archive`, and release or version lists.
5. **The backlog.** If the board has no lanes, or nothing matched, search the backlog. Use 3 to 5 keywords from the change: domain nouns, screen names, error messages, component names. Search in the language of the board, which can differ from the language of the code.

Drop closed and done items from every result. Judge a match on content, not on one shared word. A good match describes the same problem or feature as the diff. Spend a limited effort: at most 5 boards or repos and at most 10 searches.

### 4a. Propose

Show the user up to 3 candidates, best first. For each: title, link, list name, and one sentence on why it fits the change. Ask which one to link, or none. Do not link before the user picks.

After the yes:

- Put the link in the PR body where the template asks for it.
- Ask once whether to also add the PR link to the card (a comment or an attachment). Do it only on a yes.

### 4b. Nothing found

Say it plainly: "I could not find a card that fits this change. I searched: <boards, lists, keywords>." Offer two options:

1. The user adds the link by hand.
2. You create a card.

For option 2, draft the card and show it before you create it. Use the structure of the `brief` skill (`ai:brief`), written as a work item:

```
Title: <verb + object, max 8 words>

Task
<one paragraph: action, input, output, purpose, scope>

Guardrails
- <what this work must not touch or do; each one checkable>

Definition of done
- <each criterion with how it is checked>

Pull request: <PR URL>
```

Draft it from the diff and the commits, in the language of the board. It must describe the work that the PR does, not new work. Ask which board and list it goes in; suggest the in-progress or review lane. Create it only after the user approves the text and the place. Then link it in the PR.

## 5. Ask for what only the user knows

Collect all open items of the class "only the user knows" in one message. Ask them as a short numbered list. Put each answer into the PR after the user replies.

## 6. Update the PR

1. Write the new body to a file in the scratchpad directory, then apply it: `gh pr edit <number> --body-file <file>`. On Azure DevOps: `az repos pr update --id <id> --description "$(cat <file>)"`.
2. Read the PR again (`gh pr view <number> --json body`) and confirm the update landed.
3. Do not change the title, the base branch, reviewers, or labels unless the template tells you to.

## 7. Report

End with a short report:

- PR link.
- Filled items.
- Ticked boxes, each with the check that proves it.
- Linked work item, or "none" and why.
- Open items, each with what is needed and from whom.
- One tip line for each tracker route you found outside [trackers.md](trackers.md), as that file describes.
