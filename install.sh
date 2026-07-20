#!/usr/bin/env bash
#
# install.sh — replica o ambiente de terminal deste repo num Mac.
#
# O que faz:
#   1. confere git/curl; instala Homebrew se faltar (com sua confirmação)
#   2. brew bundle  -> instala as ferramentas do Brewfile
#   3. pede nome/e-mail do git e escreve ~/.gitconfig.local (identidade fora do repo)
#   4. linka (ou copia) os dotfiles pra ~ e ~/.config
#   5. opcional: gera chave SSH ed25519 (--ssh-key)
#
# Uso:
#   ./install.sh                 # symlink dos dotfiles (recomendado)
#   ./install.sh --copy          # copia em vez de symlink
#   GIT_USER_NAME="Nome" GIT_USER_EMAIL="voce@x.com" ./install.sh   # sem perguntas
#
# Flags:
#   --copy            copia os arquivos em vez de criar symlink
#   --ssh-key         gera chave SSH ed25519 (se não existir) e mostra a pública
#   --no-backup       não cria .bak.<timestamp> ao sobrescrever
#   --clean-backups   apaga, ao final, os backups gerados nesta execução
#   -h, --help        mostra esta ajuda
#
# Idempotente: rodar de novo só atualiza o que precisa.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$SCRIPT_DIR/dotfiles"

# ---------- flags ----------
COPY=0; NO_BACKUP=0; CLEAN_BACKUPS=0; SSH_KEY=0
usage(){ sed -n '2,29p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'; exit "${1:-0}"; }
for arg in "$@"; do
  case "$arg" in
    --copy)          COPY=1 ;;
    --ssh-key)       SSH_KEY=1 ;;
    --no-backup)     NO_BACKUP=1 ;;
    --clean-backups) CLEAN_BACKUPS=1 ;;
    -h|--help)       usage 0 ;;
    *) printf "Opção desconhecida: %s\n" "$arg" >&2; usage 1 ;;
  esac
done

# ---------- helpers ----------
c_b=$'\e[1m'; c_grn=$'\e[32m'; c_yel=$'\e[33m'; c_red=$'\e[31m'; c_cyan=$'\e[36m'; c_dim=$'\e[2m'; c_rst=$'\e[0m'
STEP=0
banner(){
  printf "%s\n" "$c_cyan$c_b"
  printf "   ┌───────────────────────────────────────────────┐\n"
  printf "   │   setupTerminal  ·  dotfiles + Brewfile        │\n"
  printf "   └───────────────────────────────────────────────┘%s\n" "$c_rst"
}
step(){ STEP=$((STEP+1)); printf "\n%s[%d]%s %s%s%s\n" "$c_cyan$c_b" "$STEP" "$c_rst" "$c_b" "$*" "$c_rst"; }
ok(){   printf "  %s✓%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn(){ printf "  %s!%s %s\n" "$c_yel" "$c_rst" "$*"; }
err(){  printf "  %s✗%s %s\n" "$c_red" "$c_rst" "$*" >&2; }

BACKUPS=()
backup(){
  [ "$NO_BACKUP" -eq 1 ] && return 0
  # só backupeia arquivo/dir real (symlink antigo é só removido)
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    local b
    b="$1.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$1" "$b"; BACKUPS+=("$b"); warn "backup: $b"
  fi
}

# linka $1 (fonte no repo) -> $2 (destino em ~). Respeita --copy.
link(){
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  backup "$dst"
  rm -f "$dst" 2>/dev/null || true
  if [ "$COPY" -eq 1 ]; then
    cp -a "$src" "$dst"; ok "copiado  $dst"
  else
    ln -s "$src" "$dst"; ok "symlink  $dst -> $src"
  fi
}

banner

# ---------- 0. pré-requisitos ----------
step "Checando pré-requisitos"
command -v git  >/dev/null 2>&1 || { err "git ausente. Rode: xcode-select --install"; exit 1; }
command -v curl >/dev/null 2>&1 || { err "curl ausente."; exit 1; }
ok "git e curl presentes"

# ---------- 1. Homebrew ----------
step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew não encontrado."
  read -r -p "  Instalar agora? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    err "Sem Homebrew não dá pra instalar as ferramentas. Abortando."; exit 1
  fi
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
ok "brew: $(command -v brew)"

# ---------- 2. Brewfile ----------
step "Instalando ferramentas (brew bundle)"
brew bundle --file="$SCRIPT_DIR/Brewfile"
ok "ferramentas do Brewfile instaladas"

# ---------- 3. identidade git -> ~/.gitconfig.local ----------
step "Identidade do Git (~/.gitconfig.local)"
GIT_NAME="${GIT_USER_NAME:-$(git config --global user.name 2>/dev/null || true)}"
GIT_EMAIL="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"
[ -z "$GIT_NAME" ]  && read -r -p "  Seu nome para os commits: "  GIT_NAME
[ -z "$GIT_EMAIL" ] && read -r -p "  Seu e-mail para os commits: " GIT_EMAIL
backup "$HOME/.gitconfig.local"
printf '[user]\n\tname = %s\n\temail = %s\n' "$GIT_NAME" "$GIT_EMAIL" > "$HOME/.gitconfig.local"
ok "identidade: $GIT_NAME <$GIT_EMAIL>"

# ---------- 4. dotfiles ----------
step "Linkando dotfiles"
link "$DOTFILES/gitconfig"              "$HOME/.gitconfig"
link "$DOTFILES/gitignore"              "$HOME/.gitignore"
link "$DOTFILES/zshrc"                  "$HOME/.zshrc"
link "$DOTFILES/git-cheat.sh"           "$HOME/.git-cheat.sh"
link "$DOTFILES/config/iterm2/dev.zsh"  "$HOME/.config/iterm2/dev.zsh"
link "$DOTFILES/config/starship.toml"   "$HOME/.config/starship.toml"
link "$DOTFILES/config/bat/config"      "$HOME/.config/bat/config"
git config --global --list >/dev/null && ok "gitconfig válido (identidade via include)"

# ---------- 5. chave SSH (opcional) ----------
if [ "$SSH_KEY" -eq 1 ]; then
  step "Chave SSH (ed25519)"
  KEY="$HOME/.ssh/id_ed25519"
  mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  if [ -f "$KEY" ]; then
    ok "chave já existe ($KEY) — mantendo"
  else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY" -N "" >/dev/null
    ok "chave criada: $KEY"
  fi
  eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
  ssh-add "$KEY" >/dev/null 2>&1 || ssh-add --apple-use-keychain "$KEY" >/dev/null 2>&1 || true
  echo; echo "  ${c_b}Cadastre a pública no GitHub${c_rst}: https://github.com/settings/ssh/new"; echo
  sed 's/^/    /' "$KEY.pub"; echo
fi

# ---------- 6. limpeza de backups ----------
if [ "$CLEAN_BACKUPS" -eq 1 ]; then
  step "Limpando backups desta execução"
  if [ "${#BACKUPS[@]}" -eq 0 ]; then ok "nenhum backup gerado"; else
    for b in "${BACKUPS[@]}"; do rm -rf "$b" && ok "removido: $b"; done
  fi
fi

# ---------- fim ----------
printf "\n%s%s   ✓ Setup concluído%s\n" "$c_grn" "$c_b" "$c_rst"
ok "Ferramentas: starship, delta (Dracula), fzf, zoxide, eza, bat, fd, ripgrep, direnv, lazygit, gh"
ok "Dotfiles linkados (gitconfig, zshrc, dev.zsh, starship.toml, bat, git-cheat)"
printf "\n%sPróximo passo:%s abra um terminal novo (ou: %ssource ~/.zshrc%s)\n" "$c_b" "$c_rst" "$c_cyan" "$c_rst"
printf "%sTeste:%s git cheat  ·  git diff  ·  ll  ·  z <pasta>\n" "$c_b" "$c_rst"
printf "%sSegredos locais:%s ponha API keys em ~/.zshrc.local (fora do git)\n" "$c_dim" "$c_rst"
