---
title: "Vim/Neovim の dbt 開発環境の現状と Vim を救う話"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "dbt"
  - "neovim"
  - "vim"
published: true
published_at: 2024-12-02 07:00
publication_name: "genda_jp"
---

## 1. はじめに

こんにちは。MLOps エンジニア/データエンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2024 2日目の記事です。

@[card](https://qiita.com/advent-calendar/2024/genda)

私が業務でよく利用する dbt のローカル開発環境の話をしていきます。

## 2. dbt とは

dbt について知りたい方がおそらく最初に読む記事から抜粋。

@[card](https://zenn.dev/dbt_tokyo/books/537de43829f3a0/viewer/what_dbt)

> dbt（正式名称はdata build tool）はデータアナリストやアナリティクスエンジニアが（ほぼ）SQLだけで、データを変換しデータウエアハウス、データマートを構築していくことができるツールです。

FROM 句内のサブクエリの部分を別の SQL ファイルに切り出していく形で想像すると大体合ってるはず。
SELECT 文の書かれた SQL ファイル (モデルといいます) が複数あって FROM 句内で SQL ファイル名 (モデル) を指し示すことでモデル同士の依存関係を表現しています。

## 3. dbt 開発環境に求めること

個人の主観で列挙します。

1. dbt 向け SQL ファイルのフォーマッタである [sqlfmt](https://github.com/tconbeer/sqlfmt) が動くこと
   - フォーマッタを動かすというテキストエディタとしては基本的な部分なので、重要ではあるものの今回は割愛します
2. dbt コマンドとの連携
   - 手数少なく `dbt run` などのコマンドを実行できること
3. 定義参照・自動補完のようなモダンな編集機能 (LSP)
   - 最近の開発ではこれらがないと非効率ですが dbt 向け LSP (各テキストエディタが共通で利用できるコア機能) が提供されていないため各テキストエディタが自前で対応する必要があります

## 4. 2024年現在の dbt 開発環境

### 4.1. VS Code

ベンチマークとして VS Code について言及します。
やはり圧倒的に使いやすいです。
以下の拡張機能を使用するのが現状の最適解です。

@[card](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user)

日本語解説記事は以下をはじめとして複数投稿されています。

@[card](https://www.yasuhisay.info/entry/2023/07/09/120000)

### 4.2. Neovim

VS Code 向け拡張機能に比べると提供されている機能の数は少ないものの十分に豊富な機能をもつプラグインが提供されています。

@[card](https://github.com/PedramNavid/dbtpal)

### 4.3. Vim

以下のプラグインでシンタックスハイライトといくつかの dbt コマンド連携機能が提供されています。

@[card](https://github.com/chrismaher/vim-dbt)

正直なところ機能が少ないので Vim ではなく Neovim もしくは VS Code を使うことをおすすめします。

## 5. Vim の救済

……ですが Vim でも dbt 開発をしたいですよね！
なんといっても私の好きなエディタですし。
というわけで最低限欲しかったモデル定義へのジャンプ機能のプラグインを作りました。

@[card](https://github.com/i9wa4/vim-dbt-jump2def)

インストール方法や使い方は README を参照してください。
ジャンプ機能はコマンドで提供したので各自好みのキーマッピングを設定することをオススメします。

ちなみに Vim/Neovim 両対応のフレームワークである Denops で書いたので Neovim でも使えます。
そしてこの際なので他の Denops プラグインの沼にもハマっていきましょう。。

## 6. おわりに

今回プラグインを作るために Denops や Deno の情報収集をしつつ、慣れない TypeScript を書いていたのですが結構楽しかったです。

## 7. 宣伝
