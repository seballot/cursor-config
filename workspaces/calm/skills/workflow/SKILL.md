---
name: workflow
description: >-
  Workflow for calm tickets. Use when starting or finishing a
  Redmine issue/ticket. Triggers on
  ticket numbers (e.g #1234), redmine.calm.dhamma.org links
---

# Workflow (Redmine + Git)

## 0. Before starting anything

Checklist read → start → branch before first edit.

- [ ] `script/redmine-read-issue <id-or-url>` — Read ticket. See also attachments under `tmp/redmine/<id>/`
- [ ] `script/redmine-start-issue <id-or-url>` - start redmine
- [ ] `git checkout -b nom-de-la-branche <id>-<slug> origin/master`

## 1. Delivery

When the code work is ready:

1. **Do not** `git commit`
2. Summarize changes in chat.
3. **Stop and wait** for an explicit user go.

## 2. User gates

1. **Go pour commit / commit** — `git commit` (use prepared `COMMIT_EDITMSG` if still valid), push only if asked
2. **Open PR / go PR** — **create-pr** skill, then immediately **address-pr-review** skill on that PR
3. While waiting for PR review, restrospective on the current session, let me know if you struggled when using some tools or commands
4. **merge the PR / merge is done** — merge the PR and run `script/redmine-mark-issue-as-solved <issue> <pr-url>`
