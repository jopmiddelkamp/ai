# Commands Index

The business-coach plugin ships **21 slash commands** — structured-session templates the user can invoke directly. These replace the old paste-and-edit "power prompts": each one is now a real slash command Claude Code surfaces in the `/` menu.

All commands live under the `business-coach` plugin namespace, so they appear as `/business-coach:<name>` in the CLI.

---

## Quick entry points

| Goal | Command |
|---|---|
| Not sure where to start? | **`/business-coach:start-here`** — two-step master menu |
| Want the full 2-hour session | **`/business-coach:full-strategy-session`** |
| Browse by topic | `/business-coach:strategy-and-planning` · `/business-coach:people-and-hiring` · `/business-coach:sales-and-revenue` · `/business-coach:money-and-finance` · `/business-coach:mindset-and-leadership` |

---

## All 15 direct commands

### Strategy & Planning
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:plan-the-year` | Build a rigorous year plan: WIG, annual Rocks, Q1 Rocks, scorecard, #1 hire | Traction/EOS + 4DX |
| `/business-coach:plan-90-days` | 90-day focused execution plan: WIG, lead measures, Week 1 actions, risks | 4DX |
| `/business-coach:should-i-pivot` | Should you pivot? Four-framework verdict + recommendation | Playing to Win + Good to Great + Zero to One + Innovator's Dilemma |

### People & Hiring
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:should-i-hire` | Hire or not? Buyback-rate math, ROI, clear recommendation | Buy Back Your Time |
| `/business-coach:plan-hard-conversation` | Plan a difficult conversation; word-for-word draft + pushback responses | Radical Candor + Crucial Conversations |
| `/business-coach:team-not-performing` | Why isn't the team performing? Diagnosis + 30-day reset plan | Five Dysfunctions + Traction + Multipliers + Culture Code |

### Sales & Revenue
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:build-offer` | Build an irresistible offer; stack, guarantee, price, one-sentence pitch | $100M Offers (Value Equation) |
| `/business-coach:design-sales-script` | Build the sales conversation; opening, discovery, reframe, close | Never Split the Difference + The Challenger Sale |
| `/business-coach:optimize-pricing` | Three pricing scenarios with recommendation | $100M Offers + Influence + Playing to Win |

### Money & Finance
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:cash-flow-crisis` | Triage a cash flow crisis; 90-day survival plan + prevention | Profit First + Main Street Millionaire |
| `/business-coach:should-i-buy-business` | Should you buy this business? SDE multiple, risks, deal structure, go/no-go | R.I.C.H. (Main Street Millionaire) |

### Mindset & Leadership
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:founder-burnout-reset` | 2-week reset plan when burned out / lost | Frankl + Holiday + 5 Types of Wealth + Bet-David + Martell |
| `/business-coach:make-hard-decision` | Make a major decision; 5-move-ahead analysis + clear pick | Kahneman + Bet-David + Dalio + Holiday |
| `/business-coach:plan-the-week` | Plan the week: Deep Work blocks, the ONE thing, daily schedule | Deep Work + The One Thing + Buy Back Your Time |

### Full Session
| Command | What it does | Frameworks |
|---|---|---|
| `/business-coach:full-strategy-session` | The full 2-hour strategy session — diagnosis, 3 frameworks, 30-day plan, ONE first thing, ONE thing to stop | Cross-cutting (uses the full reference library) |

---

## 5 category menus

| Command | Surfaces |
|---|---|
| `/business-coach:strategy-and-planning` | plan-the-year · plan-90-days · should-i-pivot |
| `/business-coach:people-and-hiring` | should-i-hire · plan-hard-conversation · team-not-performing |
| `/business-coach:sales-and-revenue` | build-offer · design-sales-script · optimize-pricing |
| `/business-coach:money-and-finance` | cash-flow-crisis · should-i-buy-business |
| `/business-coach:mindset-and-leadership` | founder-burnout-reset · make-hard-decision · plan-the-week |

---

## 1 master menu

| Command | What it does |
|---|---|
| `/business-coach:start-here` | Two-step menu: category → workflow. Start here if you're not sure where to go. |

---

## When to use a command vs. just ask a question

- **Use a command** when you want a *structured deliverable* (a 90-day plan, a pricing recommendation, a word-for-word conversation draft). Commands enforce a specific workflow with specific outputs.
- **Just ask a question** ("I'm stuck at $800K and everything goes through me — what do I do?") when you want the conversational coach. The auto-triggered `business-coach` skill handles those.

Both modes draw from the same reference library (`references/`).
