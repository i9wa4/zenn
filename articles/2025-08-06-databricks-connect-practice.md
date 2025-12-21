---
title: "Databricks Connect 実践編 ― ローカルから Databricks コンピュートを利用"
emoji: "🚀"
type: "tech"
topics:
  - "databricks"
  - "devcontainer"
  - "python"
  - "spark"
published: true
published_at: 2025-08-06 19:02
publication_name: "genda_jp"
---

本記事は3部構成の3本目です。

1. [Claude Code 対応 Dev Container 環境構築編 - VS Code でもそれ以外でも](2025-08-06-devcontainer-claude-code)
2. [Python 開発環境最適化編 - uv + pre-commit + GitHub Actions](2025-08-06-python-env-optimization)
3. Databricks Connect 実践編 - ローカルから Databricks コンピュートを利用

## 1. はじめに

前回までの環境に Databricks Connect を追加して、ローカル開発環境から Databricks の Spark セッションを利用できるようにします。

Databricks 上でもローカルでも同じコードが動作する汎用的なライブラリも紹介します。

## 2. 対象読者

- Databricks のコンピュートをローカルから利用したい方
- Databricks 上での開発に Claude Code を利用したい方
- Databricks 以外の DWH サービスを使っているが参考にしたい方

## 3. Databricks Connect とは

Databricks Connect は、ローカル開発環境から Databricks クラスタに接続できるライブラリです。

これにより以下のメリットが得られます。

- VS Code や Claude Code などのローカル開発環境が利用できる
- ローカルでの開発と Databricks 上での実行で同じコードが使える

## 4. 環境設定

### 4.1. pyproject.toml への追加

前回の pyproject.toml に以下の依存関係を追加します。

```toml:pyproject.toml
[project]
dependencies = [
    "databricks-connect~=16.4.0",
    "ipykernel",
    "jupyterlab",
    "matplotlib",
    "numpy",
    "pandas",
    "python-dotenv",
    "requests",
    "seaborn",
]

[tool.flake8]
extend-ignore = [
    "E203",  # Whitespace before ':'
    "E701",  # Multiple statements on one line (colon)
    "F821"   # undefined name (Databricks-specific module)
]
```

### 4.2. Dev Container設定の更新

devcontainer.json に以下の設定を追加します。

```json:.devcontainer/devcontainer.json
{
    "runArgs": [
        "--cap-add=NET_ADMIN",
        "--cap-add=NET_RAW",
        "--network=host"
    ],
    "mounts": [
        "source=${localEnv:HOME}/.databrickscfg,target=/home/node/.databrickscfg,type=bind,consistency=cached",
    ]
}
```

### 4.3. 環境変数設定

`.env.example` ファイルを作成します。

```sh:.env.example
# Databricks設定

# .databrickscfgのプロファイル名（推奨）
DATABRICKS_CONFIG_PROFILE=DEFAULT

# クラスター使用の場合（どちらか一方を設定）
# DATABRICKS_CLUSTER_ID=

# Serverless Compute使用の場合
DATABRICKS_SERVERLESS_COMPUTE_ID=auto

# バージョンチェック無効化
DATABRICKS_CONNECT_DISABLE_VERSION_CHECK=true
```

## 5. Spark セッション管理ライブラリ

Dev Container (ローカル) と Databricks の両方で同じように Spark セッションを作成するためのライブラリを用意しました。

### 5.1. 使用方法

```python
from databricks_spark import create_spark_session

# 新しいSparkセッションを作成
spark = create_spark_session()
df = spark.sql("SHOW CATALOGS")
df.show()
```

### 5.2. ライブラリ実装

:::details databricks_setup.py

```python:databricks_setup.py
"""
Databricks統一セットアップユーティリティ

ノートブックとジョブで同じコードでDatabricks環境をセットアップ
Spark、dbutils、display関数を環境に応じて自動初期化

使用方法:
    from databricks_setup import setup_spark, setup_dbutils_mock, setup_display_function

    spark = setup_spark()
    dbutils = setup_dbutils_mock()
    display = setup_display_function()

機能:
- 環境自動判定（Databricks vs ローカル）
- Sparkセッション作成
- dbutilsモック（ローカル環境用）
- display関数代替（ローカル環境用）
"""

import logging
import os
import sys
from pathlib import Path

# ロギング設定
logger = logging.getLogger(__name__)
logger.handlers.clear()
logger.propagate = False
logger.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s %(name)s [%(levelname)s] %(message)s")

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)
logger.addHandler(handler)


def setup_spark():
    """環境に応じてSparkセッションを作成・取得

    Databricks環境では既存のsparkを使用し、
    ローカル環境ではDatabricks Connectでセッションを新規作成

    Returns:
        SparkSession: 使用可能なSparkセッション
    """
    # 実行環境の検出
    if os.environ.get("DATABRICKS_RUNTIME_VERSION"):
        logger.info("🔍 実行環境検出: Databricks Runtime")
        logger.info(
            f"Databricks環境を検出 (Runtime: {os.environ.get('DATABRICKS_RUNTIME_VERSION')})"
        )
    else:
        logger.info("🔍 実行環境検出: local")

    logger.info("Sparkセッションのセットアップを開始")

    # Databricks環境の場合は何もしない（既存のsparkを使用）
    if os.environ.get("DATABRICKS_RUNTIME_VERSION"):
        spark = globals().get("spark")
        logger.info("✅ 既存のSparkセッションを使用")
        return spark

    # ローカル環境の場合はdatabricks_sessionをインポート
    logger.info("ローカル環境を検出、Databricks Connectをセットアップ")
    if "__file__" in globals():
        current_dir = Path(__file__).parent
    else:
        current_dir = Path.cwd()

    project_root = current_dir
    while project_root.parent != project_root:
        if (project_root / ".devcontainer").exists():
            break
        project_root = project_root.parent

    devcontainer_path = project_root / ".devcontainer"
    if str(devcontainer_path) not in sys.path:
        sys.path.insert(0, str(devcontainer_path))

    from databricks_session import create_spark_session

    logger.info("Databricks Connectセッションを作成中...")
    spark = create_spark_session()
    logger.info("Sparkセッションの作成完了")
    return spark


def setup_dbutils_mock():
    """ローカル環境用のdbutilsモックオブジェクトを作成

    Databricks環境のdbutilsと同じインターフェースを提供
    - widgets.getAll(): 空の辞書を返す
    - secrets.get(): 環境変数から値を取得

    Returns:
        MockDbutils: dbutilsのモックオブジェクト
    """

    class MockDbutils:
        class Widgets:
            def getAll(self):
                return {}

        class Secrets:
            def get(self, scope, key):
                env_var = f"DATABRICKS_SECRET_{scope.upper()}_{key.upper()}".replace(
                    "-", "_"
                )
                return os.environ.get(env_var, "")

        def __init__(self):
            self.widgets = self.Widgets()
            self.secrets = self.Secrets()

    return MockDbutils()


def setup_display_function():
    """ローカル環境用のdisplay関数代替を作成

    DataFrameを整形して標準出力に表示
    Databricks環境のdisplay()と同様の機能を提供

    Returns:
        function: display関数の代替
    """

    def display(df):
        print("\n=== DataFrame ===")
        if df.empty:
            print("データがありません")
        else:
            print(df.to_string())
        print()

    return display
```

:::

:::details databricks_session.py

```python:databricks_session.py
"""
Databricks Sparkセッション管理

ローカル環境でのDatabricks Connectセッション作成機能

使用方法:
    from databricks_session import create_spark_session
    spark = create_spark_session()
    df = spark.sql("SHOW CATALOGS")
    df.show()
"""

import logging
import os
import sys

# ロギング設定
logger = logging.getLogger(__name__)
logger.handlers.clear()
logger.propagate = False
logger.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s %(name)s [%(levelname)s] %(message)s")

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)
logger.addHandler(handler)


def create_spark_session():
    """Databricks Connectセッション作成

    .databrickscfgまたは環境変数から認証情報を取得し、
    DatabricksクラスターまたはServerless Computeに接続

    Returns:
        SparkSession: Databricks Connectセッション

    Raises:
        ImportError: databricks-connectが利用できない場合
        ValueError: 必要な環境変数が未設定の場合
    """
    logger.info("Databricks Connectセッションの作成を開始")
    try:
        from databricks.connect import DatabricksSession

        # 環境変数のデフォルト値を設定
        os.environ.setdefault("DATABRICKS_CONFIG_PROFILE", "DEFAULT")
        os.environ.setdefault("DATABRICKS_SERVERLESS_COMPUTE_ID", "auto")
        os.environ.setdefault("DATABRICKS_CONNECT_DISABLE_VERSION_CHECK", "true")

        profile = os.environ.get("DATABRICKS_CONFIG_PROFILE")
        logger.info(f"環境変数: DATABRICKS_CONFIG_PROFILE={profile}")
        serverless_id = os.environ.get("DATABRICKS_SERVERLESS_COMPUTE_ID")
        logger.info(f"環境変数: DATABRICKS_SERVERLESS_COMPUTE_ID={serverless_id}")

        # .env読み込み（オプション）
        try:
            from dotenv import find_dotenv, load_dotenv

            env_file = find_dotenv()
            if env_file:
                logger.info(f"📁 .env読み込み: {env_file}")
                load_dotenv(env_file)
        except ImportError:
            pass

        # プロファイル指定チェック
        profile_name = os.environ.get("DATABRICKS_CONFIG_PROFILE")
        logger.info(f"🔧 .databrickscfgプロファイル使用: {profile_name}")

        if profile_name:
            if os.environ.get("DATABRICKS_CLUSTER_ID"):
                cluster_id = os.environ.get("DATABRICKS_CLUSTER_ID")
                logger.info(f"🔗 クラスターID {cluster_id} に接続")
                spark = (
                    DatabricksSession.builder.profile(profile_name)
                    .clusterId(cluster_id)
                    .getOrCreate()
                )
            else:
                logger.info("🚀 Serverless Compute使用")
                spark = (
                    DatabricksSession.builder.profile(profile_name)
                    .serverless(True)
                    .getOrCreate()
                )
        else:
            required_vars = ["DATABRICKS_HOST", "DATABRICKS_TOKEN"]
            missing_vars = [var for var in required_vars if not os.environ.get(var)]

            if missing_vars:
                raise ValueError(f"環境変数が未設定: {missing_vars}")

            if os.environ.get("DATABRICKS_CLUSTER_ID"):
                cluster_id = os.environ.get("DATABRICKS_CLUSTER_ID")
                spark = DatabricksSession.builder.clusterId(cluster_id).getOrCreate()
            else:
                spark = DatabricksSession.builder.serverless(True).getOrCreate()

        # DataFrame表示最適化（Serverless環境では一部設定が制限される）
        try:
            spark.conf.set("spark.sql.repl.eagerEval.enabled", True)
        except Exception:
            pass

        logger.info("✅ Databricks Connect Sparkセッション作成完了")

        # Spark情報の表示
        try:
            spark_version = spark.version
            logger.info(f"📊 Spark version: {spark_version}")

            # 接続先情報
            host = os.environ.get("DATABRICKS_HOST", "")
            if host:
                logger.info(f"🌐 接続先: {host}")
        except Exception:
            pass

        return spark

    except ImportError as e:
        raise ImportError(f"databricks-connectが利用できません: {e}")
```

:::

## 6. Databricks側の設定

### 6.1. 接続先クラスタ設定

Spark config で以下を設定します。

```properties:Spark config
spark.databricks.service.server.enabled true
```

### 6.2. Databricks 接続設定

Databricks へ接続する場合は `~/.databrickscfg` に以下の内容を記述します。

```ini:~/.databrickscfg
[DEFAULT]
host = https://your-databricks-workspace.cloud.databricks.com
token = your-access-token
```

- `host`: Databricks ワークスペースの URL
- `token`: Databricks アクセストークン

## 7. 利用手順

### 7.1. `.env` 作成

1. `.env` ファイルを作成します

    ```sh
    cp .env.example .env
    ```

2. 必要であれば `.env` ファイルの内容を変更してください

### 7.2. 開発ワークフロー

1. Dev Container を起動
2. Python カーネルを選択
3. Spark セッションを作成して開発開始

```python
# .ipynb & .py (Databricks Notebook) 共通セットアップ
import os
import sys
from pathlib import Path

# プロジェクトルートを探す (.devcontainer または .git を基準に)
project_root = None
for parent in [Path.cwd()] + list(Path.cwd().parents):
    # .devcontainer または .git が存在する場所をプロジェクトルートとする
    if (parent / '.devcontainer').exists() or (parent / '.git').exists():
        project_root = parent
        break

# Databricks環境の判定
if not os.environ.get("DATABRICKS_RUNTIME_VERSION"):
    # === ローカル環境の場合 ===
    # Databricks Connect を使用してリモートクラスターに接続する
    if project_root and (project_root / '.devcontainer').exists():
        # NOTE: databricks_setup.py のパスを追加
        sys.path.insert(0, str(project_root / '.devcontainer'))
        from databricks_setup import setup_spark, setup_dbutils_mock, setup_display_function

        spark = setup_spark()
        dbutils = setup_dbutils_mock()
        display = setup_display_function()
    else:
        raise FileNotFoundError("プロジェクトルートまたは .devcontainer ディレクトリが見つかりません")
else:
    # === Databricks 環境の場合 ===
    # spark, dbutils は既に定義済みなので依存関係のインストールのみ
    if project_root and (project_root / 'pyproject.toml').exists():
        # NOTE: uv は DBR にインストールされている
        %pip install -r <(uv pip compile {project_root}/pyproject.toml --color never)
        %restart_python
    else:
        print("⚠️ プロジェクトルートまたはpyproject.tomlが見つかりません。依存関係のインストールをスキップします。")
```

書き味があまり良くないので改善ポイントです。。

## 8. ノートブックでの Python モジュールインストール方法

上の参考コードにも記載ありますが Databricks での実行時のみ Python パッケージをインストールする HACK な方法です。

uv を使っていない場合は `%pip install <package>` 等で大丈夫です。

```python
import os

if os.environ.get("DATABRICKS_RUNTIME_VERSION"):
    # NOTE: uv は DBR にインストールされている
    %pip install -r <(uv pip compile pyproject.toml --color never)
```

## 9. トラブルシューティング

### 9.1. バージョン不整合エラー

Databricks Connect のバージョンとクラスタのランタイムバージョンが合わない場合があります

```sh
# クラスタのランタイムに合わせてダウングレード
uv add 'databricks-connect~=14.3.0'  # この場合は DBR 14.3 に対応
```

### 9.2. 接続エラー

設定ファイルが存在せずマウントされていない場合が考えられるので、devcontainer.json の `mounts` 設定を確認してください。

## 10. おわりに

これでローカル開発環境から Databricks の Spark クラスタを利用できるようになりました。

Claude Code にノートブック実行とデバッグを任せることでデータサイエンスや機械学習の作業効率が爆上がりですね！

Claude Code にこの手の作業を任せるときは時間がかかるので並行して他の作業に取り組むのがオススメです。

## 11. (おまけ) Claude Code に読ませると便利なルール

```md:CONTRIBUTING.md
# CONTRIBUTING

## 重要なルール

### pre-commit 設定について

- **NEVER**: pre-commit を無効化してはならない
- **NEVER**: `pre-commit skip` や `git commit --no-verify` を使用してはならない
- **IMPORTANT**: pre-commit のチェックに失敗した場合は、必ずコードを修正してからコミットする

## Jupyter Notebook 実行方法

### デフォルトの実行方法

Notebook全体を実行する指示を受けた際は、以下のコマンドを使用する

`uv run jupyter nbconvert --to notebook --execute <notebook_path> --inplace --ExecutePreprocessor.timeout=300`

#### 使用例

`uv run jupyter nbconvert --to notebook --execute /workspace/notebooks/databricks-connect-sample.ipynb --inplace --ExecutePreprocessor.timeout=300`

#### オプション説明

- `--to notebook`: Notebook形式で出力
- `--execute`: セルを実際に実行
- `--inplace`: 元のファイルに実行結果を上書き
- `--ExecutePreprocessor.timeout=300`: タイムアウトを300秒に設定

### 実行ログの確認

実行時のログを確認したい場合は以下のように実行する

`uv run jupyter nbconvert --to notebook --execute <notebook_path> --inplace --ExecutePreprocessor.timeout=300 2>&1 | tee /tmp/notebook_execution.log`

### 注意事項

- 実行前に必要な環境変数（`.env`ファイル等）が適切に設定されていることを確認する
- 長時間実行されるセルがある場合は`--ExecutePreprocessor.timeout`の値を調整する
- VS Codeで開いている場合は実行後にファイルの更新を確認する
```
