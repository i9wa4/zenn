---
title: "Git Worktree & ghq 入門 ― Issue/PR 毎の環境を一発生成する便利スクリプトもあるよ！"
emoji: "🐴"
type: "tech"
topics:
  - "git"
  - "gitworktree"
  - "ghq"
  - "claudecode"
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

### 1.2. この記事で紹介すること

Git Worktree と ghq を組み合わせて、Issue や PR ごとに独立した作業環境を構築する方法を紹介します。
さらに、紹介する便利スクリプトを使えば1コマンドで一発生成できます！

Issue 駆動開発への意識を高めやすいので AI との相性もばっちりです。

### 1.3. 事前準備

以下のツールを事前にインストールしておいてください。

| ツール | 必須       | 用途                                            |
| ---    | ---        | ---                                             |
| git    | 必須       | バージョン 2.5 以上                             |
| ghq    | 必須       | リポジトリ管理                                  |
| gh     | 必須       | GitHub CLI。事前に `gh auth login` で認証が必要 |
| jq     | 必須       | JSON パーサー                                   |
| fzf    | オプション | リポジトリ移動の効率化                          |
| claude | オプション | ブランチ名の自動生成。なくても動作する          |

インストールは以下のように進めればOKです。

```bash
# macOS (Homebrew)
brew install ghq gh jq fzf

# Ubuntu/Debian
sudo apt install gh jq fzf
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
    - fzf と組み合わせるとリポジトリ間の移動が爆速になる

### 3.2. セットアップ

```bash
# root ディレクトリを設定 (任意の場所でいいですが大半の方は ~/ghq にすると思います)
git config --global ghq.root ~/ghq
```

### 3.3. 基本コマンド

```bash
# リポジトリをクローン (HTTPS)
ghq get https://github.com/owner/repo

# リポジトリをクローン (SSH)
ghq get -p owner/repo

# リポジトリの一覧を表示
ghq list

# fzf でリポジトリを選択して移動
cd "$(ghq root)/$(ghq list | fzf)"
```

毎回このコマンドを打つのは面倒なので、エイリアスを登録しておくと便利です。

```bash
# ~/.zshrc や ~/.bashrc に追加
alias repo='cd "$(ghq root)/$(ghq list | fzf)"'
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
  https://raw.githubusercontent.com/i9wa4/dotfiles/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/issue-worktree-create

curl -o ~/.local/bin/pr-worktree-create \
  https://raw.githubusercontent.com/i9wa4/dotfiles/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/pr-worktree-create

curl -o ~/.local/bin/worktree-remove \
  https://raw.githubusercontent.com/i9wa4/dotfiles/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/worktree-remove

# 3. 実行権限を付与
chmod +x ~/.local/bin/issue-worktree-create
chmod +x ~/.local/bin/pr-worktree-create
chmod +x ~/.local/bin/worktree-remove

# 4. インストール確認
which issue-worktree-create
```

上記は記事執筆時点のスクリプトをダウンロードするためのものです。
最新版を取得したい場合はこちらのリポジトリを確認してください。

@[card](https://github.com/i9wa4/dotfiles)

### 4.3. issue-worktree-create (Issue 用)

Issue 番号を指定するだけで worktree を一発生成！

https://github.com/i9wa4/dotfiles/blob/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/issue-worktree-create

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

### 4.4. pr-worktree-create (PR レビュー用)

PR 番号を指定するだけで worktree を一発生成！
コードレビュー時に重宝します。

https://github.com/i9wa4/dotfiles/blob/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/pr-worktree-create

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

https://github.com/i9wa4/dotfiles/blob/a8edc17f15e2792545ab8346f48c6df4610aa8a4/bin/worktree-remove

```bash
# ghq パス形式
worktree-remove github.com/org/project-issue-123-add-api

# 絶対パス
worktree-remove /Users/uma/ghq/github.com/org/project-issue-123

# 相対パス
worktree-remove ../project-issue-123

# 複数指定も可
worktree-remove github.com/org/project-issue-123 github.com/org/project-pr-456
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

repo-setup の例

```bash
#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# npm プロジェクトなら依存関係をインストール
if [[ -f package.json ]]; then
  npm install
fi

# メインリポジトリの .env をコピー (worktree には .env が含まれないため)
main_repo="$(git worktree list | head -1 | awk '{print $1}')"
if [[ -f "${main_repo}/.env" ]] && [[ ! -f .env ]]; then
  cp "${main_repo}/.env" .env
fi

# Claude Code 用の作業ディレクトリを作成 (Day 1 参照)
mkdir -p .i9wa4
```

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

不要な worktree を放置すると ghq + fzf の邪魔になるので定期的に削除するようにしましょう。

```bash
# worktree の一覧を確認
git worktree list

# こちらでも確認可能
ghq list
```

なお、worktree を削除してもブランチ自体は残ります。
ブランチも削除したい場合は別途 `git branch -D` を実行してください。

## 7. おわりに

Git Worktree と ghq を組み合わせることで、Issue 対応も PR レビューも快適になります。
この記事では私の自作スクリプトを紹介しましたが、ぜひ自分なりにカスタマイズしてみてください。
