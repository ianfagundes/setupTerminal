# Developer-friendly zsh setup for iTerm2.

# Homebrew first, so modern CLI tools beat macOS system defaults.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_NO_ENV_HINTS=1
export COLORTERM=truecolor
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

if command -v code >/dev/null 2>&1; then
  export EDITOR="code --wait"
else
  export EDITOR="nano"
fi

export VISUAL="$EDITOR"
export LESS="-FRX --mouse --wheel-lines=3"
export MANPAGER="sh -c 'col -bx | bat -l man -p 2>/dev/null || col -bx'"
export BAT_PAGER="less -R"

# History that is useful across tabs without saving noisy duplicates.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt append_history
setopt extended_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify

# Navigation ergonomics.
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_silent
setopt interactive_comments

_codex_interactive_tty() {
  [[ -o interactive && -t 0 ]]
}

bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# Completions.
if [[ -d /opt/homebrew/share/zsh-completions ]]; then
  fpath=(/opt/homebrew/share/zsh-completions $fpath)
fi
if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi
autoload -Uz compinit
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# iTerm2 shell integration: marks, better Cmd-click behavior, and utilities.
if [[ -r /Applications/iTerm.app/Contents/Resources/iterm2_shell_integration.zsh ]]; then
  source /Applications/iTerm.app/Contents/Resources/iterm2_shell_integration.zsh
fi

# fzf: fuzzy files, history, and directory jumping.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git --exclude node_modules'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git --exclude node_modules'
fi
export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border --info=inline --cycle'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || tree -C {} | head -200"'
export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --color=always {} 2>/dev/null | head -200"'
if command -v fzf >/dev/null 2>&1 && _codex_interactive_tty; then
  source <(fzf --zsh)
fi

# Project-local environment files.
if command -v direnv >/dev/null 2>&1 && _codex_interactive_tty; then
  eval "$(direnv hook zsh)"
fi

# Modern CLI aliases.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lah --icons=auto --git --group-directories-first'
  alias la='eza -lah --icons=auto --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons=auto --group-directories-first'
else
  alias ll='ls -lah'
  alias la='ls -lah'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

alias c='clear'
alias path='print -l $path'
alias reload='source ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ports='lsof -nP -iTCP -sTCP:LISTEN'
alias serve='python3 -m http.server'

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git pull --ff-only'
alias gp='git push'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

mkcd() {
  mkdir -p "$1" && cd "$1"
}

cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git --exclude node_modules . "${1:-.}" 2>/dev/null | fzf) && cd "$dir"
}

fkill() {
  local pid
  pid=$(ps -ax -o pid=,comm= | fzf --prompt='kill> ' | awk '{print $1}')
  [[ -n "$pid" ]] && kill "$pid"
}

gitroot() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$root"
}

cleanup_branches() {
  local branches
  branches=$(git branch --merged | grep -vE '(^\*|main|master|develop|dev)$')
  [[ -n "$branches" ]] && print -r -- "$branches" | xargs git branch -d
}

# Autosuggestions before syntax highlighting.
if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && _codex_interactive_tty; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi

if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && _codex_interactive_tty; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Prompt.
if command -v starship >/dev/null 2>&1 && [[ "${TERM:-}" != "dumb" ]]; then
  eval "$(starship init zsh)"
fi

# Smart cd. Use "cd partial-name" after visiting folders a few times.
# zoxide inicia por ÚLTIMO (depois do starship) pra o hook dele ser o último
# precmd — senão o `zoxide doctor` reclama "initialize at the end".
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
  alias j='z'
  alias ji='zi'
fi
