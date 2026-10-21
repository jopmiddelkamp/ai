# Trackers

The known projects and the tools that reach their work items. This list is a starting point, not a limit: see "Not in this list" at the end.

Tested read-only on 2026-10-21. "Unverified" marks a step that did not run against live data.

## Projects

Recognize the project from `git remote get-url origin` or from the PR template.

| Project | Remote contains | PR tool | Tracker | Template asks for |
|---|---|---|---|---|
| Shuttel | `stream-bv/shuttel-app` | `sflow`, templates `.github/pr-templates/sflow-<key>.md` | Trello, board "Shuttel App development" | `## Trello card(s):` with an empty `- ` bullet |
| Beans | `Beans-BV/` | `gflow` in a repo with a `.gflow/` directory; `bflow` in a repo not migrated yet | GitHub issues, in the repo of the PR | `[GitHub Issue](https://github.com/Beans-BV/<repo>/issues/)` with the number missing |
| any other | — | `gflow` | not known: see "Not in this list" | — |

`sflow` and `gflow` are custom gitflow CLI tools. `bflow` is the Beans version that `gflow` grew out of; the Beans repos are moving from `bflow` to `gflow`. Each tool prints the PR URL when it opens a PR and reads its own templates: `.github/pr-templates/<tool>-<key>.md`. Use the templates of the tool that opened the PR. In a Beans repo with both sets, use the `gflow-*.md` ones only when `gflow` opened the PR.

## Trello

Route order: the Trello CLI, then the Trello MCP server. When the `using-trello-cli` skill is installed, load it before you use the CLI.

### Trello CLI

Every command returns `{"ok": true, "data": ...}` or `{"ok": false, "error": {...}}`. Branch on `ok`. Never guess an ID; discover it first.

| Step | Command |
|---|---|
| ready? | `trello auth status`: go on only when `data.configured` is `true` |
| fetch one card | `trello cards get --card <id>` |
| boards | `trello boards list` |
| lanes | `trello lists list --board <board-id>`, then `trello cards list --list <list-id>` |
| search | `trello search cards --query "<keywords>"` |
| write, after a yes | `trello comments add --card <id> --text <text>`, `trello attachments add-url --card <id> --url <pr-url>`, `trello cards create --list <list-id> --name <name> --desc <text>` |

Unverified: the CLI was not logged in on 2026-10-21.

### Trello MCP server (`trello`)

Pass `apiKey` and `token` as empty strings; the server uses its stored credentials.

| Step | Tool |
|---|---|
| fetch one card | `get_card` |
| boards | `list_boards` |
| lanes | `get_lists`, then `trello_get_list_cards` per list |
| search | `trello_search` with `modelTypes: ["cards"]` and `boardIds` set to the project board |
| write, after a yes | `trello_add_comment`, `create_card` |

Search returns closed cards and cards in done lanes too. Drop every card with `closed: true` or in a skipped lane.

The "user's cards" step is unverified: `trello_search` with `@me is:open` returned 0 cards. If it gives nothing, go on to the lanes.

### Shuttel board lanes

The board is in Dutch. Write card text in Dutch.

| Use | Lists |
|---|---|
| work lanes, search first | `Ready for dev`, `In progress`, `Dev Test`, `Waits on back end`, `Input <version>`, `Testbevindingen rel <version>` |
| backlog, search second | `Backlog`, `Back log > 12mnd` |
| skip | `Dev done`, `Done`, version lists such as `4.4` and `4.3 hotfix` |
| new card goes to | `In progress` (suggest it; the user picks) |

## GitHub issues

Route: the `gh` CLI. Check `gh auth status` first.

| Step | Command |
|---|---|
| fetch one issue | `gh issue view <n> -R <owner>/<repo> --json number,title,state,url,body` |
| the user's issues | `gh issue list -R <owner>/<repo> --assignee @me --state open --json number,title,url` |
| lanes (GitHub Projects) | `gh project item-list <number> --owner <owner> --format json` |
| search | `gh search issues --owner <owner> --state open <keywords> --json repository,number,title,url` |
| write, after a yes | `gh issue comment <n> -R <owner>/<repo> --body <text>`, `gh issue create -R <owner>/<repo> --title <title> --body <text>` |

GitHub Projects needs the `read:project` scope. Without it, skip the lanes step and tell the user to run `gh auth refresh -s read:project`.

Search across the whole owner: a Beans change in `beans-app` can belong to an issue in `beans-api`.

Fill the template link as the full URL: `https://github.com/Beans-BV/<repo>/issues/<n>`.

## Failures

| State | Tell the user | Next step |
|---|---|---|
| CLI not installed | "`<cli>` is not installed." | Try the next route. |
| CLI not logged in | "`<cli>` is not logged in. Run `<login command>`." | Try the next route. |
| MCP server failed or needs authorization | "MCP server `<name>` failed to connect" or "needs authorization in `/mcp`". | Try the next route. |
| Token misses a scope | The exact refresh command, for example `gh auth refresh -s read:project`. | Skip that step only. |
| No route works | "I cannot reach `<tracker>` from this session. I tried: <routes>." | Go to "Nothing found". You can draft a card, but not create it. |
| Every route works, zero matches | What you searched: boards, lists, keywords. | Go to "Nothing found". |

Never fall back to scraping a web page.

## Not in this list

A project, tracker, or tool that is not in this file is still in scope.

1. Find the tracker from the template, the links in the PR body, and the repo docs.
2. Look for a route: MCP tool names that contain the tracker name, a CLI on `PATH` (`command -v`), and an installed skill for that tracker.
3. Use the first route that works, with read tools only until the user says yes.
4. In the final report, add one line for each route you found yourself: "Tip: `<tool>` worked for `<tracker>` in `<project>`. Add it to `skills/pr-enrich/trackers.md` in the ai repo for best results."

Give the same tip when a route listed here fails in a way this file does not describe.
