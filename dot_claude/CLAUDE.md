# Claude Code User Settings

Global defaults for every project. A repo's own AGENTS.md/CLAUDE.md and existing
tooling always win over what's here.

## Research First — Look Things Up

Model knowledge goes stale. Look up current docs before writing code or advising
on any library, framework, API, service, or CLI — even familiar ones — and
especially when integrating an external API, debugging version-specific behavior,
or about to say "I believe"/"IIRC".

- **context7** — library/framework docs, API syntax, config, version migration,
  CLI usage. Prefer over web search when published docs exist.
- **Exa** — broader web research (blogs, changelogs, GitHub issues, Stack
  Overflow, releases). Prefer over WebSearch; fall back to WebSearch only if Exa
  doesn't have it.

## Planning and Brainstorming

In plan mode or when planning/brainstorming, work interview-style: ask questions
with the AskUserQuestion tool to shape the plan together, iterating on
requirements, constraints, and design — don't present a finished plan upfront.

## Code Comments

Write sparingly; let clear names and straightforward code speak. Comment only
where it earns its place: non-obvious or complex logic, the *why* of a
fix/workaround/quirk, a deliberate tradeoff or constraint, or a gotcha/side
effect. Don't restate code, add section banners, narrate the diff ("renamed
from…", "now also handles…"), or write redundant docstrings. Keep it to a line
where you can; match the file's existing comment style and density.

## Git Commits

50/72 conventional commits: title ≤50 chars, body lines ≤72. Plain text only — no
markdown, no bullet points.

## Pull Requests — Issue-Closing Keywords

GitHub auto-closes a linked issue on merge if the PR body OR any commit contains a
closing keyword (`close`/`closes`/`closed`, `fix`/`fixes`/`fixed`,
`resolve`/`resolves`/`resolved`) followed by an issue reference (`#123`,
`owner/repo#123`, or a full URL). Treat these as side-effectful:

- Don't use a closing keyword unless I've approved it for that specific PR — an
  issue is usually broader than one PR, so closing it on merge is often wrong.
- To reference without closing, use plain `#123` or `Ref`/`Related to`/`Part
  of`/`See #123`.
- Before pasting a plan, task list, or notes into a PR body, scan it and
  neutralize any stray "Fixes #42"-style line first.

## General Approach

- Assume familiarity with technical concepts and CLI tools; explain in depth
  without oversimplifying.
- Prefer efficient, modern tooling.
- Use the project's own package manager, scripts, formatter, and test commands
  before falling back to the global preferences below.

## Project Instructions — Prefer AGENTS.md

`AGENTS.md` is the cross-tool standard (Claude Code, Codex, Cursor, Copilot,
Gemini, Aider…); `CLAUDE.md` is Claude-specific and is what Claude Code reads
natively. Bridge the two rather than duplicating content.

**Respect the repo's existing convention first.** Find the source of truth before
editing: a symlink (`ls -l`) → edit the real target; an `@import` chain → edit the
file holding the content; a hand-maintained duplicate → edit the source and
re-sync the copy (don't convert it to a symlink/import unless asked). Check `git
log`/`.gitignore`/`.git/info/exclude` when unsure; ask if still ambiguous.

**Greenfield default** (new project, or when asked to init one):

- Put the real instructions in `AGENTS.md` at the repo root.
- Bridge `CLAUDE.md` to it: symlink `ln -s AGENTS.md CLAUDE.md` (preferred on
  macOS/Fedora — zero maintenance), or a `CLAUDE.md` containing `@AGENTS.md` on
  its own line when you also want Claude-only notes below the import.
- Monorepo: a nested `AGENTS.md` per package (nearest in the tree wins); bridge
  each only if a tool there needs `CLAUDE.md`.
- Keep `AGENTS.md` under ~150 lines: real, copy-pasteable build/test/lint/run
  commands, testing conventions, project structure, code style, git/PR
  conventions, security gotchas, and a "do not touch" list (generated files,
  secrets, vendored code, migrations). Link out for depth; update it in the same
  change that alters build/test/structure.

Claude-only bits (skills, hooks, settings) go in `.claude/` or `CLAUDE.local.md`,
never `AGENTS.md`.

## Preferred CLI Tools

Builtin `Grep`/`Glob`/`Read` beat shelling out for search/find/read — structured
results, no shell-quoting traps, no ANSI cost. Reach for a CLI tool when a builtin
doesn't fit (shell pipelines, type/time filters, exec-per-result) or for my own
interactive terminal.

| Tool | Use for |
| --- | --- |
| `fd` | finding files beyond name match — type/mtime filters, `-x` per result |
| `eza` | enhanced `ls` (git status, `eza --tree`) |
| `dua` | fast disk usage, non-interactive (`dua /path`) |
| `jq` / `yq` | JSON / YAML-TOML in shell pipelines |
| `xh` | HTTP requests instead of `curl` (JSON by default) |
| `tokei` | lines-of-code stats |
| `hyperfine` | benchmarking/comparing command performance |
| `biome` | JS/TS lint+format when a project has no eslint config (else use eslint) |
| `uv` | Python: `uv run` for scripts (PEP 723 headers / `--with` deps), plus project, venv, and version management unless the repo uses another tool |

**mise** (polyglot version manager in use; manages Node, Go, npm, pnpm, yarn —
*not* rust/python/bun, which stay on rustup/uv/bun). Reads `mise.toml` and
idiomatic files (`.node-version`/`.nvmrc`/`.tool-versions`); global versions
live in `~/.config/mise/config.toml`. `mise activate`'s directory hook only
fires in an *interactive* shell, so a non-interactive `cd dir && …` keeps the
global tool version — often a newer major than the project pins, causing odd
test/build failures (e.g. `localStorage.getItem is not a function`). Guard
project commands with `mise exec --` (alias `mise x --`), e.g. `cd path/to/pkg
&& mise exec -- npm run test`.
