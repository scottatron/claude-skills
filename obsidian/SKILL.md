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

## Handle CLI commands that hang

The Obsidian CLI communicates with the running desktop app via Electron IPC.
Two known issues cause commands to hang or lose output:

1. **stdout race condition** — the CLI process can signal exit before stdout
   is fully flushed, causing agent harnesses to miss output.
2. **IPC connection failure** — the CLI can fail to connect to the running
   Obsidian instance and spawn a new Electron process instead, hanging
   indefinitely with no output.

### Primary pattern: temp file redirect

Redirect output to a temp file so it is captured even if the process exits
before flushing stdout:

```bash
obsidian <command> > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
```

### Fallback: background with timeout

If the temp file redirect also hangs (IPC failure), use a background process
with a kill timer:

```bash
obsidian <command> > /tmp/obs_out.txt 2>&1 &
PID=$!
sleep 10
kill $PID 2>/dev/null
wait $PID 2>/dev/null
cat /tmp/obs_out.txt
```

## Prefer direct file edits for writes

CLI write commands (`append`, `prepend`, `create`, `daily:append`) are the
most likely to hang. A more reliable pattern:

1. Use `obsidian vault` to get the vault root path.
2. Use `obsidian daily:path` (or `obsidian read path=...`) to get the
   relative file path.
3. Construct the full path (`<vault_root>/<relative_path>`) and use the
   Edit/Read tools to modify the file directly.

Reserve CLI write commands for cases where Obsidian-side processing is needed
(e.g., template insertion, plugin triggers).

## Platform caveats

- **Windows**: Direct file edits via external tools (Node.js `CREATE_ALWAYS`)
  can reset `file.ctime`, breaking creation-date queries in Obsidian. If the
  vault relies on `file.ctime`, preserve a `date created` frontmatter
  property and use a hook to restore ctime after edits.
- **macOS / Linux**: Not affected by the ctime issue. Direct file edits are
  safe.

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
