---
title: "Zenn の記事を GitHub リポジトリで管理する"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "github"
  - "zenn"
published: true
published_at: 2024-11-20 18:00
---

## 1. はじめに

初投稿なので新鮮な気持ちで Zenn 公式の記事を見ながら GitHub リポジトリ経由で Zenn の記事を投稿するまでの手順をまとめます。

## 2. 手順

### 2.1. 前準備

1. リポジトリ作成から連携までを済ませる。
   - [GitHubリポジトリでZennのコンテンツを管理する](https://zenn.dev/zenn/articles/connect-to-github)
1. Zenn CLI をインストールする。
   - [Zenn CLIをインストールする](https://zenn.dev/zenn/articles/install-zenn-cli)
1. リポジトリ内に作成されたファイルをコミットしておく。

### 2.2. 記事の作成

以下の記事に従うと記事を書くことができます。

[Zenn CLIで記事・本を管理する方法](https://zenn.dev/zenn/articles/zenn-cli-guide)

## 3. 実際に作成していて気付いた点

### 3.1. スラッグを最初に指定する

```sh
npx zenn new:article
```

で記事に対応する Markdown ファイルを作成するとスラッグ (記事IDのことで公開時のファイル名と思ってよい) としてランダムな文字列が割り当てられます。
リポジトリで記事を管理する上で無意味なファイル名が並ぶのは辛いので以下のどちらかの対応を取りましょう。

- スラッグを指定して記事作成コマンドを実行する

    ```sh
    npx zenn new:article --slug 2024-11-20-manage-zenn-with-github
    ```

- **公開前に** ファイル名を変更する

### 3.2. YAML ヘッダの `topics:` の各要素はハイフンで書く

YAML ヘッダの記載例として以下のように記載されています。

[Zenn CLIで記事・本を管理する方法](https://zenn.dev/zenn/articles/zenn-cli-guide)

```md
---
title: "" # 記事のタイトル
emoji: "😸" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: [] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---
ここから本文を書く
```

個人的には

```md
---
topics: ["markdown", "rust", "aws"]
---
```

よりも

```md
---
topics:
  - "markdown"
  - "rust"
  - "aws"
---
```

の方が行ソートで重複を見つけやすいので好きです。

### 3.3. 会社テックブログ向けの予約投稿

会社の Publication から予約投稿するには以下でよさそうです。

```md
---
published: true
published_at: 2024-11-20 18:00
publication_name: "Publication Name"
---
```

(参考) [【Zenn】PublicationでもGitHub連携したい！自由選択型アプローチのすゝめ](https://zenn.dev/open8/articles/zenn-publication-github)

ただこれだといきなり投稿されて、かつ公開前のレビューのために個人のリポジトリのPRを見せる面倒臭さが発生します。
個人リポジトリの利用を前提として事前に内容を秘匿する場合はローカルで作成したプレビューを PDF 化していこうかなと考えています。

(2024/11/21 追記) 以下でプッシュしてしまえば下書き状態で Publication 内に共有できる (はず) ということに気付きました。

```md
---
published: false
publication_name: "Publication Name"
---
```

## 4. おわりに

取り急ぎこの記事が無事投稿できていれば OK です！
自分は新規投稿する度に本記事を見直すことになりそうです。
