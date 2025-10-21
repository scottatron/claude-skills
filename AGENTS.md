# Agent Skills Playbook for Claude Code

This document explains how skills work in Claude Code and how agents should use them effectively.

## 1. How Skills Work

Skills are pre-loaded capabilities that provide specialized domain knowledge and workflows. Each skill is stored as a directory under `~/.claude/skills/` (global) or `.claude/skills/` (project-specific) containing a `SKILL.md` file with YAML frontmatter.

### The Skill Loading Process

1. **Available skills are pre-loaded**: At the start of each conversation, skill metadata (name, description, location) is loaded into `<available_skills>` in your system prompt
2. **You invoke by name**: When a task matches a skill's description, use the Skill tool with just the skill name (e.g., `command: "tracer"`)
3. **Skill prompt expands**: You'll see `<command-message>The "{name}" skill is loading</command-message>` followed by the full skill instructions
4. **Follow the expanded instructions**: The skill's `SKILL.md` content becomes part of your context, providing detailed guidance for the task

### Skill Scopes

- **User skills** (`~/.claude/skills/`): Global skills available to all sessions
- **Project skills** (`.claude/skills/`): Project-specific skills, indicated by "(project, gitignored)" in the location field

## 2. When to Use Skills

### Check Relevance Before Invoking

Before using the Skill tool, compare the user's request against each skill's description in `<available_skills>`:

```
<available_skills>
<skill>
<name>tracer</name>
<description>Manage tasks and dependencies with Tracer CLI. Use for issue tracking, dependency management, finding ready work, and AI agent workflows.</description>
<location>user</location>
</skill>
</available_skills>
```

**Only invoke a skill when**:
- The user's request clearly matches the skill's description
- The skill's description indicates it should be used proactively for certain patterns

**Examples**:
- User: "Help me track this complex feature with dependencies" → Use `tracer` skill
- User: "Set up Node.js version 20 for this project" → Use `mise` skill (if available)
- User: "Write a function to sort an array" → No skill needed

### Proactive Usage

Some skill descriptions indicate they should be used proactively. If a skill says "use this agent after you are done writing a significant piece of code" or similar, invoke it automatically when that condition is met—don't wait for the user to ask.

## 3. Using the Skill Tool

### Basic Invocation

```
Use Skill tool with: command: "tracer"
```

This loads the tracer skill's full instructions into your context.

### Important Rules

- **Only use skills from `<available_skills>`**: Don't try to invoke skills that aren't listed
- **Don't invoke running skills**: If you see `<command-message>tracer is running…</command-message>`, the skill is already loaded—follow its instructions instead
- **Don't use for CLI commands**: The Skill tool is for loading skill instructions, not for running built-in commands like `/help` or `/clear`
- **One skill at a time**: Skills are stateless; each invocation loads fresh instructions

## 4. Working with Skill Instructions

Once a skill is loaded, its `SKILL.md` content provides detailed guidance:

### Follow the Structure

Skills typically include:
- **Overview**: What the skill does
- **Key Features**: Core capabilities
- **Installation**: How to set up required tools
- **Commands**: Specific commands and syntax
- **Workflows**: Step-by-step procedures for common tasks
- **Best Practices**: Recommended patterns
- **Integration tips**: How to use the skill with Claude Code

### Read Referenced Files

Skills may reference additional files:
```markdown
See [FORMS.md](./forms.md) for template details
```

When you encounter these, use the Read tool to access the referenced file:
```
Read: /home/coder/.claude/skills/skillname/forms.md
```

### Execute Skill-Defined Tasks

If a skill documents specific commands or workflows, use those instead of improvising alternatives. This ensures consistent, tested behavior.

**Example from tracer skill**:
```bash
# Skill documents this workflow
tracer ready --json
tracer update test-5 --status in_progress
```

Prefer this documented approach over creating your own task tracking system.

## 5. Common Patterns

### Pattern 1: Check for Skill Applicability

```
User request → Check <available_skills> → Match found → Invoke skill → Follow instructions
```

### Pattern 2: Skill References Tool Usage

Many skills (like `tracer` and `mise`) document CLI tools. When using these:
1. Load the skill to understand the tool
2. Use the tool's commands as documented in the skill
3. Parse JSON output when the skill recommends it (e.g., `tracer ready --json`)

### Pattern 3: Multi-File Skills

Some skills organize content across multiple files:
```
skillname/
  SKILL.md          # Main instructions (loaded when skill invokes)
  reference.md      # Extended reference (read when needed)
  examples.md       # Examples (read when needed)
  scripts/          # Helper scripts (use as directed)
```

Load additional files only when the main SKILL.md instructions reference them.

## 6. Examples from Existing Skills

### Tracer Skill

**When to use**: User needs task tracking, dependency management, or project planning

**How it works**:
1. Invoke: `command: "tracer"`
2. Skill loads and explains Tracer CLI usage
3. Follow documented commands for creating tasks, managing dependencies, finding ready work
4. Use `--json` flags as skill recommends for programmatic parsing

### Mise Skill

**When to use**: User needs to manage tool versions (Node.js, Python, etc.), environment variables, or project tasks

**How it works**:
1. Invoke: `command: "mise"`
2. Skill loads with comprehensive mise documentation
3. Follow installation, configuration, and task runner guidance
4. Use `.mise.toml` patterns as documented

## 7. What Skills Are NOT

- **Not manual discovery**: You don't need to list directories to find skills—they're pre-loaded in `<available_skills>`
- **Not maintenance targets**: You're not expected to update or improve skills during normal operation (leave that to users/developers)
- **Not security audit targets**: Skills in your `<available_skills>` list are pre-vetted; you don't need to audit them before use
- **Not suggestions**: You don't need to suggest creating new skills when patterns repeat (though users may create them)

## 8. Skill Tool vs. Other Tools

Don't confuse the Skill tool with:
- **SlashCommand tool**: For running custom slash commands (e.g., `/review-pr`)
- **Bash tool**: For executing shell commands
- **Task tool**: For launching specialized sub-agents

Each has a distinct purpose—skills provide loaded instructions, not execution.

## 9. Best Practices

### Do:
- Check `<available_skills>` when starting work on a task
- Invoke skills that match the user's request
- Follow skill instructions closely
- Use skill-documented commands and workflows
- Read referenced files when the skill directs you to

### Don't:
- Invoke skills that aren't in your `<available_skills>` list
- Invoke skills speculatively without a clear match
- Re-invoke a skill that's already running
- Use the Skill tool for CLI commands or slash commands
- Improvise solutions when a skill provides the canonical approach

## 10. Summary

Skills in Claude Code are **pre-loaded instruction sets** that you invoke by name when relevant. They expand into your context and provide detailed guidance for specialized tasks. Think of them as expert colleagues you can consult when their domain knowledge applies to the user's request.

The workflow is simple:
1. User makes a request
2. Check if any skill in `<available_skills>` matches
3. If yes, invoke the skill by name
4. Follow the expanded instructions
5. Complete the task using skill-documented approaches

This keeps your behavior consistent, leverages tested workflows, and helps users get reliable results across sessions.
