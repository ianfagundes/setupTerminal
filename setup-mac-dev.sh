#!/usr/bin/env bash
#
# setup-mac-dev.sh
# Replica o ambiente de terminal/git do zero em um Mac novo:
#   - Oh My Zsh
#   - plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, zsh-autocomplete
#   - ~/.zshrc configurado (plugins + autocomplete + alias gcheat + Ruby do Homebrew no PATH)
#   - ~/.gitconfig (identidade + dezenas de aliases + alias `cheat`)
#   - ~/.gitignore global
#   - ~/.git-cheat.sh (cola de-para: `git cheat` / `gcheat`)
#
# Uso:
#   chmod +x setup-mac-dev.sh
#   ./setup-mac-dev.sh
#
# Não-interativo (opcional): defina antes de rodar
#   GIT_USER_NAME="Seu Nome" GIT_USER_EMAIL="voce@email.com" ./setup-mac-dev.sh
#
# Flags:
#   --no-backup        não cria os arquivos .bak.<timestamp> ao sobrescrever
#   --clean-backups    ao final, apaga os backups (.bak.*) gerados desta execução
#   -h, --help         mostra esta ajuda
#
# Idempotente: rodar de novo só atualiza o que precisa. Faz backup do que sobrescreve
# (a menos que --no-backup).

set -euo pipefail

# ---------- flags ----------
NO_BACKUP=0
CLEAN_BACKUPS=0
usage(){
  sed -n '2,21p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'
  exit "${1:-0}"
}
for arg in "$@"; do
  case "$arg" in
    --no-backup)     NO_BACKUP=1 ;;
    --clean-backups) CLEAN_BACKUPS=1 ;;
    -h|--help)       usage 0 ;;
    *) printf "Opção desconhecida: %s\n" "$arg" >&2; usage 1 ;;
  esac
done

# ---------- helpers ----------
c_b=$'\e[1m'; c_grn=$'\e[32m'; c_yel=$'\e[33m'; c_red=$'\e[31m'; c_rst=$'\e[0m'
info(){ printf "%s==>%s %s\n" "$c_b" "$c_rst" "$*"; }
ok(){   printf "  %s✓%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn(){ printf "  %s!%s %s\n" "$c_yel" "$c_rst" "$*"; }
err(){  printf "  %s✗%s %s\n" "$c_red" "$c_rst" "$*" >&2; }
BACKUPS=()  # caminhos dos backups criados nesta execução
backup(){ # backup $1 se existir (respeita --no-backup)
  [ "$NO_BACKUP" -eq 1 ] && return 0
  if [ -e "$1" ]; then
    local b="$1.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$1" "$b"
    BACKUPS+=("$b")
    warn "backup: $b"
  fi
}

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
ZSHRC="$HOME/.zshrc"

# ---------- 0. pré-requisitos ----------
info "Checando pré-requisitos"
command -v git  >/dev/null 2>&1 || { err "git não encontrado. Instale o Xcode Command Line Tools: xcode-select --install"; exit 1; }
command -v curl >/dev/null 2>&1 || { err "curl não encontrado."; exit 1; }
ok "git e curl presentes"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew não encontrado. Plugins não dependem dele, mas o PATH do Ruby só vale após instalar brew+ruby."
  warn "Para instalar: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
  ok "Homebrew presente"
fi

# ---------- 1. Oh My Zsh ----------
info "Instalando Oh My Zsh"
if [ -d "$ZSH_DIR" ]; then
  ok "já instalado ($ZSH_DIR)"
else
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh instalado"
fi

# ---------- 2. plugins externos ----------
info "Instalando plugins"
clone_plugin(){ # $1 = url, $2 = nome
  local dest="$ZSH_CUSTOM/plugins/$2"
  if [ -d "$dest" ]; then
    ok "$2 já presente"
  else
    git clone --depth=1 "$1" "$dest" >/dev/null 2>&1
    ok "$2 clonado"
  fi
}
mkdir -p "$ZSH_CUSTOM/plugins"
clone_plugin https://github.com/zsh-users/zsh-autosuggestions      zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting  zsh-syntax-highlighting
clone_plugin https://github.com/marlonrichert/zsh-autocomplete     zsh-autocomplete

# ---------- 3. identidade git ----------
info "Configurando identidade do Git"
GIT_NAME="${GIT_USER_NAME:-$(git config --global user.name 2>/dev/null || true)}"
GIT_EMAIL="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"
if [ -z "$GIT_NAME" ];  then read -r -p "  Seu nome para os commits: " GIT_NAME; fi
if [ -z "$GIT_EMAIL" ]; then read -r -p "  Seu e-mail para os commits: " GIT_EMAIL; fi
ok "nome:  $GIT_NAME"
ok "email: $GIT_EMAIL"

# ---------- 4. ~/.gitconfig ----------
info "Escrevendo ~/.gitconfig"
backup "$HOME/.gitconfig"
{
  printf '[user]\n\tname = %s\n\temail = %s\n' "$GIT_NAME" "$GIT_EMAIL"
  cat <<'GITCONFIG'
[rerere]
	enabled = 1
	autoupdate = 1
[core]
	editor = vim
	whitespace = fix,-indent-with-non-tab,trailing-space,cr-at-eol
	excludesfile = ~/.gitignore
	autocrlf = input
[push]
	default = matching
[color]
	ui = auto
[color "branch"]
	current = yellow bold
	local = green bold
	remote = cyan bold
[color "diff"]
	meta = yellow bold
	frag = magenta bold
	old = red bold
	new = green bold
	whitespace = red reverse
[color "status"]
	added = green bold
	changed = yellow bold
	untracked = red bold
[alias]
	a = add --all
	ai = add -i
	ap = add -p
	#############
	reseta = reset HEAD^ --hard
	b = branch
	ba = branch -a
	bd = branch -d
	br = branch -r
	#############
	c = commit
	ca = commit -a
	co = checkout
	cod = checkout --
	cm = commit -m
	cem = commit --allow-empty -m
	cam = commit -am
	cd = commit --amend
	cad = commit -a --amend
	ced = commit --allow-empty --amend
	#############
	d = diff
	dc = diff --cached
	dl = difftool
	dlc = difftool --cached
	dk = diff --check
	dp = diff --patience
	dck = diff --cached --check
	#############
	lg = log --oneline
	l = log
	lg2 = log --graph --branches=* --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
	#############
	ps = push
	psf = push -f
	psu = push -u
	pso = push origin
	psao = push --all origin
	psfo = push -f origin
	psuo = push -u origin
	psom = push origin master
	psfom = push -f origin master
	psuom = push -u origin master
	#############
	pl = pull
	plu = pull -u
	plo = pull origin
	plp = pull upstream
	plom = pull origin master
	plpm = pull upstream master
	#############
	pr = pull --rebase
	pbo = pull --rebase origin
	pbp = pull --rebase upstream
	pbom = pull --rebase origin master
	pbpm = pull --rebase upstream master
	#############
	rb = rebase
	re = reset
	rev = revert --no-edit
	rmpod = rm --cached Pods -r
	#############
	st = status
	sb = status -s -b
	#############
	s  = stash
	sa = stash apply
	sc = stash clear
	sd = stash drop
	sl = stash list
	sp = stash pop
	ss = stash save
	sw = stash show
	#############
	w = show
	wp = show -p
	wr = show -p --no-color
	#### atalhos do guia (modernos / extras) ####
	swi = switch
	swc = switch -c
	rst = restore
	unstage = restore --staged
	last = log -1 HEAD --stat
	graph = log --oneline --graph --all --decorate
	amend = commit --amend --no-edit
	bdd = branch -D
	rmrb = push origin --delete
	pfl = push --force-with-lease
	cont = rebase --continue
	ref = reflog
	remotes = remote -v
	grp = grep -n
	who = blame
	contrib = shortlog -sn
	cleann = clean -n
	#### tooltip / de-para ####
	cheat = "!bash ~/.git-cheat.sh"
[filter "lfs"]
	clean = git-lfs clean %f
	smudge = git-lfs smudge %f
	required = true
GITCONFIG
} > "$HOME/.gitconfig"
git config --global --list >/dev/null && ok "~/.gitconfig válido"

# ---------- 5. ~/.gitignore global ----------
info "Escrevendo ~/.gitignore global"
backup "$HOME/.gitignore"
cat > "$HOME/.gitignore" <<'GITIGNORE'
# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon
._*

# Xcode / iOS
xcuserdata/
*.xcuserstate
DerivedData/
*.moved-aside

# Editores
.idea/
.vscode/
*.swp
*~
GITIGNORE
ok "~/.gitignore criado"

# ---------- 6. ~/.git-cheat.sh ----------
info "Escrevendo ~/.git-cheat.sh (cola de-para)"
backup "$HOME/.git-cheat.sh"
cat > "$HOME/.git-cheat.sh" <<'CHEATSCRIPT'
#!/usr/bin/env bash
# Cheatsheet Git (de-para + o que faz + como usar)
# Uso:  git cheat            -> mostra tudo
#       git cheat stash      -> filtra por "stash"
#       gcheat branch        -> idem, no terminal
#
# Dados: SECAO|ALIAS|COMANDO REAL|O QUE FAZ|EXEMPLO DE USO
#   - ALIAS vazio = comando sem atalho próprio

FILTER="${*:-}"

# cores (desliga se não for terminal)
if [ -t 1 ]; then
  B=$'\e[1m'; DIM=$'\e[2m'; CYAN=$'\e[36m'; YEL=$'\e[33m'; GRN=$'\e[32m'; RST=$'\e[0m'
else
  B=""; DIM=""; CYAN=""; YEL=""; GRN=""; RST=""
fi

DATA=$(cat <<'EOF'
Config inicial|=|git config --global user.name "Nome"|define o nome dos seus commits|git config --global user.name "Ian Kulaif"
Config inicial|=|git config --global user.email "email"|define o e-mail dos seus commits|git config --global user.email "voce@email.com"
Config inicial|=|git config --list|mostra todas as configs ativas|git config --list
Config inicial|cheat|git cheat [termo]|mostra esta cola (de-para)|git cheat stash
Status & histórico|st|git status|estado dos arquivos (mod/staged/untracked)|git st
Status & histórico|sb|git status -s -b|status resumido + branch|git sb
Status & histórico|l|git log|histórico completo de commits|git l
Status & histórico|lg|git log --oneline|uma linha por commit (compacto)|git lg
Status & histórico|graph|git log --oneline --graph --all --decorate|histórico visual de todas as branches|git graph
Status & histórico|last|git log -1 HEAD --stat|detalhes do último commit|git last
Status & histórico|=|git log --author="Nome"|filtra commits por autor|git log --author="Ian"
Status & histórico|=|git log --since="2 weeks ago"|filtra commits por data|git log --since="2 weeks ago"
Status & histórico|d|git diff|mudanças NÃO staged (working vs stage)|git d
Status & histórico|dc|git diff --cached|mudanças JÁ staged (stage vs commit)|git dc
Status & histórico|w|git show|detalhes/diff de um commit|git w HEAD
Stage & commit|a|git add --all|adiciona tudo ao stage (inclui remoções)|git a
Stage & commit|ap|git add -p|escolhe pedaços (hunks) interativamente|git ap
Stage & commit|unstage|git restore --staged <arq>|tira do stage sem perder mudança|git unstage arquivo.js
Stage & commit|cm|git commit -m "msg"|commit com mensagem|git cm "feat: login"
Stage & commit|cam|git commit -am "msg"|add do rastreado + commit num passo|git cam "fix: ajuste"
Stage & commit|amend|git commit --amend --no-edit|junta mudança ao último commit, mantém msg|git amend
Stage & commit|cd|git commit --amend|edita o último commit (msg/conteúdo)|git cd
Desfazer|rst|git restore <arq>|descarta mudança não staged do arquivo|git rst arquivo.js
Desfazer|re|git reset|tira do stage (forma antiga)|git re arquivo.js
Desfazer|=|git reset --soft HEAD~1|desfaz último commit, mantém staged|git reset --soft HEAD~1
Desfazer|reseta|git reset HEAD^ --hard|desfaz último commit e DESCARTA tudo (cuidado)|git reseta
Desfazer|=|git reset --hard <commit>|volta o repo inteiro pra um commit|git reset --hard a1b2c3d
Desfazer|rev|git revert --no-edit <commit>|cria commit que desfaz outro (seguro p/ remoto)|git rev a1b2c3d
Desfazer|ref|git reflog|histórico de tudo que o HEAD apontou (recupera "perdidos")|git ref
Stash|s|git stash|guarda mudanças e limpa o working dir|git s
Stash|=|git stash push -m "msg"|guarda com mensagem descritiva|git stash push -m "wip login"
Stash|=|git stash -u|inclui arquivos untracked no stash|git stash -u
Stash|sp|git stash pop|aplica o último stash e remove da lista|git sp
Stash|sa|git stash apply|aplica o último stash, mas mantém na lista|git sa
Stash|sl|git stash list|lista todos os stashes|git sl
Stash|sd|git stash drop|remove um stash específico|git sd stash@{0}
Stash|sc|git stash clear|remove todos os stashes|git sc
Branches|b|git branch|lista branches locais|git b
Branches|ba|git branch -a|lista locais + remotas|git ba
Branches|swi|git switch <branch>|troca de branch (recomendado)|git swi main
Branches|swc|git switch -c <branch>|cria e já troca de branch|git swc feature/x
Branches|co|git checkout <branch>|troca de branch (forma antiga)|git co main
Branches|=|git branch -m antigo novo|renomeia uma branch|git branch -m old new
Branches|bd|git branch -d <branch>|apaga branch local já mesclada|git bd feature/x
Branches|bdd|git branch -D <branch>|força remover branch local (sem merge)|git bdd feature/x
Branches|rmrb|git push origin --delete <branch>|apaga branch no remoto|git rmrb feature/x
Merge & rebase|=|git merge <branch>|mescla outra branch na atual|git merge feature/x
Merge & rebase|=|git merge --no-ff <branch>|força commit de merge (sem fast-forward)|git merge --no-ff feature/x
Merge & rebase|rb|git rebase <branch>|reaplica seus commits em cima da outra (linear)|git rb main
Merge & rebase|=|git rebase -i HEAD~3|reorganiza/junta/edita os últimos 3 commits|git rebase -i HEAD~3
Merge & rebase|cont|git rebase --continue|continua o rebase após resolver conflito|git cont
Merge & rebase|=|git rebase --abort|cancela o rebase em andamento|git rebase --abort
Merge & rebase|=|git merge --abort|cancela o merge em andamento|git merge --abort
Remotos|remotes|git remote -v|lista remotos e URLs|git remotes
Remotos|=|git remote add origin <url>|adiciona remoto "origin"|git remote add origin git@...:repo.git
Remotos|=|git remote set-url origin <url>|troca a URL do remoto|git remote set-url origin git@...:repo.git
Remotos|=|git fetch|busca do remoto sem mesclar|git fetch
Remotos|pl|git pull|busca + mescla (fetch + merge)|git pl
Remotos|pr|git pull --rebase|busca e reaplica seus commits (sem merge)|git pr
Remotos|ps|git push|envia commits pro remoto|git ps
Remotos|psu|git push -u origin <branch>|envia e define upstream|git psu origin feature/x
Remotos|pfl|git push --force-with-lease|force seguro (falha se houver novidade remota)|git pfl
Remotos|psf|git push --force|force bruto (evite em branch compartilhada)|git psf
Tags|=|git tag|lista todas as tags|git tag
Tags|=|git tag -a v1.0.0 -m "msg"|cria tag anotada (recomendado)|git tag -a v1.0.0 -m "Release"
Tags|=|git push origin v1.0.0|envia uma tag pro remoto|git push origin v1.0.0
Tags|=|git push origin --tags|envia todas as tags|git push origin --tags
Inspeção|grp|git grep -n "termo"|busca termo nos arquivos rastreados|git grp TODO
Inspeção|who|git blame <arq>|quem mudou cada linha e em qual commit|git who arquivo.js
Inspeção|contrib|git shortlog -sn|contribuidores e nº de commits|git contrib
Inspeção|=|git show --stat <commit>|estatísticas de um commit|git show --stat HEAD
Limpeza|cleann|git clean -n|MOSTRA (sem apagar) untracked a remover|git cleann
Limpeza|=|git clean -fd|remove arquivos E pastas untracked (cuidado)|git clean -fd
Limpeza|=|git gc|otimização interna do repo|git gc
Pods (iOS)|rmpod|git rm --cached Pods -r|tira a pasta Pods do versionamento|git rmpod
EOF
)

# imprime, agrupado por seção, com filtro opcional
echo "$DATA" | awk -F'|' -v B="$B" -v DIM="$DIM" -v CYAN="$CYAN" -v YEL="$YEL" -v GRN="$GRN" -v RST="$RST" -v flt="$FILTER" '
function lc(s){ return tolower(s) }
BEGIN{ if(flt!=""){ flt=tolower(flt) } sec="" }
{
  if (flt!="" && index(lc($0), flt)==0) next
  if ($1 != sec) {
    sec=$1
    printf "\n%s%s%s\n", B CYAN, "▌ " sec, RST
  }
  alias = ($2=="=") ? "-" : $2
  printf "  %s%-9s%s %s%-44s%s %s%s%s\n", YEL, alias, RST, GRN, $3, RST, DIM, $4, RST
  if ($5 != "") printf "  %-9s %sex:%s %s\n", "", DIM, RST, $5
}
END{ printf "\n%sDica:%s  git cheat <termo>   filtra (ex: git cheat branch, git cheat stash)\n", B, RST }
'
CHEATSCRIPT
chmod +x "$HOME/.git-cheat.sh"
ok "~/.git-cheat.sh criado"

# ---------- 7. ~/.zshrc ----------
info "Configurando ~/.zshrc"
backup "$ZSHRC"
# garante que o arquivo existe (caso KEEP_ZSHRC tenha preservado um vazio/inexistente)
[ -f "$ZSHRC" ] || touch "$ZSHRC"

# 7a. linha de plugins
if grep -qE '^plugins=\(' "$ZSHRC"; then
  sed -i '' 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
else
  printf '\nplugins=(git zsh-autosuggestions zsh-syntax-highlighting)\n' >> "$ZSHRC"
fi
ok "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"

# 7b. bloco custom (idempotente, entre marcadores)
ZMARK_START="# >>> dev-setup (zsh) >>>"
ZMARK_END="# <<< dev-setup (zsh) <<<"
if grep -qF "$ZMARK_START" "$ZSHRC"; then
  awk -v s="$ZMARK_START" -v e="$ZMARK_END" '
    $0==s{skip=1} !skip{print} $0==e{skip=0}' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
fi
cat >> "$ZSHRC" <<'ZBLOCK'
# >>> dev-setup (zsh) >>>

# zsh-autocomplete: menu de autocomplete em tempo real
# (comente a linha abaixo se preferir o autocomplete padrão por TAB)
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

# Ruby do Homebrew no PATH (inofensivo se o caminho não existir)
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Cheatsheet git (de-para + como usar)
alias gcheat="bash ~/.git-cheat.sh"
# <<< dev-setup (zsh) <<<
ZBLOCK
ok "bloco custom aplicado"

# ---------- 8. limpeza de backups (opcional) ----------
if [ "$CLEAN_BACKUPS" -eq 1 ]; then
  info "Limpando backups desta execução (--clean-backups)"
  if [ "${#BACKUPS[@]}" -eq 0 ]; then
    ok "nenhum backup foi gerado"
  else
    for b in "${BACKUPS[@]}"; do rm -f "$b" && ok "removido: $b"; done
  fi
fi

# ---------- fim ----------
echo
info "${c_grn}Setup concluído!${c_rst}"
echo "  Abra um terminal novo (ou rode: source ~/.zshrc) para ativar tudo."
echo "  Teste:  git cheat        |  git cheat branch        |  gcheat stash"
if [ "$NO_BACKUP" -eq 0 ] && [ "$CLEAN_BACKUPS" -eq 0 ] && [ "${#BACKUPS[@]}" -gt 0 ]; then
  echo "  Backups criados (.bak.*). Para apagá-los depois: rode de novo com --clean-backups,"
  echo "  ou: rm -f ~/.gitconfig.bak.* ~/.zshrc.bak.* ~/.gitignore.bak.* ~/.git-cheat.sh.bak.*"
fi
