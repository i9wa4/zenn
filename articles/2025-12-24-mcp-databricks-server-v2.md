---
title: "Databricks MCP Server をアップデートしました"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "databricks"
  - "mcp"
publication_name: "genda_jp"
published: true
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は Databricks Advent Calendar 2025 シリーズ3 Day 23 の記事です。

@[card](https://qiita.com/advent-calendar/2025/databricks)

以前 Databricks MCP Server を Service Principal 認証対応させた記事を書きました。

@[card](https://zenn.dev/genda_jp/articles/2025-04-29-mcp-databricks-server-service-principal)

それから自分が使わないという理由で半年以上放置していましたが、必要になったので急遽アップデートを行いました。

@[card](https://github.com/i9wa4/mcp-databricks-server/)

本記事では主な変更点を紹介します。

## 2. 2025年4月時点での機能

前回の更新 (Service Principal 認証対応) 時点では以下の機能がありました。

- SQL クエリの実行
- スキーマ一覧の取得
- テーブル一覧の取得
- テーブルスキーマの取得
- Service Principal 認証対応

## 3. 2025年12月更新の主な変更点

### 3.1. Unity Catalog メタデータ探索ツールの追加

以下の機能を追加しました。

- カタログ一覧の取得
- スキーマ一覧の取得
- テーブル詳細の取得
- テーブルリネージ情報の取得 (上流/下流テーブル、関連ノートブック)

これにより Unity Catalog のメタデータを探索しやすくなりました。

### 3.2. 危険な SQL コマンドのブロック機能

安全性を考慮し、以下の SQL ステートメントをブロックするようにしました。

- DROP
- DELETE
- TRUNCATE
- ALTER
- CREATE
- INSERT
- UPDATE
- MERGE
- GRANT
- REVOKE

AI エージェントが誤って破壊的なクエリを実行することを防ぎます。
Service Principal 認証に対応しているのでそもそも権限自体を制限しやすくなっていますが、二重の安全策として有効です。

### 3.3. 認証方式の改善

設定の優先順位が分かりづらかったりコンフリクトしやすい `.env` ファイル等の環境変数優位な設定から `~/.databrickscfg` を使用する方式に変更しました。

Databricks CLI や SDK と同じ設定ファイルを共有できるため、設定の一元管理が可能になりました。

```ini
# ~/.databrickscfg の例
[DEFAULT]
host = https://your-workspace.cloud.databricks.com
token = dapi_your_personal_access_token
warehouse_id = your_warehouse_id
```

`DATABRICKS_CONFIG_PROFILE` 環境変数でプロファイルを切り替えることも可能です。

### 3.4. SQL 実行の SDK 統一

従来は SQL 実行に REST API を直接呼び出していましたが、Databricks SDK に統一しました。

これにより、認証処理や API 呼び出しのロジックがシンプルになりました。

### 3.5. モダンな Python プロジェクト構造

以下の記事のようにプロジェクト構造を改善しました。

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

## 4. 設定例

MCP Server の設定例です。

```json
{
  "mcpServers": {
    "databricks": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/mcp-databricks-server",
        "run",
        "mcp-databricks-server"
      ],
      "env": {
        "DATABRICKS_CONFIG_PROFILE": "DEFAULT"
      },
      "disabled": false
    }
  }
}
```

`DATABRICKS_CONFIG_PROFILE` 環境変数は任意です。
設定しない場合は `~/.databrickscfg` の `DEFAULT` プロファイルが使用されます。

## 5. おわりに

データ分析に使いやすい MCP サーバーに進化したと思います！

ぜひお試しください。
