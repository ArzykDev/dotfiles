---
name: agents-md
description: Conventions for project instruction files. Use when creating, restructuring, bridging, or initializing AGENTS.md / CLAUDE.md files in a repo, or deciding where a project rule should live.
---

# AGENTS.md / CLAUDE.md conventions

`AGENTS.md` is the cross-tool standard (Claude Code, Codex, Cursor, Copilot,
Gemini, Aider…); `CLAUDE.md` is Claude-specific and is what Claude Code reads
natively. Bridge the two rather than duplicating content.

**Respect the repo's existing convention first.** Find the source of truth before
editing: a symlink (`ls -l`) → edit the real target; an `@import` chain → edit the
file holding the content; a hand-maintained duplicate → edit the source and
re-sync the copy (don't convert it to a symlink/import unless asked). Check `git
log`/`.gitignore`/`.git/info/exclude` when unsure; ask if still ambiguous.

**Greenfield default** (new project, or when asked to init one):

- Put the real instructions in `AGENTS.md` at the repo root, and create no
  `CLAUDE.md`: Claude Code's built-in `cc-plugin-agents-md` (on by default)
  loads `AGENTS.md` whenever no `CLAUDE.md` exists. Add a `CLAUDE.md`
  (`@AGENTS.md` on its own line, notes below) only when there are Claude-only
  notes to keep.
- Existing repos keep whatever bridge they already have (symlink or
  `@AGENTS.md` import); don't strip it unless asked.
- Monorepo: a nested `AGENTS.md` per package (nearest in the tree wins).
- Keep `AGENTS.md` under ~150 lines: real, copy-pasteable build/test/lint/run
  commands, testing conventions, project structure, code style, git/PR
  conventions, security gotchas, and a "do not touch" list (generated files,
  secrets, vendored code, migrations). Link out for depth; update it in the same
  change that alters build/test/structure.

Claude-only bits (skills, hooks, settings) go in `.claude/` or `CLAUDE.local.md`,
never `AGENTS.md`.
