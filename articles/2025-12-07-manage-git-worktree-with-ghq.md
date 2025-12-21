---
title: "Git Worktree & ghq 入門 ― Issue/PR 毎の環境を一発生成する便利スクリプトもあるよ！"
emoji: "🐴"
type: "tech"
topics:
  - "claudecode"
  - "ghq"
  - "git"
  - "gitworktree"
publication_name: "genda_jp"
published: true
published_at: 2025-12-07 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ3 Day 7 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

### 1.1. こんな悩みありますよね

- 機能開発中に緊急のバグ修正依頼が来た
- 複数の PR を同時にレビューしたい
- Issue 対応を並行して進めたい

忙しいときのあるあるシチュエーションです。
ブランチでの作業を一旦中断して、別の作業に取り掛かるために `git switch (git checkout)` や `git stash` で苦しんでいませんか？

### 1.2. この記事で紹介すること

Git Worktree と ghq を組み合わせて、Issue や PR ごとに独立した作業環境を構築する方法を紹介します。
さらに、紹介する便利スクリプトを使えば1コマンドで一発生成できます！

Issue 駆動開発への意識を高めやすいので AI との相性もばっちりです。

### 1.3. 事前準備

以下のツールを事前にインストールしておいてください。

| ツール      | 必須       | 用途                                            |
| ---         | ---        | ---                                             |
| git         | 必須       | バージョン 2.5 以上                             |
| ghq         | 必須       | リポジトリ管理                                  |
| gh          | 必須       | GitHub CLI。事前に `gh auth login` で認証が必要 |
| jq          | 必須       | JSON パーサー                                   |
| fzf or peco | オプション | リポジトリ移動の効率化                          |
| claude      | オプション | ブランチ名の自動生成。なくても動作する          |

インストールは以下のように進めればOKです。

```bash
# macOS (Homebrew)
brew install ghq gh jq fzf  # fzf の代わりに peco でもOK

# Ubuntu/Debian
sudo apt install gh jq fzf  # fzf の代わりに peco でもOK
# ghq は go install か GitHub Releases からインストール

# gh の認証
gh auth login
```

ghq の Homebrew 以外のインストール方法は公式リポジトリを参照してください。

@[card](https://github.com/x-motemen/ghq)

## 2. Git Worktree とは

Git Worktree は、1つのリポジトリから複数の作業ディレクトリを作成できる機能です。
Git 2.5 以降で使えます。

### 2.1. 何が嬉しいの？

- Issue ごと、PR ごとに独立した作業ディレクトリを持てる
- ブランチ切り替えや stash が不要になる
- `.git/` を共有するので Git hooks 等の設定が共通化される

### 2.2. ディレクトリ構成のイメージ

```text
project/                    # メインの作業ディレクトリ (main ブランチ)
project-issue-123-add-api/  # Issue #123 用の worktree
project-pr-456/             # PR #456 レビュー用の worktree
```

必ずしも同じディレクトリに作成する必要はなく、任意の場所に作成できます。

### 2.3. 基本コマンド

以降で紹介するスクリプトがあれば基本コマンドは使用しないのですが、一応押さえておきましょう。

```bash
# worktree を作成 (新規ブランチ)
git worktree add ../project-feature -b feature/new-feature

# worktree を作成 (既存ブランチ)
git worktree add ../project-feature feature/existing-branch

# worktree の一覧を表示
git worktree list

# worktree を削除 (rm -rf ではなくこのコマンドを使う)
git worktree remove ../project-feature
```

## 3. ghq とは

ghq はリポジトリを一元管理するツールです。

@[card](https://github.com/x-motemen/ghq)

### 3.1. 何が嬉しいの？

- リポジトリが `~/ghq/github.com/owner/repo` のような統一された構成で管理される
- `ghq list` で全リポジトリを一覧表示
    - fzf/peco と組み合わせるとリポジトリ間の移動が爆速になる

### 3.2. セットアップ

```bash
# root ディレクトリを設定 (任意の場所でいいですが大半の方は ~/ghq にすると思います)
git config --global ghq.root ~/ghq

# 設定を確認
git config --global ghq.root
```

### 3.3. 基本コマンド

```bash
# リポジトリをクローン (HTTPS)
ghq get https://github.com/owner/repo

# リポジトリをクローン (SSH)
ghq get -p owner/repo

# リポジトリの一覧を表示
ghq list

# fzf/peco でリポジトリを選択して移動
cd "$(ghq root)/$(ghq list | fzf)"
# または
cd "$(ghq root)/$(ghq list | peco)"
```

fzf/peco を実行するとインタラクティブな選択画面が表示されます。

- 文字を入力: リポジトリ名で絞り込み (あいまい検索)
- `↑` / `↓` または `Ctrl-p` / `Ctrl-n`: 候補を移動
- `Enter`: 選択して確定
- `Ctrl-c` または `Esc`: キャンセル

毎回このコマンドを打つのは面倒なので、エイリアスを登録しておくと便利です。

```bash
# ~/.zshrc や ~/.bashrc に追加
alias repo='cd "$(ghq root)/$(ghq list | fzf)"'
# または
alias repo='cd "$(ghq root)/$(ghq list | peco)"'
```

これで `repo` と打つだけでリポジトリを選択して移動できます。

### 3.4. ghq x Git Worktree の相性が最高

ghq と Git Worktree を組み合わせると、worktree も同じディレクトリ構成で管理できます。

```text
~/ghq/github.com/org/project/                    # メインリポジトリ
~/ghq/github.com/org/project-issue-123-add-api/  # Issue 用 worktree
~/ghq/github.com/org/project-pr-456/             # PR 用 worktree
```

`ghq list` で worktree も表示されるので、メインリポジトリと worktree をシームレスに行き来できます。

## 4. 便利スクリプトで一発生成！

ここからが本題です。
worktree の作成・削除を効率化するスクリプトを用意しました。

### 4.1. スクリプト一覧

| スクリプト | 用途 |
| --- | --- |
| `issue-worktree-create` | Issue 番号から worktree を一発生成 |
| `pr-worktree-create` | PR 番号から worktree を一発生成 |
| `worktree-remove` | worktree を安全に削除 |

### 4.2. インストール方法

```bash
# 1. ディレクトリを作成して PATH に追加
mkdir -p ~/.local/bin
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc

# 2. スクリプトをダウンロード
curl -o ~/.local/bin/issue-worktree-create \
  https://raw.githubusercontent.com/i9wa4/dotfiles/40944eb/bin/issue-worktree-create

curl -o ~/.local/bin/pr-worktree-create \
  https://raw.githubusercontent.com/i9wa4/dotfiles/40944eb/bin/pr-worktree-create

curl -o ~/.local/bin/worktree-remove \
  https://raw.githubusercontent.com/i9wa4/dotfiles/40944eb/bin/worktree-remove

# 3. 実行権限を付与
chmod +x ~/.local/bin/{issue-worktree-create,pr-worktree-create,worktree-remove}

# 4. インストール確認
which issue-worktree-create
```

上記は記事執筆時点のスクリプトをダウンロードするためのものです。
最新版を取得したい場合はこちらのリポジトリを確認してください。

@[card](https://github.com/i9wa4/dotfiles)

### 4.3. issue-worktree-create (Issue 用)

Issue 番号を指定するだけで worktree を一発生成！

@[card](https://github.com/i9wa4/dotfiles/blob/40944eb/bin/issue-worktree-create)

```bash
# 使い方 (対象リポジトリに cd してから実行)
cd ~/ghq/github.com/org/project
issue-worktree-create 123
issue-worktree-create 123 456 789  # 複数 Issue も可
```

出力例

```text
-> Fetching remote...

=== Processing Issue #123 ===
-> Fetching issue info...
-> Generating branch name...
* Branch name: issue-123-add-user-authentication
* Created worktree: /path/to/project-issue-123-add-user-authentication
* Created local branch: issue-123-add-user-authentication
-> Running repo-setup...
```

特徴

- Claude Code があれば Issue 内容からブランチ名を自動生成
- Claude Code がなくても `issue-123` のようなシンプルな名前で動作
- リモートに同名ブランチがあればチェックアウト、なければ新規作成
- `repo-setup` コマンドがあれば自動実行 (後述)
- `issue-` から始まるコマンドはあまりないので `is` あたりで Tab キーでコマンド補完できるはず

Claude Code によるブランチ名生成の詳細は Day 1 の記事で紹介しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-01-shell-script-claude-code)

チームでブランチ命名規則がある場合は、スクリプト内のプロンプトを修正することでカスタマイズできます。

```text
# デフォルトのプロンプト (スクリプト内)
Generate a short English slug (kebab-case) for a Git branch name from the following issue.
- Maximum 5 words
- Lowercase and hyphens only
- Remove special characters
- Start with a verb if possible

# カスタマイズ例: Issue 種別に応じたプレフィックス
以下の Issue から Git ブランチ名を生成してください。
- Issue の種別に応じてプレフィックスを決定:
  - feature/ 新機能
  - fix/ バグ修正
  - docs/ ドキュメント
- フォーマット: <プレフィックス><slug>
- slug 部分は英語で最大5単語程度
- 小文字とハイフンのみ
```

### 4.4. pr-worktree-create (PR レビュー用)

PR 番号を指定するだけで worktree を一発生成！
コードレビュー時に重宝します。

@[card](https://github.com/i9wa4/dotfiles/blob/40944eb/bin/pr-worktree-create)

```bash
# 使い方
pr-worktree-create 456
pr-worktree-create 456 789  # 複数 PR も可
```

出力例

```text
-> Fetching remote...

=== Processing PR #456 ===
-> Fetching PR #456 info...
* PR #456 branch: feature/add-new-api
-> Creating worktree...
* Created worktree: /path/to/project-pr-456
```

PR のヘッドブランチを自動取得してチェックアウトします。

- `pr-` から始まるコマンドはあまりないので `pr-` あたりで Tab キーでコマンド補完できるはず

### 4.5. worktree-remove (削除用)

worktree を安全に削除します。

@[card](https://github.com/i9wa4/dotfiles/blob/40944eb/bin/worktree-remove)

```bash
# ghq パス形式
worktree-remove github.com/org/project-issue-123-add-api

# 絶対パス
worktree-remove /Users/uma/ghq/github.com/org/project-issue-123

# 相対パス
worktree-remove ../project-issue-123

# 複数指定も可
worktree-remove github.com/org/project-issue-123 github.com/org/project-pr-456

# fzf/peco で選択して削除
worktree-remove "$(ghq list | fzf)"
# または
worktree-remove "$(ghq list | peco)"
```

出力例

```text
Processing: github.com/org/project-issue-123-add-api
  -> Removing worktree...
  * Removed: /Users/uma/ghq/github.com/org/project-issue-123-add-api

* Done.
```

特徴

- ghq のパス形式 (`github.com/org/repo`) で指定可能
- 通常のリポジトリ (非 worktree) は削除しない安全設計
- `--force` で削除するため、未コミットの変更があると失われる点に注意
- `worktree-` から始まるコマンドはあまりないので `wo` あたりで Tab キーでコマンド補完できるはず

### 4.6. repo-setup (オプション)

worktree 作成後に自動実行されるセットアップコマンドです。
リポジトリごとの初期設定を自動化できます。

@[card](https://github.com/i9wa4/dotfiles/blob/40944eb/bin/repo-setup)

repo-setup の例

```bash
#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# メインリポジトリの情報を取得
main_repo="$(git worktree list --porcelain | awk '/^worktree / {print $2; exit}')"
repo_name="$(basename "${main_repo}")"

# リポジトリごとの初期設定
case "${repo_name}" in
  "my-frontend-app")
    npm ci
    ;;
  "my-backend-api")
    # .env をコピー (worktree には .env が含まれないため)
    # とはいえ秘密情報の複製が増えるため、direnv 等を推奨
    if [[ -f "${main_repo}/.env" ]] && [[ ! -f .env ]]; then
      cp "${main_repo}/.env" .env
    fi
    ;;
esac

# Claude Code 用の作業ディレクトリを作成
# Issue 情報やレビュー結果などの作業メモを格納する
mkdir -p .i9wa4
```

`.i9wa4/` ディレクトリは global gitignore に追加しておくことで、どのリポジトリでも git 管理外にできます。

```bash
# global gitignore を設定 (デフォルトではここです)
git config --global core.excludesfile ~/.config/git/ignore

# .i9wa4/ (私の GitHub ユーザー ID) を global gitignore に追加
mkdir -p ~/.config/git
echo ".i9wa4/" >> ~/.config/git/ignore
```

詳細は Day 1 の記事を参照してください。

このスクリプトを `~/.local/bin/repo-setup` に配置して実行権限を付与すれば、worktree 作成時に自動実行されます。

## 5. 実際のワークフロー

### 5.1. Issue 対応フロー

```bash
# 1. Issue 用 worktree を作成
cd ~/ghq/github.com/org/project
issue-worktree-create 123

# 2. worktree に移動して作業
cd ../project-issue-123-add-api
# ... コーディング ...

# 3. PR 作成後、worktree を削除
worktree-remove github.com/org/project-issue-123-add-api
```

### 5.2. PR レビューフロー

```bash
# 1. PR 用 worktree を作成
cd ~/ghq/github.com/org/project
pr-worktree-create 456

# 2. worktree に移動してレビュー
cd ../project-pr-456
# ... コードレビュー、動作確認 ...

# 3. レビュー完了後、worktree を削除
worktree-remove github.com/org/project-pr-456
```

レビュー対象のコードをローカルで動かしながら確認できるので、手戻りが減ります。

### 5.3. 並行作業

```bash
# 複数の Issue を同時に対応
issue-worktree-create 123 456 789

# 各 worktree で独立して作業
cd ../project-issue-123-add-api    # API 追加
cd ../project-issue-456-fix-bug    # バグ修正
cd ../project-issue-789-update-docs  # ドキュメント更新
```

各 worktree は完全に独立しているので、ブランチの切り替えや stash の心配がありません。

## 6. 注意点

### 6.1. 同じブランチの重複チェックアウト

同じブランチを複数の worktree でチェックアウトすることはできません。
既に使用中のブランチで worktree を作成しようとするとエラーになります。

### 6.2. worktree の定期削除

不要な worktree を放置すると ghq + fzf/peco の邪魔になるので定期的に削除するようにしましょう。

```bash
# worktree の一覧を確認
git worktree list

# こちらでも確認可能
ghq list
```

なお worktree を削除してもブランチ自体は残ります。
ブランチも削除したい場合は別途 `git branch -D` を実行してください。

## 7. おわりに

Git Worktree と ghq を組み合わせることで、Issue 対応も PR レビューも快適になります。
この記事では私の自作スクリプトを紹介しましたが、ぜひ自分なりにカスタマイズしてみてください。
