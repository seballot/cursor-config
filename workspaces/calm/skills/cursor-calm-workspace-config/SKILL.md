---
name: cursor-calm-workspace-config
description: >-
  Create or edit Cursor rules, skills, or hooks for the CALM repo. Use when
  adding project rules, agent skills, hooks.json, or anything under .cursor for
  calm — including questions about where those files live.
---

# CALM Cursor workspace config

## Symlink (read this first)

In the CALM git checkout (`/home/sebastian/Work/calm`), **`.cursor` is not a normal folder**. It is a symlink:

```text
/home/sebastian/Work/calm/.cursor  →  /home/sebastian/.cursor/workspaces/calm
```

If you need to create new rules/hooks/skills for CALM project, add them inside `/home/sebastian/.cursor/workspaces/calm` and then commit and push in this `/home/sebastian/.cursor` repository.
