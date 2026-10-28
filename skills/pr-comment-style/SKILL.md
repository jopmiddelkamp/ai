---
name: pr-comment-style
description: Use when writing or replying to a pull request comment, review comment, or review summary on GitHub, GitLab, Bitbucket, or Azure DevOps, or when a review flow needs findings posted to a PR. Triggers on "PR comment", "review comment", "reply in the thread", "post this on the PR", "draft a review summary", "write a nit", and on Dutch requests such as "schrijf een PR-comment" or "reageer in de thread".
---

# PR comment style

Two rules for every PR comment.

1. **Write it in the ELI5 output style.** Read `../../output-styles/eli5.md`, relative to this skill's base directory, and apply its rules to the comment. Its line "a skill that sets its own format wins" does not apply here: this skill picks that style.
2. **Run the humanizer skill on the draft.** Always, before you output or post the comment.

## Merge decision

Write these lines word for word, so the reader learns them once.

- A comment that blocks the merge ends with: `This blocks the merge.`
- A suggestion ends with: `This is just a suggestion. If you disagree, resolve this comment yourself.`
- A batched review body opens with: `Comments here block the merge unless the comment says it is a suggestion.` Comments in that review that block the merge then need no closing line.

## Comments in Dutch

Write in Dutch when the user asks for it or when the thread is in Dutch. The rule: **Dutch grammar, English terms.** Dutch developers say most technical terms in English. A Dutch replacement such as `samenvoegen` for merge makes the comment harder to read, not easier.

The test for each term: would a Dutch developer say it out loud in English at a standup? Then write the English word.

- **Keep in English:** git and workflow terms (commit, branch, merge, rebase, pull request, PR, review, approve, deploy, release, build, pipeline), code terms (null, string, array, type, callback, hook, state, endpoint, request, response, payload, cache, retry, timeout, race condition), and test terms (unit test, mock, fixture, flaky). Never translate an identifier, a keyword, an error message, or a UI label of a tool.
- **Write in Dutch:** words Dutch developers also say in Dutch: bestand, map, regel, wijziging, functie, waarde, fout, gebruiker, pagina, scherm, aanroep, controle, oplossing.
- **Never write:** samenvoegen (merge), vastleggen (commit), tak or vertakking (branch), samenvoegverzoek (pull request), terugdraaien when the action is a git revert, verzoek (request), antwoord (response).

Conjugate an English verb by the Dutch rules: Dutch endings, `ge-` plus `-t` or `-d` by the 't kofschip rule. Never use the English `-ed` ending alone.

| Verb | Present | Past participle |
|---|---|---|
| committen | hij commit | gecommit |
| pushen | hij pusht | gepusht |
| fixen | hij fixt | gefixt |
| mergen | hij merget | gemerged |
| reviewen | hij reviewt | gereviewd |
| deployen | hij deployt | gedeployd |
| updaten | hij updatet | geüpdatet |

Keep an English noun group apart, as in English: `pull request`, `merge conflict`, `unit test`. Join an English term to a Dutch word with a hyphen when the term is an abbreviation: `PR-beschrijving`, `API-call`.

Use these Dutch merge decision lines, word for word, instead of the English ones:

- Blocks the merge: `Dit blokkeert de merge.`
- Suggestion: `Dit is alleen een suggestie. Ben je het er niet mee eens, resolve deze comment dan zelf.`
- Batched review body: `Comments hier blokkeren de merge, tenzij de comment zegt dat het een suggestie is.`

The ELI5 rules still apply in Dutch: short sentences, one idea per sentence, active voice.

## Output

- A comment the user pastes: one ```text block, or one ```markdown block when it holds a Mermaid diagram. Outside the block, write at most one line.
- A comment you post yourself with gh or the API: the raw text, no fence.
