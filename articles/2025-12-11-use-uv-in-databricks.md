---
title: "Databricks で uv を活用して依存関係を管理する"
emoji: "🐴"
type: "tech"
topics:
  - "databricks"
  - "python"
  - "uv"
publication_name: "genda_jp"
published: true
published_at: 2025-12-11 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 11 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

本記事では、Databricks で uv を使って依存関係を管理する方法を紹介します。

## 2. uv とは

uv は Rust 製の高速な Python パッケージマネージャです。

@[card](https://docs.astral.sh/uv/)

主な特徴

- pip の10-100倍高速
- `uv.lock` による再現可能な依存関係管理
- Python バージョン管理も可能

## 3. uv を使った Databricks でのパッケージ管理

### 3.1. requirements.txt 事前生成

`uv.lock` から `requirements.txt` を生成し、リポジトリにコミットしておきます。

```bash
uv export --no-hashes --no-dev > requirements.txt
```

Databricks では事前生成した requirements.txt を使います。

```python
%pip install -r requirements.txt
```

pre-commit で自動化すると、生成忘れや手動編集による整合性エラーを防げます。

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: uv-export
        name: uv export
        entry: uv export --no-hashes --no-dev -o requirements.txt
        language: system
        files: ^(pyproject\.toml|uv\.lock)$
        pass_filenames: false
```

メリット

- PR で依存関係の変更が見やすい

### 3.2. requirements.txt 動的生成

uv をインストールしておき動的生成することも可能です。

```python
%pip install uv
```

```python
import subprocess
result = subprocess.run(
    ["uv", "export", "--no-hashes", "--no-dev"],
    cwd="/Workspace/Repos/<user>/<repo>",
    capture_output=True,
    text=True
)
print(result.stdout)
```

メリット

- requirements.txt の管理が不要
- 常に uv.lock から生成するため整合性が保証される

デメリット

- 毎回 uv のダウンロードが発生する

### 3.3. uv sync / uv run について（参考）

ローカル開発では `uv sync` で仮想環境を作成し、`uv run` でスクリプトを実行するのが一般的です。
Databricks でも同様のワークフローが使えるか検証しました。

```python
# uv sync は成功する
result = subprocess.run(
    ["uv", "sync"],
    cwd="/Workspace/Repos/<user>/<repo>",
    capture_output=True,
    text=True
)
# .venv が作成され、パッケージがインストールされる
```

```python
# uv run は失敗する
result = subprocess.run(
    ["uv", "run", "python", "-c", "import httpx; print(httpx.__version__)"],
    cwd="/Workspace/Repos/<user>/<repo>",
    capture_output=True,
    text=True
)
# error: Failed to spawn: `python`
# Caused by: Invalid cross-device link (os error 18)
```

`uv sync` は成功しますが、`uv run` は失敗します。
これは `/Workspace` がネットワークファイルシステムであり、
ハードリンクの作成に制限があるためです。

結論として、Databricks では `requirements.txt` 経由での `%pip install` が最も安定した方法です。

## 4. pyproject.toml の構成

```toml
[project]
name = "databricks-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    # Databricks にインストールするパッケージ
]

[dependency-groups]
dev = [
    "pytest",
    "ruff",
]
dbr = [
    # DBR 17.3 LTS プリインストール済み
    # https://docs.databricks.com/aws/en/release-notes/runtime/17.3lts
    "pandas==2.2.3",
    "numpy==2.1.3",
    "pyspark==4.0.0",
]
```

ポイント

- `dependencies`: Databricks にインストールするパッケージ
- `dev`: ローカル開発ツール
- `dbr`: DBR プリインストール済みパッケージ
    - ローカルと DBR のバージョン整合性を保つために記載
    - `uv export --no-dev` でも含まれない（デフォルトで除外）

## 5. まとめ

uv を使うことでパッケージ依存関係を効率的に管理できます。

まだ uv を使ったことがない場合はぜひ試してみてください。

## 6. 関連記事

@[card](https://zenn.dev/genda_jp/articles/2025-12-10-organize-databricks-notebook-management)

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

## 7. 参考

- <https://docs.astral.sh/uv/>
- <https://docs.astral.sh/uv/reference/cli/#uv-export>
