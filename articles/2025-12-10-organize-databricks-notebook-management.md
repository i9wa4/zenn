---
title: "Databricksのノートブック管理方法2選"
emoji: "📓"
type: "tech"
topics:
  - "databricks"
  - "jupyter"
  - "python"
  - "ruff"
publication_name: "genda_jp"
published: true
published_at: 2025-12-10 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 10 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

Databricks ノートブックで Git diff が読めない、テストが書けないのような課題感をもつ方がいらっしゃると思います。

本記事では、2つの解決策を紹介します。

1. **Source形式** - ノートブックを `.py` 形式で保存（Git diff 問題を解決）
2. **Skinny Notebook Wrapper** - ロジックを別ファイルに分離（テスト・再利用性を解決）

## 2. 従来のノートブック開発の課題

デフォルトの IPYNB形式（`.ipynb`）は JSON ベースのため、
通常の開発ツールが使いにくいです。

| 項目     | IPYNB形式         | 理想               |
| ------   | -----------       | ------             |
| Git diff | JSON で読みにくい | テキストで読みたい |
| pytest   | 実行困難          | 簡単にテストしたい |
| IDE 補完 | 効きにくい        | 完全に効かせたい   |

※ Ruff（Linter/Formatter）は `.ipynb` をネイティブサポートしています。

## 3. 解決策1: Source形式

### 3.1. Source形式とは

Databricks ノートブックは IPYNB形式以外に **Source形式** をサポートしています。
Source形式では、ノートブックが `.py`（または `.scala`, `.sql`, `.r`）ファイルとして保存されます。

```python
# Databricks notebook source
# MAGIC %md
# MAGIC # サンプルノートブック

# COMMAND ----------

print("Hello, Databricks!")

# COMMAND ----------

df = spark.table("samples.nyctaxi.trips")
df.show()
```

ファイル先頭の `# Databricks notebook source` コメントにより、
Databricks がこのファイルをノートブックとして認識します。

### 3.2. IPYNB形式 vs Source形式

| 項目         | IPYNB形式          | Source形式              |
| ------       | -----------        | ------------            |
| ファイル形式 | JSON（`.ipynb`）   | テキスト（`.py`等）     |
| Git diff     | 読みにくい         | 読みやすい              |
| 出力の保存   | 可能               | 不可                    |
| Ruff 対応    | ネイティブサポート | 通常の `.py` として対応 |

### 3.3. Source形式への変更方法

**個別のノートブック:**
File メニュー → Notebook format → Source を選択

**デフォルト設定:**
Settings → Developer → Editor settings で変更

### 3.4. Source形式の限界

Source形式で Git diff の問題は解決しますが、以下は残ります。

- ロジックがセルに散らばる問題
- `dbutils` / `spark` 依存によるテスト困難
- コードの再利用性

これらを解決するには、次の Skinny Notebook Wrapper パターンが有効です。

## 4. 解決策2: Skinny Notebook Wrapper パターン

### 4.1. 基本的な考え方

**Skinny Notebook Wrapper** とは、ノートブックを「薄いラッパー」として扱い、
実際のロジックは `.py` ファイルに書くパターンです。
Web 開発における「Skinny Controller, Fat Model」（コントローラーは処理を振り分けるだけで、
ビジネスロジックはモデル層に書く設計）と同じ考え方です。

```text
project/
├── launcher.py       # 薄いラッパー（Source形式ノートブック）
├── main.py           # メインロジック（通常の Python ファイル）
├── test_main.py      # テストコード
└── pyproject.toml    # Ruff 設定
```

※ launcher は IPYNB形式（`launcher.ipynb`）でも構いません。

### 4.2. なぜノートブックを残すのか

ロジックを `.py` に切り出しても、ノートブックは以下の理由で便利です。

| 役割                               | ノートブック  | .py ファイル   |
| ------                             | ------------- | -------------- |
| マジックコマンド (%pip install 等) | ○            | ×             |
| テストの書きやすさ                 | ×            | ○             |

つまり、ノートブックは「Job のエントリーポイント」として残しつつ、
ロジックは `.py` に書くのがベストです。

### 4.3. launcher の例

Databricks Repos / Git Folders を使う場合の例です。
（Workspace Files の場合は `sys.path` 設定が必要。詳細はセクション6参照）

<!-- rumdl-disable MD036 -->
**Cell 1: Widget 定義**
<!-- rumdl-enable MD036 -->

`dbutils.widgets.text()` でパラメータとデフォルト値を定義します。
Job 実行時はデフォルト値が使われます。

```python
dbutils.widgets.text("table_name", "samples.nyctaxi.trips", "Table Name")
dbutils.widgets.text("limit", "10", "Limit")
```

<!-- rumdl-disable MD036 -->
**Cell 2: main() 実行**
<!-- rumdl-enable MD036 -->

Widget で定義したパラメータを取得し、ロジック（`main.py`）に渡します。
Widget は常に文字列を返すため、数値が必要な場合は `int()` で変換します。

```python
from main import main

main(
    table_name=dbutils.widgets.get("table_name"),
    limit=int(dbutils.widgets.get("limit")),
)
```

ポイント:

- `dbutils` は Databricks が事前定義（再生成不要）
- Ruff の F821 エラーは `pyproject.toml` で抑制（セクション5参照）
- ノートブックは「起動装置」に徹する

Databricks Job の設定で `base_parameters` を指定すると、
Widget のデフォルト値を上書きできます。

```json
{
  "notebook_task": {
    "notebook_path": "/path/to/launcher",
    "base_parameters": {
      "table_name": "production.sales.orders",
      "limit": "1000"
    }
  }
}
```

### 4.4. main.py にロジックを集約

```python
"""メインロジックモジュール"""

from pyspark.sql import DataFrame, SparkSession


def load_table(spark: SparkSession, table_name: str, limit: int) -> DataFrame:
    """テーブルからデータを読み込む"""
    return spark.table(table_name).limit(limit)


def main(table_name: str, limit: int = 10) -> None:
    """メイン処理（ノートブックから呼ばれる）"""
    spark = SparkSession.builder.getOrCreate()
    df = load_table(spark, table_name, limit)
    df.show()
```

ポイント:

- `load_table()` は `spark` を引数で受け取るためモック可能
- `dbutils` に依存しない
- 型アノテーション付きで IDE 補完が効く

### 4.5. テストの例

`load_table()` は `spark` を引数で受け取るため、モックを使ってテストできます。

```python
# test_main.py
from unittest.mock import MagicMock

from main import load_table


def test_load_table():
    mock_spark = MagicMock()
    mock_df = MagicMock()
    mock_spark.table.return_value.limit.return_value = mock_df

    result = load_table(mock_spark, "test_table", 10)

    mock_spark.table.assert_called_once_with("test_table")
    mock_spark.table.return_value.limit.assert_called_once_with(10)
    assert result == mock_df
```

このテストは Databricks 環境がなくても実行できます。

```bash
# テスト実行
pytest test_main.py
```

## 5. Ruff（Linter/Formatter）の設定

Ruff は Rust 製の高速な Python Linter/Formatter です。

### 5.1. F821 エラーを pyproject.toml で抑制

ノートブック内で `dbutils` や `spark` を使うと
Ruff が F821 (Undefined name) エラーを出します。

```text
F821 Undefined name `dbutils`
F821 Undefined name `spark`
```

Databricks 環境では `spark` と `dbutils` が事前定義されていますが、
Ruff は静的解析ツールなのでこれを認識できません。
`per-file-ignores` でノートブックのみ F821 を無視します。

Skinny Notebook Wrapper パターンでは、`dbutils` はノートブック内でのみ使用し、
Widget の値を引数としてロジック側に渡します。
ロジック側の `.py` ファイルは `dbutils` に依存しないため、F821 抑制は不要です。
`spark` も `SparkSession.builder.getOrCreate()` で取得するため、
事前定義変数への依存がなくなります。

### 5.2. pyproject.toml の設定例

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # Pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "UP",  # pyupgrade
]

[tool.ruff.lint.per-file-ignores]
# IPYNB形式の場合（全ての .ipynb に適用）
"*.ipynb" = ["F821"]
# Source形式の場合（ノートブック用 .py のみ指定。通常の .py には適用しない）
# E402: セル区切りにより import が先頭に来ないため
"notebooks/*.py" = ["F821", "E402"]
```

Ruff は `.ipynb` ファイルをネイティブサポートしているため、
IPYNB形式でも Source形式でも同じルールでチェックできます。

```bash
# .py も .ipynb も両方チェック
ruff check .
```

## 6. .py ファイルのインポート

### 6.1. Databricks Repos / Git Folders を使う

Databricks Repos（現在は Git Folders と呼ばれています）を使うと、
ノートブックのディレクトリが自動的に `sys.path` に含まれます。

```text
/Repos/your-name/project/
├── launcher.py   # Source形式ノートブック
├── main.py
└── utils.py
```

この構成なら、ノートブックから `from main import main` が
追加設定なしで動作します。

※ ノートブックと `.py` ファイルが同じディレクトリにあるフラット構成を前提とします。

### 6.2. 階層構造のインポート（Git Folders）

プロジェクトが大きくなると、ディレクトリを分けたくなります。
Git Folders を使えば、階層構造でも問題なくインポートできます。

```text
project/
├── notebooks/
│   └── launcher.ipynb   # ノートブック
├── src/
│   └── main.py          # メインロジック
├── common/
│   └── utils.py         # 共通ユーティリティ
└── tests/
    └── test_main.py     # テストコード
```

```python
# notebooks/launcher.ipynb (Cell 2)
from src.main import main

main(
    table_name=dbutils.widgets.get("table_name"),
    limit=int(dbutils.widgets.get("limit")),
)
```

```python
# src/main.py
from common.utils import greet  # 別階層からインポート可能
```

この構成は Databricks Job（Git Folders 経由）でも動作確認済みです。
ローカルの pytest と Databricks Job の両方で同じコードが使えます。

## 7. まとめ

### 7.1. Source形式で解決できること

- Git diff が読みやすくなる
- Ruff で通常の `.py` としてチェック可能

### 7.2. Skinny Notebook Wrapper で解決できること

- ロジックの分離によるテスト可能性
- コードの再利用性向上

既存のノートブックがある場合は、まず Source形式への変換を試してみてください。
テストや再利用が必要になったら Skinny Notebook Wrapper パターンを導入しましょう。

## 8. 関連記事

@[card](https://zenn.dev/genda_jp/articles/2025-12-19-databricks-notebook-ai-ready)

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

## 9. 参考

- [Manage notebook format | Databricks Documentation](https://docs.databricks.com/aws/en/notebooks/notebook-format)
