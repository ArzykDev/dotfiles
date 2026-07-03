---
name: simplify-comments
description: >-
  Audit and clean up the comments in a code change — trim over-verbose comments,
  delete redundant ones that only restate self-explanatory code, drop comments
  left on trivial 1–2 line changes, and fix or flag stale comments whose wording
  no longer matches the code after a logic change. Use after writing or editing
  code and before committing, and whenever the user asks to "simplify", "clean
  up", "trim", or "prune" comments, mentions over-commenting, or wants the
  comments reviewed on a diff, branch, or PR. Operates on the current change set
  (uncommitted work, or the branch vs its base) rather than the whole repo.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
---

# Simplify Comments

Models tend to over-comment: they narrate self-explanatory code, restate what a
line already says, and leave verbose block comments that outlive the code they
described. This skill reviews only the comments touched by a change and makes
them earn their place — trimming, removing, or correcting them — without
rewriting the code itself.

The bar for keeping a comment is the same one in the user's global `CLAUDE.md`
"Code Comments" section: a comment earns its place only when it explains
non-obvious logic, the *why* behind a fix/workaround/quirk, a deliberate
tradeoff, or a gotcha/side effect. Defer to that philosophy — don't restate it,
apply it.

## 1. Scope the change

Figure out what changed, then look only at those regions. Auto-detect by default:

```bash
# Uncommitted work first (working tree + staged, vs HEAD)
git diff HEAD --unified=3
```

If that diff is empty, fall back to the whole branch vs its base:

```bash
# Detect the base branch (origin/HEAD, else main, else master)
base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
base=${base:-$(git rev-parse --verify --quiet main >/dev/null && echo main || echo master)}
git diff "$base"...HEAD --unified=3
```

Honor an explicit scope if the user gave one: a base ref ("vs develop"), "staged
only" (`git diff --staged`), or specific files/paths — use that instead of
auto-detecting.

## 2. Decide what to examine

Look at **every comment inside a changed hunk** — both comments the diff added
*and* pre-existing comments sitting next to changed code. The latter matters
because when the logic under a comment changes, the comment often silently goes
stale. Read enough surrounding code (the whole function, not just the `+` lines)
to judge whether each comment is still true and still useful.

Leave comments in unchanged regions alone. This skill cleans up a change; it is
not a repo-wide comment sweep.

## 3. Apply the judgment

For each comment in scope, do one of:

- **Keep** — it explains a non-obvious *why*, a gotcha, a tradeoff, or intent
  that the code can't convey. Leave it untouched.
- **Trim** — the point is worth keeping but it's padded. Cut it to the essential
  line; drop restated mechanics, hedging, and narration.
- **Cut** — it only restates what the code plainly says, or narrates the diff
  ("renamed from…", "now also handles…", "added null check"). Remove it.
- **Fix** — it's now false: the code changed but the comment still describes the
  old behavior. Correct it to match, or remove it if the corrected version would
  just restate the code. If you're unsure whether the new code is intended, don't
  silently rewrite — flag it in the summary instead.

Extra rules:

- **Trivial changes carry no narration.** If a hunk is a 1–2 line tweak, it
  almost never needs its own explanatory comment. Remove comments that were added
  just to annotate such a change, unless they capture a genuine non-obvious *why*.
- **Match the file's existing density.** A file that already comments heavily and
  deliberately sets a different bar than a terse one. Fit in; don't impose a
  uniform style across the repo.
- **Prefer removal over rewording for pure restatement**, but don't churn a
  comment that's already fine just to reword it.

## 4. Never touch these

Some "comments" are load-bearing. Leave them exactly as-is:

- Tool/linter directives: `eslint-disable`, `prettier-ignore`, `# type: ignore`,
  `# noqa`, `//nolint`, `# pragma`, `@ts-expect-error`, `# fmt: off`, etc.
- Doc comments consumed by tooling where the surrounding file uses them: JSDoc/
  TSDoc, Python/Go/Rust docstrings feeding API docs, Swagger/OpenAPI annotations.
- License/copyright headers, shebangs, and encoding/mode lines.
- `TODO`/`FIXME`/`HACK`/`XXX` notes that record real outstanding work — keep the
  intent; you may tighten the wording.

When in doubt about whether a comment is functional, keep it.

## 5. Apply directly, then summarize

Make the edits directly to the files. Afterward, give a short summary grouped by
file — one line per change, e.g. `trimmed`, `removed (restated code)`,
`fixed (stale after loop change)`, plus any comment you flagged for the user to
resolve. Keep it scannable; the point is the user can see at a glance what moved.

## Examples

**Restated code → cut**
```
Input:   // increment the counter by one
         counter += 1;
Output:  counter += 1;
```

**Verbose → trimmed**
```
Input:   // We use a WeakMap here instead of a regular Map so that entries are
         // garbage-collected automatically when the key object is no longer
         // referenced anywhere else, which prevents a memory leak over time.
         const cache = new WeakMap();
Output:  // WeakMap so cache entries are GC'd when their key is dropped
         const cache = new WeakMap();
```

**Stale after a logic change → fixed**
```
Input:   // retry up to 3 times            (code now loops `for i in range(5)`)
         for i in range(5):
Output:  // retry up to 5 times
         for i in range(5):
```

**Trivial change annotation → cut**
```
Input:   // changed default timeout to 30s
         timeout = 30
Output:  timeout = 30
```

**Genuine why → kept, untouched**
```
// Safari fires `resize` before layout settles, so debounce a frame
window.addEventListener('resize', debounce(onResize, 16));
```
