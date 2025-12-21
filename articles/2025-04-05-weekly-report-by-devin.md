---
title: "Devin に週報を書いてもらった"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "devin"
  - "github"
published: true
publication_name: "genda_jp"
---

## 1. はじめに

こんにちは。データエンジニア / MLOps エンジニアの uma-chan です。

最近 Devin で遊びながら勘所を掴んでいる最中です。
題材として丁度よかったので週報作成を Devin にやらせてみることにしました。

## 2. 週報作成の概要

集計期間の GitHub の issue と pull request の情報を基に各メンバーの活動の概要と詳細を issue にまとめてもらいます。

## 3. Devin へのプロンプト

長文プロンプトを用意する必要があります。
Devin では Playbook を利用すればよいですね。
今回はリポジトリ内の Markdown ファイルを参照させてます。

Zenn では Markdown ブロックの入れ子表現ができなかったため別記事に分けてます。

@[card](https://zenn.dev/genda_jp/articles/2025-04-05-weekly-report-prompt-for-devin)

生の Markdown は以下を参照してください。

@[card](https://github.com/i9wa4/zenn-i9wa4/blob/main/articles/2025-04-05-weekly-report-prompt-for-devin.md?plain=1)

上に書いたような長文プロンプトを用意した上で以下のように Devin に指示を出します。

> 以下の Markdown の指示に従って情報収集を行った上で GitHub issue を作成してください。
> <プロンプトとなるMarkdownのURL>
>
> 集計開始日：2025/03/12
> 集計終了日：2025/03/18

## 4. Devin へのプロンプトを書く上でのコツ

### 4.1. Devin というか LLM の忘れっぽさへの対処

長文だとどうしても近眼的に周囲数行の記述に引っぱられてしまうので、大枠の構造を提示しつつ、詳細は具体例とピンポイントなコメントという書き味にすることで出力が安定しました。

今回各メンバーを列挙する箇所がありますが、横着せず愚直に列挙しました。
冗長だなあと思いつつもこうすることで Devin が忘れずに全メンバーの情報収集をしてくれました。

### 4.2. GitHub CLI の仕様への対処

Devin がうまく情報収集してくれないことがあるので GitHub CLI の仕様を理解し適切なコマンドを実行できているか見ておく必要があります。
今回は `--state all` オプションを指定して閉じられた issue なども取得させるように指示を出しています。

また、issue の description が長文になると文章を分割して編集追加させなければならなくなるので issue の description とコメントの行数を想定した上で適度に分割しておくと良いでしょう。
もし長文投稿させたい場合は作成した issue を読み込ませて見切れてないか Devin に確認させるのも良いかもしれません。
