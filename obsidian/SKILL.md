---
name: obsidian
description: "Automate Obsidian desktop workflows through the Obsidian CLI: create, read, search, and update notes; run daily-note and task commands; target specific vaults/files; and use plugin/developer commands. Use when a user asks to operate an Obsidian vault from terminal commands, script repeatable note workflows, or troubleshoot Obsidian CLI setup."
---

# Obsidian CLI

## Run non-interactive commands

Use one-shot commands instead of the interactive TUI unless the user explicitly asks for interactive mode.

1. Confirm command availability with `command -v obsidian`.
2. Inspect available commands with `obsidian help`.
3. When syntax is uncertain, re-run `obsidian help` and review the command list before writing content.

## Follow a safe execution flow

1. Resolve targeting first.
- If the user specifies a vault, place `vault="<vault-name>"` first.
- If the user specifies a file, prefer `path="Folder/Note.md"` for exact targeting.
2. Prefer read-only commands before writes (`read`, `search`, `tasks`, `tags`, `diff`).
3. Apply minimal edits.
- Prefer append/prepend style changes when possible instead of full replacements.
4. Return useful command output in the response.

## Use command syntax correctly

Use `key=value` parameters. Quote values containing spaces. Use flags without values.

```bash
obsidian create name="Sprint Notes" content="# Sprint\n- [ ] Draft plan"
obsidian search query="release checklist"
obsidian daily:append content="- [ ] Follow up with design"
obsidian vault="Work" read path="Projects/Agent Skills.md"
```

## Troubleshoot quickly

1. Treat the CLI as early access and expect command/syntax drift.
2. If a command fails unexpectedly, re-run `obsidian help` and adapt to the installed command set.
3. If CLI commands are unavailable, instruct the user to enable `Settings -> General -> Command line interface` in Obsidian and register again.
4. On macOS, ensure `/Applications/Obsidian.app/Contents/MacOS` is in `PATH` (commonly via `~/.zprofile`).

## Read detailed recipes on demand

Load `references/command-recipes.md` for concrete command recipes and troubleshooting patterns.
