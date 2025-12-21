---
title: "Databricks MCP Server を Service Principal 認証対応させた"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "databricks"
  - "mcp"
published: true
publication_name: "genda_jp"
---

## 1. はじめに

@[card](https://github.com/RafaelCartenet/mcp-databricks-server)

上記の Databricks MCP Server を Service Principal 対応させたものを以下に公開しました。

@[card](https://github.com/i9wa4/mcp-databricks-server/)

存在意義と利用方法について説明します。

## 2. Service Principal とは

@[card](https://docs.databricks.com/gcp/ja/admin/users-groups/service-principals)

> サービスプリンシパルは、自動化とプログラムによるアクセス用に設計された Databricks の特殊な ID です。 サービスプリンシパル は、自動化されたツールとスクリプトに API のみのアクセスを Databricks リソースに付与し、users アカウントを使用するよりも優れたセキュリティを提供します。

一言でまとめると人間に紐付かない ID なので適切な権限管理ができます！

## 3. 存在意義

Databricks MCP Server を含む AI エージェントを社内展開しようと思っています。

ただ、Databricks MCP Server に必要な Token として私のアカウントで作成する Personal Access Token を使うのは権限が強すぎるのとクエリ履歴管理上良くないため Service Principal を使うようにしたかったのです。

## 4. 利用方法

@[card](https://github.com/i9wa4/mcp-databricks-server/)

こちらの README に記載していますが、fork 元と異なる点は環境変数として下の3つを読み込める状態にすることです。

ちなみに Service Principal 認証の場合は `DATABRICKS_TOKEN` は不要です。

```sh
export DATABRICKS_HOST="your-databricks-instance.cloud.databricks.com"
export DATABRICKS_TOKEN="your-databricks-access-token"
export DATABRICKS_SQL_WAREHOUSE_ID="your-sql-warehouse-id"
# for OAuth authentication
export DATABRICKS_CLIENT_ID="your-client-id"
export DATABRICKS_CLIENT_SECRET="your-client-secret"
export DATABRICKS_AUTH_TYPE="oauth"
```

`DATABRICKS_CLIENT_ID` と `DATABRICKS_CLIENT_SECRET` の作成方法は以下のドキュメントを参考にしてください。

@[card](https://docs.databricks.com/aws/ja/dev-tools/auth/oauth-m2m)

## 5. おまけ：実装上の工夫

手元で Formatter を効かせてしまった都合で fork 元に Pull Request を出すのはちょっと難しくなってしまったのですが、それでも差分をできるだけ小さくしておきました。

ヘッダ作成に必要なトークン取得部分を同期関数にして、その中で OAuth or PAT という形で分岐させる構成が結構良い感じに書けたのではないかと思います。
OAuth を優先してる都合でここは非同期にはできないですよね。
