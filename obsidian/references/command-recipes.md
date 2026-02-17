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

```bash
obsidian daily
obsidian search query="meeting notes"
obsidian read path="Inbox/TODO.md"
obsidian tasks daily
obsidian tags [counts]
obsidian diff path="Notes/Architecture.md" from=1 to=3
```

Use read-only commands to confirm targets and current content before making edits.

## Write command recipes

```bash
obsidian create name="Weekly Plan" content="# Weekly Plan\n- [ ] Prepare status update"
obsidian daily:append content="- [ ] Review open pull requests"
obsidian vault="Work" create path="Projects/Launch.md" content="# Launch Checklist"
```

Prefer append-oriented updates for incremental edits. Avoid destructive rewrites unless the user asks.

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
