---
title: "シェルスクリプト × Claude Code: 日常スクリプトへの導入実践"
emoji: "🐴"
type: "tech"
topics:
  - "claudecode"
  - "github"
  - "shellscript"
publication_name: "genda_jp"
published: true
published_at: 2025-12-01 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ1 Day 1 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

最近は AI コーディングエージェントをターミナルから利用する機会が増えてきました。

- Claude Code
- Codex CLI
- Gemini CLI
- GitHub Copilot CLI

など様々なツールが登場しています。

これらのツールは対話的に使うだけでなく、シェルスクリプトに組み込めます。
本記事では日常スクリプトに Claude Code を導入した実践例を紹介します。

:::message
本記事の内容は 2025年12月時点での検証結果に基づいています。
:::

## 2. 対象読者

- シェルスクリプトに抵抗がない方
- AI CLI ツールの活用に興味がある方

## 3. AI CLI ツールの非対話モード

各 AI CLI ツールには、プロンプトを渡して結果を受け取る非対話モードが用意されています。

### 3.1. 各ツールのコマンド

| ツール             | コマンド例                |
| ---                | ---                       |
| Claude Code        | `claude -p "プロンプト"`  |
| Gemini CLI         | `gemini "プロンプト"`     |
| GitHub Copilot CLI | `copilot -p "プロンプト"` |
| Codex CLI          | `codex exec "プロンプト"` |

### 3.2. シェルスクリプトでの利用における重要な違い

各ツールを試したところ、`$()` で変数に取り込む用途で大きな違いがありました。

```bash
# 理想的な動作
result=$(ai-tool "Hello と返してください")
echo "$result"  # => Hello
```

Claude Code だけが余計な出力なしで純粋な結果のみを返します。

他のツールは実行情報などが含まれ、`grep` 等で除去する手間が発生します。

というわけでシェルスクリプトへの組み込みには Claude Code が最適です。

## 4. 題材スクリプトの紹介

私が日常的に使っている `issue-worktree-create` というスクリプトを題材にします。

以下は執筆時点のバージョンのスクリプトです。

@[card](https://github.com/i9wa4/dotfiles/blob/ee547253107795444a7f56a7c1da52cba087de8a/bin/issue-worktree-create)

このスクリプトは GitHub Issue に対応する Git Worktree を作成するものです。

### 4.1. 解決したかった課題

初期は `issue-123` のような単純なブランチ名にしていました。

運用していると管理しやすくするためにブランチ名を適切に生成したくなりました。

### 4.2. 改善後のスクリプトの概要

このスクリプトは以下の処理を行います。

1. 引数で Issue 番号を受け取る
2. `gh` コマンドで Issue 情報を取得
3. Claude Code でブランチ名のスラッグを生成
4. `git worktree` で作業ディレクトリを作成

## 5. Claude Code の組み込み方法

### 5.1. 基本形

Claude Code の非対話モードは `-p` または `--print` オプションで利用できます。

```bash
result=$(claude -p "プロンプト")
```

### 5.2. 実際のコード

issue-worktree-create での実装例です。

```bash
if ! branch_slug=$(claude --print "以下のIssue情報から、Gitブランチ名として適切な英語の短いスラッグ(kebab-case)を生成してください。
- 最大5単語程度
- 小文字とハイフンのみ使用
- 特殊文字は除去
- 動詞から始めることを推奨

出力は英語のスラッグのみを返してください(説明不要)。

---
Issueタイトル: ${issue_title}
---
Issue本文:
${issue_body}
---
Issueコメント:
${issue_comments}
---" 2>/dev/null | tr -d '\n') || [[ -z $branch_slug ]]; then
    echo "Error: ブランチ名生成に失敗しました。" >&2
    exit 1
fi
```

### 5.3. プロンプト設計のポイント

#### 5.3.1. 出力形式を明確に指定する

```text
出力は英語のスラッグのみを返してください(説明不要)。
```

AI は親切に説明を付けたがりますが、シェルスクリプトでは純粋な結果だけが必要です。「説明不要」と明示することで余計な出力を防ぎます。

#### 5.3.2. 制約条件を箇条書きで示す

```text
- 最大5単語程度
- 小文字とハイフンのみ使用
- 特殊文字は除去
- 動詞から始めることを推奨
```

期待する出力の形式を具体的に示すことで、安定した結果が得られます。

#### 5.3.3. 入力情報を構造化して渡す

```text
---
Issueタイトル: ${issue_title}
---
Issue本文:
${issue_body}
---
```

AI が理解しやすいように、入力情報をセクションで区切って渡します。

### 5.4. エラーハンドリング

スクリプト冒頭でエラー検出を厳格にするための設定をしています。

```bash
set -o errexit   # コマンド失敗時に即終了
set -o nounset   # 未定義変数の参照でエラー
set -o pipefail  # パイプライン中のエラーも検出
```

特に `pipefail` が重要です。

- デフォルトではパイプラインの最後のコマンドの終了ステータスのみ評価される
- `pipefail` を有効にすると途中のコマンドの失敗も検出できる

Claude Code 呼び出し部分のエラーハンドリングは以下のようになっています。

```bash
if ! branch_slug=$(claude ... 2>/dev/null | tr -d '\n') || [[ -z $branch_slug ]]; then
    echo "Error: ブランチ名生成に失敗しました。" >&2
    exit 1
fi
```

- `2>/dev/null`: 標準エラー出力を破棄
- `tr -d '\n'`: 改行を除去
- `if !`: `pipefail` により `claude` 失敗時にこの条件が真になる
- `[[ -z $branch_slug ]]`: 出力が空の場合もエラーとして扱う

AI の呼び出しが失敗した場合はスクリプトを終了します。

- API やネットワークの問題が原因である可能性が高い
- 続行しても同じエラーが繰り返される

## 6. 応用アイデア

Claude Code の非対話モードはAIに安定した出力を期待できる場面で活用できます。

### 6.1. コミットメッセージの生成

```bash
commit_msg=$(GIT_PAGER=cat git diff --staged --no-color | claude -p "以下の差分から適切なコミットメッセージを1行で生成してください。Conventional Commits 形式で。出力はメッセージのみ。")
git commit -m "$commit_msg"
```

### 6.2. ファイル名のリネーム

```bash
new_name=$(claude -p "以下のファイル名を英語の kebab-case に変換してください。出力はファイル名のみ。: ${old_name}")
mv "${old_name}" "${new_name}"
```

### 6.3. ログの要約

```bash
summary=$(tail -100 /var/log/app.log | claude -p "以下のログから重要なイベントを3行で要約してください。")
echo "$summary"
```

## 7. おわりに

せっかく定額課金しているので応用範囲を広げて日常の様々な作業に活用していきたいですね。
