---
title: "databricks-goose-starter を作りました ― 開発者でなくても使える AI コーディング環境"
emoji: "🦆"
type: "tech"
topics:
  - "databricks"
  - "devcontainer"
  - "goose"
  - "jupyter"
  - "mcp"
publication_name: "genda_jp"
published: false
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。

技術部門以外のメンバー (データアナリストなど) にも AI コーディング環境を提供したい、そんな課題を解決する Dev Container テンプレートを OSS として公開しました。

@[card](https://github.com/i9wa4/databricks-goose-starter)

本記事では、このテンプレートの機能と使い方を紹介します。

本記事は下記イベントでの登壇内容を補完するものです。

@[card](https://jedai.connpass.com/event/379174/)

## 2. 解決したい課題

### 2.1. AI コーディングエージェントの普及の壁

AI コーディングエージェントを組織内に展開しようとすると、以下のような課題があると思います。

- 環境構築のハードルが高い
- 認証設定が複雑 (API キー管理、Service Principal 作成など)
- 技術部門以外のメンバーには敷居が高い

### 2.2. このテンプレートの解決策

databricks-goose-starter はこれらの課題を解決します。

- **Dev Container で環境構築を自動化**: 「Reopen in Container」をクリックするだけ
- **OAuth U2M 認証で複雑な認証設定不要**: ブラウザで認証するだけで完了
- **Goose 経由で対話的に操作**: 自然言語で Notebook 実行や SQL 実行を依頼
- **ローカルに Python や Spark をインストール不要**: すべて Databricks 上で実行

開発者でなくても AI コーディングエージェントが使える環境を目指しました。

## 3. 対象ユーザー

このテンプレートは以下のようなユーザーに適しています。

- データアナリスト、ビジネスユーザー
- インターン、外部協力者
- 今すぐ AI コーディング環境を使いたい人

逆に適していないのは以下のようなケースです。

- 大量にトークンを消費するヘビーユーザー
- リアルタイムでの利用制限が必要な場合

## 4. 作ったもの

Databricks Mosaic AI Gateway を LLM バックエンドとして使う Goose (AI コーディングエージェント) の Dev Container テンプレートです。

### 4.1. Goose + Mosaic AI Gateway

Goose は Block 社が開発した AI コーディングエージェントです。Databricks Mosaic AI Gateway 経由で Claude や GPT などの LLM を利用できます。

@[card](https://github.com/block/goose)

```console
goose
```

Goose は以下のことができます。

- コマンド実行 (`uv run jupyter execute` を含む)
- Notebook の読み書き
- コードベースとの対話

技術部門以外のメンバーでも、自然言語で「このテーブルの集計をして」「Notebook を実行して」と依頼するだけで操作できます。

### 4.2. MCP Server (対話的な SQL 実行)

mcp-databricks-server が事前設定されており、Goose から Databricks SQL Warehouse に対話的にアクセスできます。

- SQL クエリ実行 (Databricks SQL Warehouse 経由)
- カタログ、スキーマ、テーブル一覧 (Unity Catalog)
- テーブルスキーマの確認
- テーブルリネージ情報の取得

安全のため、DROP/DELETE/TRUNCATE などの破壊的な SQL はブロックされます。

@[card](https://github.com/i9wa4/mcp-databricks-server)

SQL を書けなくても「売上の月別推移を見たい」と伝えるだけで、Goose が適切なクエリを生成して実行します。認証さえ通れば Databricks 上のデータを対話的に探索できます。

### 4.3. jupyter-databricks-kernel (Notebook の完全リモート実行)

jupyter-databricks-kernel により、Notebook のコードを Databricks クラスタ上で完全リモート実行できます。

```bash
uv run jupyter execute notebooks/sample.ipynb --inplace --kernel_name=databricks
```

@[card](https://github.com/i9wa4/jupyter-databricks-kernel)

ローカル環境のリソースを考慮することなく Goose に「この Notebook を実行して」と依頼すれば、上記コマンドを実行して結果を取得してくれます。

## 5. セットアップ手順

### 5.1. 前提条件

- VS Code + [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Docker Desktop または Docker デーモン
- Databricks ワークスペース (Mosaic AI Gateway 有効)

### 5.2. 事前準備

`.env` ファイルは Dev Container 起動前に作成する必要があります。

1. リポジトリをクローン
1. `.env.example` を `.env` にコピーして編集

```bash
cp .env.example .env
```

環境変数の設定

| 変数                          | 説明                          |
| ---                           | ---                           |
| `DATABRICKS_HOST`             | Databricks ワークスペース URL |
| `DATABRICKS_CLUSTER_ID`       | Notebook 実行用クラスタ ID    |
| `DATABRICKS_SQL_WAREHOUSE_ID` | SQL 実行用 Warehouse ID       |
| `GOOSE_PROVIDER`              | LLM プロバイダ (databricks)   |
| `GOOSE_MODEL`                 | 使用するモデル                |

### 5.3. Dev Container 起動

1. VS Code でリポジトリを開く
1. 「Reopen in Container」をクリック
1. 自動セットアップを待つ
   - mise とツール (goose, databricks cli, uv) のインストール
   - Python 依存関係のインストール
   - Databricks OAuth 認証 (ブラウザが開きます)
   - Goose の MCP 設定

### 5.4. Goose 起動

```bash
goose
```

これだけで AI コーディング環境が使えます。

## 6. 使い方

Goose を起動すると、AI エージェントと対話できます。

例

- 「samples.nyctaxi.trips テーブルの構造を教えて」
- 「notebooks/sample.ipynb を実行して」
- 「pickup_zip ごとの平均運賃を SQL で集計して」

技術的な知識がなくても、やりたいことを自然言語で伝えるだけで操作できます。

## 7. OAuth U2M 認証のメリット

このテンプレートは OAuth U2M (User-to-Machine) 認証のみで動作します。

従来の方法との比較

| 認証方式              | 設定の複雑さ | トークン管理   | 権限管理     |
| --------------------- | ------------ | -------------- | ------------ |
| Personal Access Token | 中           | 手動更新が必要 | トークン単位 |
| Service Principal     | 高           | 自動           | SP 単位      |
| OAuth U2M             | 低           | 自動更新       | ユーザー単位 |

OAuth U2M のメリット

- Service Principal の作成が不要
- 個人の認証情報で即座に利用開始
- 開発者ごとの権限で動作 (最小権限の原則)
- トークン管理の手間が不要 (OAuth 自動更新)

Dev Container 起動時に `databricks auth login` が実行され、ブラウザで認証するだけで完了します。複雑な設定は一切不要です。

## 8. 予算管理 (Budget Monitoring)

ユーザー単位のトークン消費量を監視し、予算超過時に自動でアクセスを制限する仕組みを Databricks Job で実装しています。

### 8.1. 仕組み

- `system.serving.endpoint_usage` テーブルでトークン消費量を集計
- Mosaic AI Gateway の `rate_limits` API で `calls=0` を設定してユーザーをブロック
- 月初に `rate_limits` をリセットして全ユーザーを解除

### 8.2. budget-monitor Job

予算超過ユーザーを検出してブロックする Job です。

```python
"""
Budget Monitor Job - Detects budget overages and blocks users via rate limits.
"""

import os
import sys
from datetime import datetime

import requests

# Configuration
BUDGET_TOKENS = 10_000_000  # 10 million tokens
ENDPOINT_NAME = "databricks-claude-sonnet-4"
WAREHOUSE_ID = "warehouse-id"


def log(message: str):
    """Print timestamped log message."""
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")


def get_databricks_credentials():
    """Get Databricks host and token."""
    try:
        from pyspark.sql import SparkSession

        spark = SparkSession.builder.getOrCreate()
        host = "https://" + spark.conf.get("spark.databricks.workspaceUrl")
        from pyspark.dbutils import DBUtils

        dbutils = DBUtils(spark)
        token = (
            dbutils.notebook.entry_point.getDbutils()
            .notebook()
            .getContext()
            .apiToken()
            .get()
        )
        return host, token
    except Exception as e:
        log(f"Warning: Could not get credentials from Spark context: {e}")

    host = os.environ.get("DATABRICKS_HOST")
    token = os.environ.get("DATABRICKS_TOKEN")
    if not host or not token:
        raise ValueError("DATABRICKS_HOST and DATABRICKS_TOKEN must be set")
    return host.rstrip("/"), token


def execute_sql(host: str, token: str, statement: str) -> list:
    """Execute SQL via Statement Execution API."""
    url = f"{host}/api/2.0/sql/statements"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "warehouse_id": WAREHOUSE_ID,
        "statement": statement,
        "wait_timeout": "50s",
    }

    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()
    result = response.json()

    if result["status"]["state"] != "SUCCEEDED":
        raise RuntimeError(f"SQL execution failed: {result}")

    return result.get("result", {}).get("data_array", [])


def get_exceeded_users_with_usage(host: str, token: str) -> list:
    """Get users who exceeded budget with their token usage."""
    query = f"""
    SELECT
        requester,
        SUM(input_token_count) as input_tokens,
        SUM(output_token_count) as output_tokens,
        SUM(input_token_count + output_token_count) as total_tokens
    FROM system.serving.endpoint_usage
    WHERE request_time >= date_trunc('month', current_date())
    GROUP BY requester
    HAVING SUM(input_token_count + output_token_count) >= {BUDGET_TOKENS}
    ORDER BY total_tokens DESC
    """
    return execute_sql(host, token, query)


def block_users(host: str, token: str, users: list) -> bool:
    """Set rate_limits calls=0 for exceeded users. Returns success status."""
    if not users:
        log("No users to block")
        return True

    rate_limits = [
        {"calls": 0, "key": "user", "principal": user, "renewal_period": "minute"}
        for user in users
    ]
    config = {"rate_limits": rate_limits, "usage_tracking_config": {"enabled": True}}

    url = f"{host}/api/2.0/serving-endpoints/{ENDPOINT_NAME}/ai-gateway"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    try:
        response = requests.put(url, headers=headers, json=config)
        response.raise_for_status()
        return True
    except Exception as e:
        log(f"ERROR: Failed to block users: {e}")
        return False


def main():
    print("=" * 60)
    log("Budget Monitor Job started")
    print("=" * 60)

    # Configuration
    print("\n[Configuration]")
    print(f"  Budget threshold: {BUDGET_TOKENS:,} tokens")
    print(f"  Target endpoint:  {ENDPOINT_NAME}")
    print(f"  SQL Warehouse:    {WAREHOUSE_ID}")

    host, token = get_databricks_credentials()
    print(f"  Workspace:        {host}")

    # Query exceeded users
    print("\n[Query Results]")
    log("Querying system.serving.endpoint_usage...")

    exceeded_users = get_exceeded_users_with_usage(host, token)

    if not exceeded_users:
        log("No users exceeding budget found")
    else:
        log(f"Found {len(exceeded_users)} user(s) exceeding budget:")
        print()
        print(f"  {'User':<40} {'Input':<15} {'Output':<15} {'Total':<15}")
        print(f"  {'-' * 40} {'-' * 15} {'-' * 15} {'-' * 15}")
        for row in exceeded_users:
            user, input_t, output_t, total_t = (
                row[0],
                int(row[1]),
                int(row[2]),
                int(row[3]),
            )
            print(f"  {user:<40} {input_t:>14,} {output_t:>14,} {total_t:>14,}")

    # Block users
    print("\n[Block Processing]")
    users_to_block = [row[0] for row in exceeded_users]

    if users_to_block:
        log(f"Blocking {len(users_to_block)} user(s)...")
        success = block_users(host, token, users_to_block)
        if success:
            log("SUCCESS: All users blocked via rate_limits (calls=0)")
        else:
            log("FAILED: Could not block users")
            sys.exit(1)
    else:
        log("No blocking action required")

    # Completion
    print()
    print("=" * 60)
    log("Budget Monitor Job completed")
    print("=" * 60)


if __name__ == "__main__":
    main()
```

### 8.3. budget-monthly-reset Job

月初に rate_limits をリセットする Job です。

```python
"""
Budget Monthly Reset Job - Resets rate limits at the beginning of each month.
"""

import os
import sys
from datetime import datetime

import requests

# Configuration
ENDPOINT_NAME = "databricks-claude-sonnet-4"


def log(message: str):
    """Print timestamped log message."""
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")


def get_databricks_credentials():
    """Get Databricks host and token."""
    try:
        from pyspark.sql import SparkSession

        spark = SparkSession.builder.getOrCreate()
        host = "https://" + spark.conf.get("spark.databricks.workspaceUrl")
        from pyspark.dbutils import DBUtils

        dbutils = DBUtils(spark)
        token = (
            dbutils.notebook.entry_point.getDbutils()
            .notebook()
            .getContext()
            .apiToken()
            .get()
        )
        return host, token
    except Exception as e:
        log(f"Warning: Could not get credentials from Spark context: {e}")

    host = os.environ.get("DATABRICKS_HOST")
    token = os.environ.get("DATABRICKS_TOKEN")
    if not host or not token:
        raise ValueError("DATABRICKS_HOST and DATABRICKS_TOKEN must be set")
    return host.rstrip("/"), token


def get_current_rate_limits(host: str, token: str) -> dict:
    """Get current AI Gateway configuration."""
    url = f"{host}/api/2.0/serving-endpoints/{ENDPOINT_NAME}"
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    result = response.json()
    return result.get("ai_gateway", {})


def reset_rate_limits(host: str, token: str) -> bool:
    """Reset rate limits to unblock all users. Returns success status."""
    config = {"rate_limits": [], "usage_tracking_config": {"enabled": True}}

    url = f"{host}/api/2.0/serving-endpoints/{ENDPOINT_NAME}/ai-gateway"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    try:
        response = requests.put(url, headers=headers, json=config)
        response.raise_for_status()
        return True
    except Exception as e:
        log(f"ERROR: Failed to reset rate limits: {e}")
        return False


def main():
    print("=" * 60)
    log("Budget Monthly Reset Job started")
    print("=" * 60)

    # Configuration
    print("\n[Configuration]")
    print(f"  Target endpoint: {ENDPOINT_NAME}")

    host, token = get_databricks_credentials()
    print(f"  Workspace:       {host}")

    # Get current state
    print("\n[Current State]")
    log("Fetching current rate_limits...")

    current_config = get_current_rate_limits(host, token)
    current_limits = current_config.get("rate_limits", [])

    if not current_limits:
        log("No rate_limits currently set")
    else:
        log(f"Found {len(current_limits)} rate_limit(s):")
        for limit in current_limits:
            principal = limit.get("principal", "N/A")
            calls = limit.get("calls", "N/A")
            key = limit.get("key", "N/A")
            print(f"  - {principal} (key={key}, calls={calls})")

    # Reset rate limits
    print("\n[Reset Processing]")
    log("Resetting rate_limits to empty...")

    success = reset_rate_limits(host, token)

    if success:
        log("SUCCESS: Rate limits cleared")
        if current_limits:
            log(f"Unblocked {len(current_limits)} user(s)")
        else:
            log("No users were blocked")
    else:
        log("FAILED: Could not reset rate limits")
        sys.exit(1)

    # Completion
    print()
    print("=" * 60)
    log("Budget Monthly Reset Job completed")
    print("=" * 60)


if __name__ == "__main__":
    main()
```

## 9. おわりに

Issue でバグ報告や機能提案などお気軽にどうぞ。

@[card](https://github.com/i9wa4/databricks-goose-starter)

### 9.1. 関連記事

@[card](https://zenn.dev/genda_jp/articles/2025-12-13-jupyter-databricks-kernel-oss-dev)

@[card](https://zenn.dev/genda_jp/articles/2025-12-19-databricks-notebook-ai-ready)

@[card](https://zenn.dev/genda_jp/articles/2025-12-24-mcp-databricks-server-v2)

### 9.2. 関連プロジェクト

@[card](https://github.com/block/goose)

@[card](https://github.com/i9wa4/mcp-databricks-server)

@[card](https://github.com/i9wa4/jupyter-databricks-kernel)
