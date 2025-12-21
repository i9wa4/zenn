---
title: "Claude Code で drawio 向け Skills を作成して使ってみた"
emoji: "🐴"
type: "tech"
topics:
  - "aws"
  - "claudecode"
  - "drawio"
publication_name: "genda_jp"
published: true
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 7 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

### 1.1. この記事について

以前 draw.io のコツをまとめた記事を書きました。

@[card](https://zenn.dev/genda_jp/articles/2025-12-12-drawio-tips-claude-code)

本記事では、この知見を Claude Code の Skills としてパッケージ化する方法を紹介します。

### 1.2. Skills を使う理由

draw.io の図を描かせるたびに同じ指示を繰り返すのは非効率です。

- fontFamily の指定忘れ
- 矢印の配置ルール
- AWS アイコンの正しい指定方法

これらを Skills として定義しておけば、draw.io 関連のタスクを依頼するだけで自動的にルールが適用されます。

## 2. Skills の基本

### 2.1. Skills とは

Skills は Claude Code が動的に読み込む命令とリソースのフォルダです。会話の文脈に応じて自動的に発動します。

### 2.2. 他の機能との違い

| 機能              | 発動タイミング         |
| ---               | ---                    |
| CLAUDE.md / rules | 常時読み込み           |
| slash commands    | ユーザーが明示的に実行 |
| Skills            | 会話に基づき自動判断   |

詳細は以下を参照してください。

@[card](https://blog.atusy.net/2025/12/15/claude-code-user-config/)

### 2.3. Rules ではなく Skills を選ぶ理由

`.drawio` ファイルに対するルールなら Rules でも実現できそうに見えます。両者の違いを整理します。

| 項目             | Rules                     | Skills                                     |
| ---              | ---                       | ---                                        |
| 読み込み         | 起動時に全て読み込み (※) | description のみ先読み、必要時にフルロード |
| コンテキスト消費 | 常に消費 (※)             | 必要になるまで消費しない                   |
| パス制限         | `paths: **/*.drawio` 可能 | description で判断                         |
| ファイル構成     | 単一ファイル              | SKILL.md + 複数ファイル対応                |

:::message
(※) Path-specific Rules は動的読み込みの可能性があります

@[tweet](https://x.com/oikon48/status/1998710902854660528)
:::

draw.io の場合、以下の理由から Skills が適切です。

- `.drawio` ファイルを扱うときだけ必要 (毎回ではない)
- AWS アイコン一覧、検索スクリプトなど複数ファイルが必要
- 複数ファイル構成をまとめて管理したい

Rules の Path-specific でも `paths: **/*.drawio` で限定はできますが、複数ファイル構成 (references/, scripts/) を扱うなら Skills の方が向いています。

## 3. Skills の作成手順

Anthropic 公式の Skills リポジトリを参考に進めます。

@[card](https://github.com/anthropics/skills)

### 3.1. プラグインのインストール

anthropic/skills をプラグインとしてインストールします。

```sh
# マーケットプレイスを登録
/plugin marketplace add anthropics/skills

# example-skills をインストール (skill-creator 含む)
/plugin install example-skills@anthropic-agent-skills
```

example-skills には以下のカテゴリの Skills が含まれています。

- Creative & Design
- Development & Technical (skill-creator はここに含まれる)
- Enterprise & Communication

### 3.2. 既存の知見を投げ込む

Claude Code に以下のように依頼するだけで Skills を作成できます。

```text
draw.io の図を描くための Skills を作成したい。
以下の情報を参考にしてほしい。

[既存の記事やメモの内容をここに貼り付け]
```

skill-creator が対話的に SKILL.md を生成してくれます。配置場所も聞いてくれるので、指示に従うだけです。

投げ込むコンテキストとして、執筆時点では以下のような情報が参考になると思います。

```text
# draw.io Tips
https://zenn.dev/genda_jp/articles/2025-12-12-drawio-tips-claude-code
https://drawio-app.com/blog/5-tips-to-optimize-your-draw-io-diagrams/
https://drawio-app.com/blog/draw-io-tips-for-pre-diagramming-prep/
https://drawio-app.com/blog/automatic-layout-in-draw-io/

# AWS アーキテクチャ図
https://dev.classmethod.jp/articles/trial-and-error-aws-diagram-agent-skills/

# デザイン原則
https://www.atlassian.com/work-management/project-management/architecture-diagram
https://learn.microsoft.com/en-us/azure/well-architected/architect-role/design-diagrams
```

## 4. 使用方法

Skills を配置したら、あとは普通に依頼するだけです。

```text
AWS のサービスのみを使用した、よくあるできるだけ複雑なデータパイプラインのアーキテクチャ図を draw.io 形式で作成してください。
サービス同士がスパゲッティのように矢印で接続しているような複雑な図が見たいです。
```

![aws-architecture-diagram](/images/2025-12-15-drawio-skills-claude-code/aws-data-pipeline.drawio.png)
<!-- rumdl-disable MD036 -->
*とんでもないことになった……*
<!-- rumdl-enable MD036 -->

## 5. おわりに

Skills デビューとしてちょうどいい題材でした！みなさんもぜひ試してみてください。

## 6. 参考リンク

### 6.1. Claude Code

@[card](https://github.com/anthropics/skills)

@[card](https://code.claude.com/docs/en/skills)

@[card](https://blog.atusy.net/2025/12/15/claude-code-user-config/)

### 6.2. draw.io Tips

@[card](https://zenn.dev/genda_jp/articles/2025-12-12-drawio-tips-claude-code)

@[card](https://drawio-app.com/blog/5-tips-to-optimize-your-draw-io-diagrams/)

@[card](https://drawio-app.com/blog/draw-io-tips-for-pre-diagramming-prep/)

@[card](https://drawio-app.com/blog/automatic-layout-in-draw-io/)

### 6.3. AWS アーキテクチャ図

@[card](https://dev.classmethod.jp/articles/trial-and-error-aws-diagram-agent-skills/)

### 6.4. デザイン原則

@[card](https://www.atlassian.com/work-management/project-management/architecture-diagram)

@[card](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/design-diagrams)
