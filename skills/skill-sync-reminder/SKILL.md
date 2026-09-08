---
name: skill-sync-reminder
description: "Claude.ai skills and Claude Code skills are separate stores that do not sync. Use this skill EVERY time a skill is created, edited, improved, packaged, renamed, or deleted in this conversation — including whenever the skill-creator skill runs, whenever the user says 'edit the X skill', 'update this skill', 'make a skill', or whenever a .skill file is produced. Also use it when the user mentions having changed a skill in Claude Code or in the beans-claude-config repo. This skill defines the sync reminder that must close the final response."
---

# Skill Sync Reminder

The user runs the same custom skills in two places: claude.ai (uploaded to the profile) and Claude Code (loaded from the filesystem via the beans-claude-config repo and symlinks). The two stores do not sync in either direction. Any change in one store silently forks the other. The user's policy: **beans-claude-config is the single source of truth; claude.ai is a deploy target.**

## When a skill changes in claude.ai (this conversation)

1. Do the requested skill work first. Never block or shorten it because of this reminder.
2. Make every changed file downloadable: present the updated SKILL.md and any changed bundled resources (scripts, references).
3. End the final message of the task with one short sync block:

   ```text
   Sync reminder — only the claude.ai copy changed.
   Changed skills: <exact names>.
   Commit the downloaded files to beans-claude-config/skills/<name>/ — Claude Code picks the change up through the existing symlinks.
   ```

4. If a changed skill references other skills (example: review-pr references code-review and pull-request-comment-style), add one line telling the user to verify those referenced skills exist on the Claude Code side.

## When a skill changed in Claude Code or beans-claude-config

Remind the user that the claude.ai copy is now stale. To update claude.ai: zip the skill folder (or package it as a .skill file) and upload it in claude.ai under Settings > Capabilities > Skills, replacing the old version.

## Rules

- One reminder per changed skill set, at the end of the final message. Do not repeat it every turn of the conversation.
- Never skip the reminder because a change is small. A stale copy of a small change is still a fork.
- Name the exact skills that changed. A generic "remember to sync" line is not actionable.
