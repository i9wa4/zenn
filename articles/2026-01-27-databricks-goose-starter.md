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

## 8. 今後の展望

- 追加の Agent Skills (dbt, Databricks Jobs など)
- ドキュメント拡充
- コミュニティからのフィードバック対応

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
