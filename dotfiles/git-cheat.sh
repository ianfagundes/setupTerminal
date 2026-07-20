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
