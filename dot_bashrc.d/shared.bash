# Sourced by every bash, including the non-interactive login shell that starts
# the desktop session, so everything above the interactive guard must be silent.

# shellenv prepends unconditionally, so a nested bash would stack duplicates.
[[ -x /opt/homebrew/bin/brew && ":$PATH:" != *":/opt/homebrew/bin:"* ]] &&
    eval "$(/opt/homebrew/bin/brew shellenv bash)"

for _d in "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/.local/bin" "$HOME/bin"; do
    [[ ":$PATH:" == *":$_d:"* ]] || PATH="$_d:$PATH"
done
unset _d
export PATH

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR=hx
export PAGER=ov
export MANPAGER="bat -plman"
export EGET_BIN="$HOME/bin"
export SYSTEMD_LESS='FRSMK'
export SYSTEMD_COLORS=1
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_SCROLL_SPEED=3
export AGENT_BROWSER_IGNORE_HTTPS_ERRORS=true

# Every cgo build on macOS 15 warns about duplicate libraries; nothing to fix.
[[ $OSTYPE == darwin* ]] && export CGO_LDFLAGS="-Wl,-no_warn_duplicate_libraries"

# Base look inherited by all fzf tools (zoxide overrides it, see _ZO_FZF_OPTS).
export FZF_DEFAULT_OPTS="
  --height=80%
  --layout=reverse
  --border
  --info=inline
  --cycle
"

# zoxide's interactive fzf (zi). Self-contained: zoxide replaces FZF_DEFAULT_OPTS
# rather than appending. No --exact = fuzzy. {2} is the path (score is field 1).
export _ZO_FZF_OPTS="
  --no-sort
  --keep-right
  --cycle
  --info=inline
  --exit-0
  --bind=ctrl-z:ignore,btab:up,tab:down
  --height=80%
  --layout=reverse
  --border
  --preview='eza -la --icons --color=always {2}'
  --preview-window=right,50%,border-left
"

# Also stops sshd-spawned non-interactive bash, which reads .bashrc too.
[[ $- == *i* ]] || return

# Fedora loads bash-completion via /etc/profile.d; macOS doesn't.
[[ -n ${HOMEBREW_PREFIX:-} && -r $HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh ]] &&
    . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

alias ll="eza -la --icons=auto"
# Pinned by path rather than $(brew --prefix nano) to skip a fork per shell.
[[ $OSTYPE == darwin* ]] && alias nano=/opt/homebrew/opt/nano/bin/nano

mkcd() {
    if (( $# != 1 )); then
        echo "usage: mkcd DIR" >&2
        return 2
    fi

    mkdir -p -- "$1" && z -- "$1"
}

gi() { curl -sLw "\n" "https://www.toptal.com/developers/gitignore/api/$*"; }

eval "$(mise activate bash)"
eval "$(starship init bash)"
eval "$(zoxide init bash)"

# Homebrew's bash finds its flyline on the default loadables path;
# install.sh (Linux) drops it in ~/.local/lib instead.
# Fedora's default path ends in ".", so a bare `enable` that misses the system
# dirs would dlopen ./flyline from whatever directory the terminal opened in.
BASH_LOADABLES_PATH=${BASH_LOADABLES_PATH%:.}
if enable flyline 2>/dev/null ||
    enable -f "$HOME/.local/lib/libflyline.so" flyline 2>/dev/null; then
    # JSONL store shared across sessions; also what `flyline history import` fills.
    flyline history --backend flyline
    # flyline doesn't run PROMPT_COMMAND after runBashCommand, so the cd would
    # leave starship and mise on the old dir; the empty submit refreshes them.
    # bufferIsEmpty so it can never submit half-typed text.
    flyline key bind Alt+c 'editingBufferMode+bufferIsEmpty=runBashCommand(__zoxide_zi)+submitOrNewline'

    flyline set-agent-mode \
        --system-prompt "Be concise. Answer with a JSON array of at most 3 items with objects containing: command and description. Command will be a Bash command. " \
        --trigger-prefix ': ' \
        --command 'claude --no-session-persistence --effort low --print'

    flyline set-cursor --effect blink

    # flyline renders PS1 itself and drops OSC escapes, so ghostty's PS1-embedded
    # "title = cwd" reset never fires and the last command sticks in the titlebar.
    __title_pwd() { printf '\e]2;%s\a' "${PWD/#$HOME/\~}"; }
    PROMPT_COMMAND=("${PROMPT_COMMAND[@]}" __title_pwd)
fi

fastfetch
