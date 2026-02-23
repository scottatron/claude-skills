# Obsidian CLI Command Recipes

Source of truth: `https://help.obsidian.md/cli` (verify locally with `obsidian help` because CLI commands are evolving).

## Baseline checks

Run these first in any session:

```bash
command -v obsidian
obsidian help
```

If the CLI command is missing or incomplete, validate Obsidian settings and shell `PATH` before continuing.

## Parameter and targeting model

- Use parameters as `key=value`.
- Quote values that contain spaces.
- Place `vault="<vault-name>"` first when targeting a non-default vault.
- Prefer `path="Folder/Note.md"` over `file=Note` when ambiguity is possible.


## Read-only command recipes

Always wrap CLI calls with a temp file redirect to avoid lost output from the
stdout race condition (see SKILL.md):

```bash
obsidian daily > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
obsidian search query="meeting notes" > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
obsidian read path="Inbox/TODO.md" > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
obsidian tasks daily > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
obsidian tags counts > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
```

Use read-only commands to confirm targets and current content before making edits.

## Write command recipes

CLI write commands can hang indefinitely (see SKILL.md). Prefer direct file
edits using the vault root + relative path. Use CLI writes only when
Obsidian-side processing is needed (e.g., template insertion).

### Reliable write pattern (recommended)

```bash
# 1. Discover paths (with temp file redirect)
obsidian vault > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
# -> name: my-vault, path: /Users/you/my-vault

obsidian daily:path > /tmp/obs_out.txt 2>&1; cat /tmp/obs_out.txt
# -> daily-notes/2026-02-23.md

# 2. Edit the file directly at /Users/you/my-vault/daily-notes/2026-02-23.md
#    using Read/Edit tools instead of CLI write commands.
```

If the redirect hangs, fall back to the background+timeout pattern from
SKILL.md.

### CLI write commands (may hang)

```bash
obsidian create name="Weekly Plan" content="# Weekly Plan\n- [ ] Prepare status update"
obsidian daily:append content="- [ ] Review open pull requests"
obsidian vault="Work" create path="Projects/Launch.md" content="# Launch Checklist"
```

If using CLI writes, always wrap with a temp file redirect or timeout (see
SKILL.md).

## Plugin and developer recipes

```bash
obsidian plugin:reload id="my-plugin"
obsidian dev:screenshot path="/tmp/obsidian.png"
```

Use developer commands only when the user asks for plugin/debugging tasks.

## Troubleshooting checklist

1. Re-run `obsidian help` and adapt to current command names.
2. Confirm CLI is enabled in Obsidian settings.
3. Confirm shell can execute `obsidian` from `PATH`.
4. Reduce to a minimal read-only command in the target vault.
5. If output is missing or truncated, use the temp file redirect pattern.
6. If a command hangs completely, use the background+timeout fallback and fall
   back to direct file edits for writes.
7. On Windows, check for `file.ctime` resets after direct edits (see
   SKILL.md platform caveats).
