# Reference Index

One-line summary of every file in `references/`. Use this to decide what to load. **Do not load files speculatively** — load what the user's specific question needs.

## Core operating references (use most often)

| File | What's in it |
|---|---|
| `frameworks/cheatsheet.md` | Single-page index of every named framework grouped by domain. **Start here** when you don't yet know which framework applies. |
| `lookups/patterns.md` | Named anti-patterns (Technician's Trap, Founder Bottleneck, etc.) with book citations and rules of use. |
| `lookups/stats.md` | Citable statistics paired with their sources and how to use each one. |
| `lookups/scripts.md` | Word-for-word conversation scripts: Radical Candor, Mom Test, price increase, Challenger reframe, Ackerman, Accusation Audit. |
| `lookups/benchmarks.md` | Specific thresholds: LTV:CAC, gross margins, revenue concentration, buyback rate, offer score, Profit First allocations, Keeper Test, GWC. |

## Response calibration

| File | What's in it |
|---|---|
| `response-format.md` | Quick-reference card for the response shape and the 7 Signature Moves. Companion to SKILL.md. |
| `sample-answers.md` | 20 worked example answers at the minimum quality bar. **Read at least one example before your first response in a session** to calibrate tone and depth. |
| `commands-index.md` | Catalog of the 21 slash commands shipped by this plugin (15 direct + 5 category + 1 master). Useful when the user asks "what can I do here?" or wants to discover a structured workflow. |
| `synthesis.md` | The 10 universal laws that emerge from all the books — a one-page meta-summary. Use when the user wants the big picture, not a specific framework. |

## Problem playbooks

| File | When to load |
|---|---|
| `playbooks/cant-get-customers.md` | User describes a dry pipeline, weak conversion, or stalled growth. |
| `playbooks/founder-bottleneck.md` | User is the constraint: decisions wait, quality drops without them, no time for strategy. |
| `playbooks/all-problems.md` | Comprehensive problem diagnostics. Load **only when** neither of the specific playbooks above fits. Long file — don't load unless needed. |

## Stage playbooks

All five stage files live in `stages/`.

| File | When to load |
|---|---|
| `stages/01-idea-stage.md` | Pre-revenue. Validation, customer discovery, MVP decisions. |
| `stages/02-early-stage.md` | $0–$1M. First sale to first million. Repeatable sales, cash discipline, first hire. |
| `stages/03-growth-stage.md` | $1M–$10M ("Valley of Death"). Systems, delegation, transitioning out of operator role. |
| `stages/04-scaling-stage.md` | $10M+. Institutionalizing culture and operating system; founder leads leaders, not the work. |
| `stages/05-acquisition-stage.md` | Buying a business. Sourcing → DD → deal structure → first 90 days post-close. |

## Framework deep dives

| File | When to load |
|---|---|
| `frameworks/overview.md` | Visual/structural breakdowns of every named framework. Use when the user asks **how a specific framework works**. |
| `frameworks/deep.md` | Extended notes on the same frameworks with more application detail. Load **instead of** the above when the user needs operational depth, not just structure. |

## Book deep dives

Every book has its own file in `books/`. Load **only the book(s) directly relevant** to the user's question. Filename = book title slugified (e.g. *The Mom Test* → `books/the-mom-test.md`, *$100M Offers* → `books/100m-offers.md`).

**91 book files total.** Some files contain merged sections from multiple original deep-dive entries on the same book (e.g. `principles.md` contains both the radical-transparency framework and the principle list; `the-mom-test.md` contains both the discovery questions and the advanced B2B applications). Sections are separated by `---` inside the file.

Quick locator for the most-cited books:

| Domain | Books to know |
|---|---|
| Strategy & vision | `good-to-great.md`, `playing-to-win.md`, `zero-to-one.md`, `your-next-five-moves.md`, `the-innovators-dilemma.md`, `think-again.md`, `good-strategy-bad-strategy.md`, `the-art-of-war.md`, `the-infinite-game.md`, `choose-your-enemies-wisely.md`, `blue-ocean-strategy.md` |
| Offers, pricing & sales | `100m-offers.md`, `100m-leads.md`, `never-split-the-difference.md`, `obviously-awesome.md`, `influence.md`, `crossing-the-chasm.md`, `fanatical-prospecting.md`, `start-with-why.md`, `dotcom-secrets.md`, `building-a-storybrand.md`, `spin-selling.md`, `monetizing-innovation.md`, `the-challenger-sale.md` |
| Customer discovery & validation | `the-mom-test.md`, `the-lean-startup.md`, `hooked.md`, `four-steps-to-the-epiphany.md` |
| Communication & messaging | `made-to-stick.md`, `building-a-storybrand.md`, `how-to-win-friends-and-influence-people.md` |
| Operations & scaling | `traction.md`, `scaling-up.md`, `the-e-myth-revisited.md`, `buy-back-your-time.md`, `profit-first.md`, `blitzscaling.md`, `measure-what-matters.md`, `the-great-game-of-business.md`, `the-4-hour-workweek.md` |
| People & culture | `the-five-dysfunctions-of-a-team.md`, `radical-candor.md`, `multipliers.md`, `culture-code.md`, `no-rules-rules.md`, `crucial-conversations.md`, `the-hard-thing-about-hard-things.md`, `surrounded-by-idiots.md`, `emotional-intelligence.md` |
| Leadership | `turn-the-ship-around.md`, `dare-to-lead.md`, `the-21-irrefutable-laws-of-leadership.md`, `leaders-eat-last.md`, `extreme-ownership.md` |
| Mindset, focus & habits | `atomic-habits.md`, `deep-work.md`, `essentialism.md`, `the-one-thing.md`, `grit.md`, `cant-hurt-me.md`, `mindset.md`, `the-compound-effect.md`, `high-performance-habits.md`, `the-obstacle-is-the-way.md`, `mans-search-for-meaning.md`, `the-miracle-morning.md`, `die-empty.md`, `the-alchemist.md`, `becoming.md`, `when-breath-becomes-air.md` |
| Money & wealth | `the-psychology-of-money.md`, `profit-first.md`, `main-street-millionaire.md`, `the-5-types-of-wealth.md`, `die-with-zero.md`, `rich-dad-poor-dad.md`, `the-millionaire-next-door.md`, `the-simple-path-to-wealth.md`, `i-will-teach-you-to-be-rich.md`, `set-for-life.md` |
| Marketing, persuasion & relationships | `contagious.md`, `never-eat-alone.md`, `give-and-take.md`, `unreasonable-hospitality.md`, `how-to-win-friends-and-influence-people.md` |
| Decision-making & thinking | `principles.md`, `thinking-fast-and-slow.md`, `predictably-irrational.md`, `same-as-ever.md`, `the-almanack-of-naval-ravikant.md`, `shoe-dog.md`, `the-founders-dilemmas.md`, `the-platform-revolution.md`, `thinking-in-bets.md` |

For the complete list, run `ls references/books/`.

## Routing rules

1. **Almost every session:** load `frameworks/cheatsheet.md` first.
2. **Specific problem mentioned:** load the matching playbook (`playbooks/cant-get-customers.md` or `playbooks/founder-bottleneck.md`) if it fits; otherwise `playbooks/all-problems.md`.
3. **Stage known:** load the matching stage playbook.
4. **Specific framework asked about:** load `frameworks/overview.md`; escalate to `frameworks/deep.md` only if structure isn't enough.
5. **Specific book asked about:** load `books/<book-slug>.md` directly.
6. **Hard conversation:** load `lookups/scripts.md`.
7. **Numbers / thresholds requested:** load `lookups/benchmarks.md` and/or `lookups/stats.md`.

**Do not load every file. Be surgical.** A pricing question needs `lookups/benchmarks.md` + `books/100m-offers.md`. A team conflict needs `lookups/scripts.md` + `books/the-five-dysfunctions-of-a-team.md` + `books/radical-candor.md`.
