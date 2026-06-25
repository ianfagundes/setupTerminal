# Setup Mac Dev — ambiente de terminal + Git

Script único e idempotente que replica todo o ambiente de terminal/Git em um Mac novo,
do zero ao estado final: Oh My Zsh, plugins do Zsh, aliases do Git e uma "cola" de comandos.

Arquivo: `setup-mac-dev.sh`

---

## Como usar

1. Copie `setup-mac-dev.sh` para o Mac novo (AirDrop, pendrive, repositório, etc.).
2. No Terminal, na pasta onde está o arquivo:

   ```sh
   chmod +x setup-mac-dev.sh
   ./setup-mac-dev.sh
   ```

3. Ele pede seu **nome** e **e-mail** do Git (única interação).
4. Abra um **terminal novo** (ou rode `source ~/.zshrc`) para ativar tudo.

### Modo 100% automático (sem perguntas)

```sh
GIT_USER_NAME="Seu Nome" GIT_USER_EMAIL="voce@email.com" ./setup-mac-dev.sh
```

### Flags

| Flag | O que faz |
|------|-----------|
| `--no-backup` | não cria os arquivos `.bak.<timestamp>` ao sobrescrever |
| `--clean-backups` | roda normalmente e, no final, **apaga** os backups gerados nesta execução |
| `-h`, `--help` | mostra a ajuda |

Exemplos:

```sh
./setup-mac-dev.sh --no-backup        # nem cria backup
./setup-mac-dev.sh --clean-backups    # cria, usa e remove os backups ao terminar
```

---

## O que é instalado/configurado

| # | Item | Detalhe |
|---|------|---------|
| 1 | Pré-requisitos | confere `git` e `curl`; avisa (sem travar) se faltar Homebrew |
| 2 | **Oh My Zsh** | instalação unattended (pula se já existir) |
| 3 | **Plugins Zsh** | `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-autocomplete` |
| 4 | **`~/.gitconfig`** | identidade + dezenas de aliases + alias `cheat` |
| 5 | **`~/.gitignore`** global | macOS / Xcode / editores |
| 6 | **`~/.git-cheat.sh`** | cola de-para (`git cheat` / `gcheat`) |
| 7 | **`~/.zshrc`** | linha `plugins=(...)` + bloco custom (autocomplete, Ruby no PATH, alias `gcheat`) |

---

## A "cola" de comandos (de-para)

Depois de instalado:

```sh
git cheat            # mostra todos os comandos: atalho -> comando real -> o que faz -> exemplo
git cheat branch     # filtra por um termo
git cheat stash
gcheat push          # mesmo que `git cheat`, atalho de terminal
```

### Exemplos de atalhos do Git criados

| Atalho | Comando | O que faz |
|--------|---------|-----------|
| `git st` | `status` | estado dos arquivos |
| `git lg` | `log --oneline` | histórico compacto |
| `git graph` | `log --oneline --graph --all` | histórico visual |
| `git swc <branch>` | `switch -c` | cria e troca de branch |
| `git unstage <arq>` | `restore --staged` | tira do stage |
| `git amend` | `commit --amend --no-edit` | junta mudança ao último commit |
| `git pfl` | `push --force-with-lease` | force seguro |
| `git cheat` | — | abre a cola |

> Lista completa: rode `git cheat`.

---

## Segurança e repetição

- **Idempotente**: pode rodar várias vezes. A linha de `plugins=()` não se multiplica e o
  bloco custom do `.zshrc` (entre os marcadores `# >>> dev-setup >>>` e `# <<< dev-setup <<<`)
  é substituído, nunca duplicado.
- **Backup automático**: tudo que é sobrescrito (`.gitconfig`, `.zshrc`, `.gitignore`,
  `.git-cheat.sh`) vira `arquivo.bak.<timestamp>` antes de mudar.
- **Não inclui o lazygit**.

---

## O que o script NÃO faz

- Não copia repositórios.
- Não copia/gera chaves **SSH** (`~/.ssh`). No Mac novo, gere/transfira sua chave à parte:

  ```sh
  ssh-keygen -t ed25519 -C "voce@email.com"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  # depois adicione a chave pública (~/.ssh/id_ed25519.pub) no GitHub/GitLab/Azure
  ```

- Não instala o Homebrew automaticamente. Se faltar e você quiser o Ruby do Homebrew:

  ```sh
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install ruby
  ```

---

## Personalizar a cola

Edite o bloco `DATA` dentro de `~/.git-cheat.sh`, no formato:

```
Seção|atalho|comando real|o que faz|exemplo de uso
```

Use `=` no campo do atalho quando o comando não tiver um atalho próprio.

---

## Desfazer / restaurar

Cada execução gera backups com timestamp. Para voltar ao estado anterior, é só restaurar:

```sh
cp ~/.gitconfig.bak.<timestamp> ~/.gitconfig
cp ~/.zshrc.bak.<timestamp> ~/.zshrc
```
