# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

This repository is the chezmoi source directory. Files here are written in
chezmoi's source-state naming format, then applied into `$HOME`.

## Layout

- `dot_config/` - application configuration under `~/.config`
- `dot_codex/` - Codex configuration and agent instructions
- `dot_claude/` - Claude configuration and helper scripts
- `bin/` - executable scripts installed into `~/bin`
- `dot_gitconfig.tmpl` - templated Git configuration
- `dot_zshrc.shared` - shared Zsh configuration
- `.chezmoi.toml.tmpl` - chezmoi data/config template
- `.chezmoiignore.tmpl` - ignored paths for this source tree

## Bootstrap a New Machine

Encrypted files (`~/.ssh/config`) need the age key in place before the first
apply, otherwise `chezmoi init --apply` leaves them undecrypted:

```sh
op document get "Chezmoi Age Key" --out-file ~/.config/chezmoi/key.txt
chezmoi init --apply ArzykDev/dotfiles
```

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
