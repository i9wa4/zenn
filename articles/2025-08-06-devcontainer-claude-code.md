---
title: "Claude Code 対応 Dev Container 環境構築編 ― VS Code でもそれ以外でも"
emoji: "🏗️"
type: "tech"
topics:
  - "claudecode"
  - "devcontainer"
  - "docker"
  - "vscode"
published: true
published_at: 2025-08-06 19:00
publication_name: "genda_jp"
---

本記事は3部構成の1本目です。

1. Claude Code 対応 Dev Container 環境構築編 - VS Code でもそれ以外でも
2. [Python 開発環境最適化編 - uv + pre-commit + GitHub Actions](2025-08-06-python-env-optimization)
3. [Databricks Connect 実践編 - ローカルから Databricks コンピュートを利用](2025-08-06-databricks-connect-practice)

## 1. はじめに

Claude Codeを使いたいけれど環境構築が面倒、チーム全員に同じ開発環境を提供したい、そんな悩みをサクッと解決します。

この記事では Anthropic のリファレンス実装をベースに、実用的にカスタマイズしたDev Container設定を紹介します。

## 2. 対象読者

- Claude Code を使いたいが環境構築を簡単にしたい方
- チーム開発で統一された開発環境を提供したい方

## 3. 前提知識

### 3.1. Dev Container とは

Dev Container は VS Code でコンテナを開発環境として利用できる便利機能です。

今回の設定をチームで共有すれば全員に同じ開発環境を提供できます。

VS Code以外のエディタでも Dev Container CLI を利用することで恩恵を受けることができます。

### 3.2. Claude Code in Dev Container

Claude Code を Dev Container で利用する方法について2通り紹介します。

#### 3.2.1. devcontainer.json の features を利用する

こちらが簡単な方法です。

以下に Anthropic が提供している Dev Container feature を利用する方法が記載されています。

@[card](https://github.com/anthropics/devcontainer-features/blob/main/src/claude-code/README.md)

抜粋すると以下の通りです。

```json:.devcontainer/devcontainer.json
"features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {}
}
```

#### 3.2.2. Dockerfile を利用する

本家のリファレンス実装を利用する方法です。

以下が Claude Code 向け Dev Container について記載されている公式ドキュメントです。

@[card](https://docs.anthropic.com/en/docs/claude-code/devcontainer)

この中でリファレンス実装として Claude Code 自身の Dev Container 設定が紹介されています。

@[card](https://github.com/anthropics/claude-code/tree/main/.devcontainer)

```sh
.devcontainer
├── devcontainer.json
├── Dockerfile
└── init-firewall.sh
```

このリファレンス実装を参考にしつつ私が使いやすいようにカスタマイズしたものを以下で紹介していきます。

## 4. Dev Container 設定

### 4.1. VS Code 側の準備

Dev Container 拡張をインストールしておく必要があります。

@[card](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### 4.2. Dockerfile

Anthropic のリファレンス実装をベースにして以下のような Dockerfile を作成しました。

見て分かる通り hadolint で結構指摘が出る書き味ですが特に意思もないのでそのままにしています。

:::details .devcontainer/Dockerfile

```dockerfile:.devcontainer/Dockerfile
FROM node:20

ARG TZ
ENV TZ="$TZ"

# Install basic development tools and iptables/ipset
RUN apt update && apt install -y less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_0.18.2_${ARCH}.deb" && \
  rm "git-delta_0.18.2_${ARCH}.deb"

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Default powerline10k theme
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude
RUN npm install -g @anthropic-ai/claude-code

# Python environment setup (if needed)
# Copy uv binary from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

USER node
```

Anthropic のリファレンス実装と比較すると以下のような変更を行っています。

- firewall スクリプト対応部分を削除
- uv インストール部分を追加

```diff
$ diff -u ../../anthropics/claude-code/.devcontainer/Dockerfile .devcontainer/Dockerfile
--- ../../anthropics/claude-code/.devcontainer/Dockerfile       2025-07-26 16:16:50
+++ .devcontainer/Dockerfile    2025-07-26 23:24:59
@@ -69,10 +69,8 @@
 # Install Claude
 RUN npm install -g @anthropic-ai/claude-code

-# Copy and set up firewall script
-COPY init-firewall.sh /usr/local/bin/
-USER root
-RUN chmod +x /usr/local/bin/init-firewall.sh && \
-  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
-  chmod 0440 /etc/sudoers.d/node-firewall
+# Python environment setup (if needed)
+# Copy uv binary from official image
+COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
+
 USER node
```

:::

### 4.3. devcontainer.json

以下のような `devcontainer.json` を作成しました。

こちらは Anthropic のリファレンス実装に比べると割と変更点が多いです。

:::details .devcontainer/devcontainer.json

```json:.devcontainer/devcontainer.json
{
    "name": "Claude Code Development Environment",
    "build": {
        "dockerfile": "Dockerfile",
        "args": {
            "TZ": "${localEnv:TZ:Asia/Tokyo}"
        }
    },
    "runArgs": [
        "--cap-add=NET_ADMIN",
        "--cap-add=NET_RAW"
    ],
    "customizations": {
        "vscode": {
            "extensions": [
                "editorconfig.editorconfig",
                "elagil.pre-commit-helper"
            ],
            "settings": {
                "terminal.integrated.defaultProfile.linux": "zsh",
                "terminal.integrated.profiles.linux": {
                    "bash": {
                        "path": "bash",
                        "icon": "terminal-bash"
                    },
                    "zsh": {
                        "path": "zsh"
                    }
                }
            }
        }
    },
    "remoteUser": "node",
    "mounts": [
        "source=${localEnv:CLAUDE_CONFIG_DIR},target=/home/node/.claude,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.config/gh,target=/home/node/.config/gh,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.config/git,target=/home/node/.config/git,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.gitconfig,target=/home/node/.gitconfig,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.ssh,target=/home/node/.ssh,type=bind,consistency=cached",
        "source=claude-code-bashhistory-${devcontainerId},target=/commandhistory,type=volume"
    ],
    "remoteEnv": {
        "CLAUDE_CONFIG_DIR": "/home/node/.claude",
        "NODE_OPTIONS": "--max-old-space-size=4096",
        "POWERLEVEL9K_DISABLE_GITSTATUS": "true"
    },
    "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
    "workspaceFolder": "/workspace"
}
```

Anthropic のリファレンス実装と比較すると以下のような変更を行っています。

- VS Code 向け拡張機能を追加
    - `editorconfig.editorconfig`
        - テキストエディタ間での設定を統一する
    - `elagil.pre-commit-helper`
        - pre-commit を使いやすくする
- VS Code 向け Formatter 設定を削除
- `mounts` に設定ファイル群を追加
    - 以下のツールの設定ファイルをマウントして利用します
        - Claude Code
        - GitHub CLI
        - Git
        - ssh
- `mounts` の Claude Code 設定分離部分を削除
    - ユーザー設定をマウントして利用したかったので削除しました
- `remoteEnv` に以下の環境変数を追加
    - `CLAUDE_CONFIG_DIR`
        - Claude Code の設定参照箇所の安定化を図る

:::

## 5. 利用手順

### 5.1. Claude Code 設定

Claude Code の設定ディレクトリを環境変数で指定しておきます。

```sh:~/.bashrc または ~/.zshrc
export CLAUDE_CONFIG_DIR="$HOME/.claude"
```

### 5.2. Dev Container VS Code

1. F1 -> "Dev Containers: Open Folder in Container..." を選択します
2. Claude Code はインストール済みなのでターミナルから起動できます

### 5.3. Dev Container CLI

VS Code を使わない場合は Dev Container CLI を利用できます。

```sh
# Dev Container CLI のインストール
npm install -g @devcontainers/cli

# コンテナ起動
devcontainer up --workspace-folder .

# コンテナに接続
devcontainer exec --workspace-folder . zsh
```

## 6. おわりに

これで Claude Code が使える開発環境の完成です。

次回はこの環境に Python 開発環境を追加する方法を紹介します。

[Python 開発環境最適化編 - uv + pre-commit + GitHub Actions](2025-08-06-python-env-optimization)
