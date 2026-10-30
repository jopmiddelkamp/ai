---
max_turns: 6
allowed_tools: [Skill]
tags: [best-solution, explicit]
---

Use your best-solution skill if you have one. Our team has an internal Dart CLI. Each developer installs it by compiling from their own git checkout of the CLI repo, and everyone keeps that checkout in a different folder. Other agent sessions often work in that same checkout at the same time.

I want to add an `update` command that rebuilds the CLI from the latest release tag. It must never switch branches or touch the working tree of the developer's checkout. The CLI already stores a few team settings under `git config` keys with its own prefix.

How should the update command find and build the source?
