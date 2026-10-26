# Claude Code User Settings

Global defaults for every project, on both my Fedora desktop and my MacBook. A
repo's own AGENTS.md/CLAUDE.md and existing tooling always win over what's here.
Platform-specific lines are tagged **(Linux)** or **(macOS)**; everything else
applies to both. Check `uname` rather than assuming which machine you're on.

## Research First — Look Things Up

Model knowledge goes stale; answering from memory about a library, framework,
API, service, or CLI is a bug, not a shortcut. Before writing code against one
or advising on it — even a familiar one — fetch current docs first. Mandatory
when integrating an external API, debugging version-specific behavior, or when
you're about to write "I believe"/"IIRC"/"as far as I know".

- **context7** (`resolve-library-id` → `query-docs`) — library/framework docs,
  API syntax, config, version migration, CLI usage. First stop whenever
  published docs exist.
- **Exa** — everything else on the web: blogs, changelogs, GitHub issues, Stack
  Overflow, releases. WebSearch is disabled, so Exa is the web; use whichever
  Exa server is connected, its search tool to find pages and its fetch/crawl
  tool to read a known URL.

Don't ask permission to look things up, but budget it. Search quota is shared
across the session and its subagents, and it runs out. Beyond a handful of
lookups, estimate the request count first; prefer bulk sources (dataset dumps,
data already local, one list page covering many items) and batch endpoints
over one call per item, and cache results to disk. Never fan per-item searches
out across parallel subagents. If the only route is hundreds of requests to one
service, skip it or ask. Cite what you found (library + version) when it shaped
the code.

## Working with External APIs

Before writing integration code against a third-party API (Simkl, TVDB, Sonarr,
Rebble, etc.), fetch and cite the official API/format docs first. Never guess at
file/JSON import formats — if two attempts fail, switch to the documented REST
API instead of iterating on guesses.

## Debugging

Don't declare a root cause from absence of evidence (no coredump, README-only
inspection, log level defaults). State the hypothesis, name the falsifying test,
run it, then conclude. If I contradict a premise, drop the prior chain entirely
and re-derive rather than patching the old conclusion.

## Planning and Brainstorming

In plan mode or when planning/brainstorming, work interview-style: ask questions
with the AskUserQuestion tool to shape the plan together, iterating on
requirements, constraints, and design — don't present a finished plan upfront.

## Code Comments

Comment sparingly, only the *why*: non-obvious logic, a workaround or quirk, a
deliberate tradeoff, a gotcha. Don't restate code, add section banners, or
narrate the diff. Match the file's existing comment style and density.

## Git and SSH

50/72 conventional commits: title ≤50 chars, body lines ≤72. Plain text only — no
markdown, no bullet points. Commit only the files touched by the current task;
never `git add -A`.

Don't mention my local helper scripts in commit messages or PR descriptions —
ad-hoc scripts on my PATH (e.g. `~/.local/bin`) that aren't part of the repo or
installed system-wide. They mean nothing to anyone else reading the history.

Work on the branch I'm on. Don't create branches or worktrees for routine work
— committing straight to the default branch is fine in my personal repos —
unless I ask, the repo's own docs require a PR flow, or it's a throwaway
experiment.

Signing is per-repo: `git config --get commit.gpgsign` decides. If it's not
`true`, commit normally and don't add `-S` or mention signing at all. Where it
is `true`, commits and SSH auth go through the 1Password agent, which may need
me present to approve. Don't probe it with `ssh-add -l` — it reports "no
identities" even when signing works. Just run the command; if signing fails and
I'm clearly away, commit with `--no-gpg-sign` and note it needs signing later
(`git commit --amend -S`, or `git rebase --exec 'git commit --amend --no-edit
-S' <base>` for several).

For SSH to a host I'll hit more than once, always multiplex — one approval,
then every later connection rides the same socket:

    ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p \
        -o ControlPersist=10m host

## Safety — Proportionate, Not Ceremonial

Match caution to what can actually be lost. Git is the backup for committed
work: don't make backup patches, stashes, or safety branches before ordinary
edits, checkouts, rebasing your own commits, or `git stash pop`. Make a backup
only when an operation would destroy something that exists nowhere else —
uncommitted or untracked work you didn't write, config outside version control,
data with no other copy.

Show the plan and confirm first for: `git reset --hard`, discarding uncommitted
changes, `git clean`, force-push or rewriting pushed history, and any change to
system config or a live session/device.

Delete through the Trash anything not trivially regenerable — **(Linux)**
`trash-put`, **(macOS 15+)** `trash` — and list what you trashed. Plain `rm` is
fine for build output, caches, and temp files you created.

Privileged commands: Bash-tool calls have no TTY, so `sudo` can't prompt. Say
what and why and get approval, then **(Linux)** run it via `pkexec` (polkit
prompts graphically; batch steps as `pkexec sh -c 'a && b'`), **(macOS)** give
me the command to run in my own terminal.

## Secrets in Commands

Hand 1Password secrets to commands only with `op run -- cmd` (`op run
--env-file=.env -- cmd`, or `VAR=op://vault/item/field op run -- cmd`). Never
`op read`, `--no-masking`, or any other path that puts a secret on stdout: `op
run` masks secrets on stdout/stderr, so a mis-wired pipeline fails concealed.

`op inject` is the one fallback, only when a tool truly needs a config file on
disk and can't read an env var: `op inject -i tpl -o file` (writes 0600), never
to stdout. Delete the file when done, keep it out of git.

`op item get` is for metadata only (title, vault, field labels, `op://` refs).
Never pass `--reveal` or `--otp`; concealed fields must stay concealed.

Never pipe a secret into a program that doesn't document a stdin password mode
— it becomes input data and gets echoed back verbatim in the error (`psql`
parses it as SQL, `ssh host` runs it as a remote command). Known-good stdin
modes: `sudo -S`, `docker login --password-stdin`, `gpg --passphrase-fd 0`.
Otherwise use the env var via `op run` (`PGPASSWORD`), or a config file via `op
inject` (`~/.pgpass`, `mysql --defaults-extra-file`).

Never put a secret in argv or a connection URL (`postgres://u:p@host`) — argv
shows up in `ps`, in error text, and in the transcript.

Test the plumbing with a placeholder first, then swap in the real secret. If one
leaks anyway, say so immediately and treat it as needing rotation.

## Pull Requests — Issue-Closing Keywords

GitHub auto-closes a linked issue on merge if the PR body or any commit contains
a closing keyword (`close`, `fix`, `resolve` and their -s/-d forms) followed by
an issue reference (`#123`, `owner/repo#123`, or a URL). Don't use one unless
I've approved it for that specific PR — an issue is usually broader than one
PR. Reference without closing via `Ref`/`Related to`/`Part of`/`See #123`, and
scan any plan or notes pasted into a PR body for a stray "Fixes #42" first.

## General Approach

- Assume familiarity with technical concepts and CLI tools; explain in depth
  without oversimplifying.
- Use the project's own package manager, scripts, formatter, and test commands
  before falling back to the preferences below.

## Subagents

Pick the model by the task, not the session's model. Sonnet is the default for
delegated work — search, file edits, focused refactors, routine analysis. Opus
only for genuinely complex subtasks: intricate multi-file reasoning, subtle
debugging, architecture-level design. Never run subagents or workflow stages as
Fable; the code-review workflow uses Opus at most (Sonnet for lighter stages).

Every brief must tell the agent to:

- not spawn subagents of its own — they nest and multiply;
- write its output file incrementally, not at the end, so a stopped agent loses
  nothing;
- pace network probes — no wide loops of parallel requests at one host;
- stay within an explicit search budget, and mark items as "not researched"
  versus "not found" so a budget gap doesn't look like a real absence.

After parallel work, run a QA pass for consistency across agents. After a
session hiccup, check for duplicate agent sets before trusting completion
reports.

## Project Instructions

Before creating, restructuring, or bridging `AGENTS.md`/`CLAUDE.md` files, load
the `agents-md` skill. When just editing one, find the source of truth first (a
symlink target, or the file an `@import` points to).

## Shell

The Bash tool runs my login shell: bash **(Linux)**, zsh **(macOS default)**.
In bash an unmatched glob passes through as a literal argument; in zsh it
errors. Either way, quote any pattern the *called program* expands (`fd -e py`,
`rg 'foo.*'`, `git log --grep='[A-Z]'`, `uv pip install 'pkg[extra]'`) and
quote `$var`. **(macOS)** Base `sed`, `find`, `date`, `stat` are BSD flavors —
e.g. `sed -i ''` — so prefer portable flags or the tools below.

## CLI Tools

Use whichever builtin tools or shell the harness steers you to; `sed`,
heredocs, and inline Python are fine for edits. When shelling out:

- **Python:** `uv` — `uv run` for scripts (PEP 723 headers / `--with` deps),
  plus project, venv, and version management unless the repo uses another tool.
- **JS/TS lint+format:** `biome` when the project has no eslint config.
- **Search/data:** `rg`, `fd`, `jq`, `yq`.
- Before hand-rolling something a specialized tool would do better
  (benchmarking, LOC stats, disk usage, media probing, format conversion…),
  check what's installed: `command -v <tool>`, `mise ls`, **(macOS)** `brew
  leaves`, **(Linux)** `dnf repoquery --userinstalled`. Use it if present;
  suggest it if missing rather than installing it yourself.

**mise** manages Node, Go, npm, pnpm, yarn — *not* rust/python/bun, which stay
on rustup/uv/bun. A hook injects `mise env` for the current directory into every
Bash call, so run project commands directly (`npm test`, no `mise exec`).
Gotcha: within a single compound call, `cd sub && cmd` still has the pre-`cd`
env — `cd` in its own call first, or use `cd sub && mise x -- cmd`.
