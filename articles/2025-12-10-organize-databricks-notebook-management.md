---
title: "カオス化を防ぐDatabricksのノートブック管理方法"
emoji: "📓"
type: "tech"
topics:
  - "databricks"
  - "jupyter"
  - "python"
  - "ruff"
publication_name: "genda_jp"
published: false
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 10 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

Databricks ノートブックの Git diff が読めない、テストが書けない、
そんな悩みを抱えていませんか？

本記事では、2つの解決策を段階的に紹介します。

1. **Source形式** - ノートブックを `.py` 形式で保存
2. **Thin Notebook Wrapper** - ロジックを別ファイルに分離

まずは Source形式を試し、それでも足りない場合に
Thin Notebook Wrapper パターンを検討してください。

## 2. 従来のノートブック開発の課題

デフォルトの IPYNB形式（`.ipynb`）は JSON ベースのため、
通常の開発ツールが使いにくいです。

| 項目 | IPYNB形式 | 理想 |
|------|-----------|------|
| Git diff | JSON で読みにくい | テキストで読みたい |
| pytest | 実行困難 | 簡単にテストしたい |
| IDE 補完 | 効きにくい | 完全に効かせたい |

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

| 項目 | IPYNB形式 | Source形式 |
|------|-----------|------------|
| ファイル形式 | JSON（`.ipynb`） | テキスト（`.py`等） |
| Git diff | 読みにくい | 読みやすい |
| 出力の保存 | 可能 | 不可 |
| Ruff 対応 | ネイティブサポート | 通常の `.py` として対応 |

### 3.3. Source形式への変更方法

**個別のノートブック:**
File メニュー → Notebook format → Source を選択

**デフォルト設定:**
Settings → Developer → Editor settings で変更

注意: IPYNB形式から Source形式に変換すると、セルの出力（実行結果）は失われます。

### 3.4. Source形式の限界

Source形式で Git diff の問題は解決しますが、以下は残ります。

- ロジックがセルに散らばる問題
- `dbutils` / `spark` 依存によるテスト困難
- コードの再利用性

これらを解決するには、次の Thin Notebook Wrapper パターンが有効です。

## 4. 解決策2: Thin Notebook Wrapper パターン

### 4.1. 基本的な考え方

**Thin Notebook Wrapper** とは、ノートブックを「薄いラッパー」として扱い、
実際のロジックは `.py` ファイルに書くパターンです。
Web 開発における「Thin Controller」（コントローラーは処理を振り分けるだけで、
ビジネスロジックは別のレイヤーに書く設計）と同じ考え方です。

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

| 役割 | ノートブック | .py ファイル |
|------|-------------|--------------|
| Widget パラメータ | ○ | × |
| Databricks UI でのデバッグ | ○ | × |
| テスト | × | ○ |

Databricks Job では、ノートブックは Notebook Task、`.py` ファイルは `spark_python_task` で実行できます。
ただし Widget パラメータはノートブックでのみ使えます。

つまり、ノートブックは「Job のエントリーポイント」として残しつつ、
ロジックは `.py` に書くのがベストです。

### 4.3. launcher はたった2セル

Databricks Repos / Git Folders を使う場合の例です。
（Workspace Files の場合は `sys.path` 設定が必要。詳細はセクション6参照）

```python
# Cell 1: Widget定義
dbutils.widgets.text("table_name", "samples.nyctaxi.trips", "Table Name")
dbutils.widgets.text("limit", "10", "Limit")
```

```python
# Cell 2: main() 実行
from main import main

# Widget は文字列を返すため、必要に応じて型変換
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
"launcher.py" = ["F821"]
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

### 6.2. Workspace Files を使う場合

Workspace Files（`/Workspace/Users/...`）を使う場合は、
ノートブックのパスから相対的にプロジェクトルートを計算します。

```python
import os
import sys

# ノートブックのパスを取得（/Workspace プレフィックスなし）
# 例: /Users/your-name/project/launcher
notebook_context = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
notebook_path = notebook_context.notebookPath().get()

# /Workspace プレフィックスを付けてフルパスに変換
# 例: /Workspace/Users/your-name/project
PROJECT_ROOT = f"/Workspace{os.path.dirname(notebook_path)}"

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)
```

注意: 上記はノートブックと `.py` ファイルが同じディレクトリにある
フラット構成を前提としています。

## 7. まとめ

### Source形式で解決できること

- Git diff が読みやすくなる
- Ruff で通常の `.py` としてチェック可能

### Thin Notebook Wrapper で解決できること

- ロジックの分離によるテスト可能性
- コードの再利用性向上
- IDE 補完の完全動作

既存のノートブックがある場合は、まず Source形式への変換を試してみてください。
テストや再利用が必要になったら Thin Notebook Wrapper パターンを導入しましょう。

## 8. 関連記事

ガードレール構成（mise + pre-commit + Renovate）については
以下の記事で紹介しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

## 参考

- [Manage notebook format | Databricks Documentation](https://docs.databricks.com/aws/en/notebooks/notebook-format)
