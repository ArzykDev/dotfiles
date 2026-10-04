# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

This repository is the chezmoi source directory. Files here are written in
chezmoi's source-state naming format, then applied into `$HOME`.

## Layout

- `dot_config/` - application configuration under `~/.config`
- `dot_codex/` - Codex configuration and agent instructions
- `dot_claude/` - Claude configuration and helper scripts
- `dot_local/bin/` - executable scripts installed into `~/.local/bin`
  (desktop-only ones are ignored elsewhere via `.chezmoiignore.tmpl`)
- `dot_gitconfig.tmpl` - templated Git configuration
- `dot_zshrc.shared` - shared Zsh configuration
- `dot_bashrc.d/shared.bash` - shared Bash configuration (flyline, starship,
  zoxide, mise), sourced by Fedora's stock `~/.bashrc` loop

Anything machine-local or secret-bearing stays out of this repo (it is public)
and lives in an untracked `~/.bashrc.d/work.bash`, which the same loop picks up
after `shared.bash`.
- `.chezmoi.toml.tmpl` - chezmoi data/config template
- `.chezmoiignore.tmpl` - ignored paths for this source tree

## Bootstrap a New Machine

Encrypted files (`~/.ssh/config`) need the age key in place before the first
apply, otherwise `chezmoi init --apply` leaves them undecrypted:

```sh
op document get "Chezmoi Age Key" --out-file ~/.config/chezmoi/key.txt
chezmoi init --apply ArzykDev/dotfiles
```

## Bash as Login Shell

Login bash reads only `~/.profile` (keep no `~/.bash_profile`), so it must
end by sourcing `~/.bashrc`, which sources every file in `~/.bashrc.d`:

```sh
[ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
```

Fedora's stock `~/.bashrc` already has the `~/.bashrc.d` loop. On macOS, add
one to `~/.bashrc`, then allow Homebrew's bash before switching:

```sh
echo "$(brew --prefix)/bin/bash" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/bash"
```

## Importing Shell History into flyline

`shared.bash` puts flyline on its own JSONL store, so history from a previous
shell has to be imported once. Atuin's database also holds agent commands
(`atuin hook claude-code`, dropped in 5e8d73f); filter them out on a copy
first, since `flyline history import` takes the whole file:

```sh
sqlite3 ~/.local/share/atuin/history.db "VACUUM INTO '/tmp/atuin-user.db'"
sqlite3 /tmp/atuin-user.db "DELETE FROM history WHERE author IS NOT NULL AND author <> 'arzyk';"
flyline history import /tmp/atuin-user.db
rm /tmp/atuin-user.db
```

flyline is a loadable builtin, not a binary, so the import has to run from a
real interactive terminal. Switching the backend also pulls in `~/.bash_history`
on its own, so prune that file first - agent harnesses that drove an interactive
bash leave `___BEGIN___COMMAND_OUTPUT_MARKER___` wrappers and spilled heredoc
bodies in it. The store is `~/.local/share/flyline/history.jsonl` on Linux and
`~/Library/Application Support/flyline/history.jsonl` on macOS; a bad import is
recoverable by deleting entries with the import's timestamp, which they all
share.

## Common Commands

Preview changes before applying them:

```sh
chezmoi diff
```

Apply the current source state:

```sh
chezmoi apply
```

Edit a managed file:

```sh
chezmoi edit ~/.zshrc
```

Add or refresh a file from the home directory:

```sh
chezmoi add ~/.config/example/config.toml
```

Check what chezmoi manages:

```sh
chezmoi managed
```

## Commit Messages

Use conventional commits with scopes for dotfile changes.

Prefer messages that describe the behavior change, not just that a file was
updated.

Good:

```text
feat(lazygit): use Codex for commit messages
fix(zsh): preserve SSH agent env across shells
config(git): enable difftastic pager
chore(brew): refresh package list
docs(readme): document bootstrap steps
```

Avoid vague subjects:

```text
feat: update lazygit config
chore: update files
```

Use a body when the commit changes behavior across multiple files or when the
reason is not obvious from the subject. Keep commit titles under 50 characters
and body lines under 72 characters.
