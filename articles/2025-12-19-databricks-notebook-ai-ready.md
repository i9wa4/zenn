---
title: "Databricks Notebook 開発環境を AI-Ready にする"
emoji: "🧱"
type: "tech"
topics: ["databricks", "jupyter", "uv", "renovate", "mise", "pre-commit"]
published: false
publication_name: "genda_jp"
---

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 19 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

ならびに Databricks Advent Calendar 2025 シリーズ1 Day 19 の記事です。

@[card](https://qiita.com/advent-calendar/2025/databricks)

本記事は 2025-12-12 に開催された Databricks 招待イベント Data+AI World Tour Tokyo After Party での登壇内容を再構成したものです。

@[speakerdeck](58be33da57d84a5eb9914aa8a8c903ec)

## 1. はじめに

Databricks Notebook は手軽にデータ分析や機械学習のプロトタイピングができる便利なツールですが、開発体験にはいくつかの課題があります。

さらに、GitHub Copilot や Claude Code などの AI コーディングアシスタントが普及した現在、これらのツールを活用しやすい状態を目指すことが重要となっています。

以下で Databricks Notebook 開発を AI-Ready にするための 4 つの改善策を紹介します。

### 1.1. 本記事の新しい観点

従来の Databricks 開発環境整備は「人間の開発者」の生産性向上が主目的でした。本記事では、AI コーディングアシスタントとの統合という新しい視点から開発環境を見直します。

具体的には以下のようなアプローチを紹介します。

- 既存の Databricks 公式の VS Code 拡張や Databricks Connect ではなく新たに Jupyter Kernel を開発し完全ローカル開発環境を実現
- パッケージマネージャー uv の Databricks 環境での活用
- AI が生成したコードの品質を担保するガードレールの構築

## 2. 課題提起

### 2.1. 従来の Databricks Notebook 開発の課題

Databricks Notebook をそのまま使った開発には、以下のような課題があります。

1. ローカル開発環境との乖離
    - Databricks 上でしかコードを実行できない
    - 使い慣れた VS Code などのエディタが使えない
    - Git との連携が煩雑

2. コード品質管理の難しさ
    - Linter / Formatter の適用が難しい
    - テストコードの管理が複雑
    - コードレビューがしづらい

3. 依存関係管理の複雑さ
    - ノートブックごとに pip install が散らばる
    - バージョン固定が不完全
    - 再現性の確保が困難

### 2.2. AI 時代の新たな課題

GitHub Copilot や Claude Code などの AI コーディングアシスタントが登場し、開発生産性が大きく向上しました。しかし、Databricks Notebook 環境では以下の理由から AI ツールの恩恵を受けにくい状況があります。

1. AI ツールとの連携が困難
    - Databricks 上のノートブックでは AI アシスタントが動作しない、または制限がある
    - ローカルの AI ツールから Databricks Compute に接続できない

2. コンテキストの断絶
    - ノートブック内にロジックが散在していると AI がコード全体を理解しにくい
    - Pure Python ファイルに比べてコード補完の精度が落ちる

3. ガードレールの欠如
    - AI が生成したコードの品質チェックが手動になりがち
    - セキュリティリスクのあるコードが混入する可能性

これらの課題を解決し、AI ツールを最大限活用できる「AI-Ready」な開発環境を構築していきましょう。

## 3. Databricks Notebook 開発体験改善策

### 3.1. jupyter-databricks-kernel

#### 3.1.1. 概要

まず紹介するのは、私が開発した `jupyter-databricks-kernel` です。

@[card](https://github.com/i9wa4/jupyter-databricks-kernel)

Jupyter における「カーネル」とは、ノートブックのセルを処理し、結果をフロントエンド（VS Code など）に送信するコンポーネントです。

`jupyter-databricks-kernel` は、ローカルの Jupyter 環境から Databricks Compute に接続できるカーネルを提供します。これにより、以下のようなコマンドでノートブックを実行できます。

```sh
jupyter execute notebook.ipynb
```

#### 3.1.2. 既存アプローチとの違い

Databricks でのローカル開発には、公式の VS Code 拡張や Databricks Connect といったアプローチがあります。`jupyter-databricks-kernel` はこれらとは異なる特徴を持っています。

| アプローチ | 特徴 |
|-----------|------|
| Databricks VS Code 拡張 | Databricks 専用、VS Code 限定 |
| Databricks Connect | Spark セッションをローカルから接続、PySpark コード向け |
| jupyter-databricks-kernel | Jupyter 標準プロトコル、あらゆる Jupyter 対応ツールで動作 |

Jupyter 標準のカーネルプロトコルを採用しているため、VS Code だけでなく JupyterLab、Claude Code など Jupyter に対応したあらゆるツールから利用できます。

#### 3.1.3. メリット

1. ローカル開発環境の統一
    - VS Code + Jupyter 拡張で快適な開発体験
    - 使い慣れたエディタの機能をフル活用

2. AI ツールとの連携
    - GitHub Copilot がノートブックセル内でも動作
    - Claude Code からノートブックを直接実行可能

3. CI/CD との統合
    - `jupyter execute` コマンドでノートブックをヘッドレス実行
    - GitHub Actions などでの自動テストが容易に

#### 3.1.4. アーキテクチャ

```text
┌─────────────────────────────────────┐
│         ローカル開発環境              │
│  ┌─────────────┐  ┌──────────────┐  │
│  │   VS Code   │  │ Claude Code  │  │
│  │  + Jupyter  │  │              │  │
│  └──────┬──────┘  └──────┬───────┘  │
│         │                │          │
│         ▼                ▼          │
│  ┌──────────────────────────────┐   │
│  │  jupyter-databricks-kernel  │   │
│  └──────────────┬───────────────┘   │
└─────────────────┼───────────────────┘
                  │ Databricks SDK
                  ▼
┌─────────────────────────────────────┐
│        Databricks Workspace         │
│  ┌──────────────────────────────┐   │
│  │     Databricks Compute       │   │
│  │   (Cluster / SQL Warehouse)  │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 3.2. Skinny Notebook Wrapper + Pure Python

#### 3.2.1. 概要

ノートブックは便利ですが、ロジックをすべてノートブックに書くと管理が難しくなります。そこで推奨するのが「Skinny Notebook Wrapper + Pure Python」パターンです。

- ノートブックは「薄いラッパー」として使い続ける
- メインロジックは `.py` ファイルに切り出す
- ノートブックからは `.py` ファイルを呼び出すだけ

詳細は以下の記事で解説しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-10-organize-databricks-notebook-management)

#### 3.2.2. 構成例

```text
project/
├── notebooks/
│   └── main.ipynb          # 薄いラッパー（数セルのみ）
├── src/
│   └── main_logic.py       # メインロジック
├── tests/
│   └── test_main_logic.py  # テストコード
└── pyproject.toml
```

#### 3.2.3. ノートブックの中身

```python
# Cell 1: セットアップ
%pip install -e /Workspace/path/to/project

# Cell 2: 実行
from src.main_logic import run_pipeline
run_pipeline()
```

#### 3.2.4. メリット

1. コード品質の向上
    - Pure Python ファイルには Linter / Formatter が適用しやすい
    - 静的解析ツール（mypy など）も活用可能

2. テスタビリティの向上
    - pytest などの標準的なテストフレームワークが使える
    - ユニットテストが書きやすい

3. AI ツールとの親和性
    - Pure Python ファイルは AI アシスタントが理解しやすい
    - コード補完の精度が向上
    - リファクタリング提案も受けやすい

4. コードレビューの効率化
    - `.py` ファイルは差分が見やすい
    - PR でのレビューが容易

### 3.3. uv による依存関係管理

#### 3.3.1. 概要

Databricks 環境での依存関係管理には `uv` が非常に便利です。`uv` は Rust で書かれた高速な Python パッケージマネージャーで、`pip` や `poetry` の代替として使えます。

`uv` は 2024 年に登場した比較的新しいツールで、Databricks 環境での活用事例はまだ多くありません。しかし、その高速性と厳密なバージョン管理機能は、Databricks 開発においても大きなメリットをもたらします。

詳細は以下の記事で解説しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-11-use-uv-in-databricks)

#### 3.3.2. メリット

1. 高速なパッケージインストール
    - `pip` の 10〜100 倍高速
    - CI/CD の実行時間短縮

2. 厳密なバージョン管理
    - `uv.lock` による完全なバージョン固定
    - 再現性の確保

3. ローカルと Databricks での統一
    - 同じ `pyproject.toml` / `uv.lock` をローカルと Databricks で使用
    - 環境差異によるバグを防止

#### 3.3.3. 使い方

ローカルでの実行

```sh
uv run python src/main_logic.py
```

Databricks ノートブックでの実行

```python
# Cell 1: uv のインストールと依存関係のセットアップ
%pip install uv
!uv sync --frozen

# Cell 2: メインロジックの実行
!uv run python src/main_logic.py
```

### 3.4. ガードレール

#### 3.4.1. 概要

AI ツールを活用する上で重要なのが「ガードレール」です。AI が生成したコードにも、人間が書いたコードと同じ品質チェックを適用することで、コード品質とセキュリティを担保します。

詳細は以下の記事で解説しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

#### 3.4.2. 推奨ツールスタック

1. mise（ランタイム管理）
    - Python / Node.js などのバージョン管理
    - チーム全体で統一されたツールバージョン

2. pre-commit（コミット時チェック）
    - Linter / Formatter の自動実行
    - セキュリティスキャン
    - 型チェック

3. Renovate（依存関係の自動更新）
    - セキュリティパッチの自動適用
    - 依存関係の最新化

#### 3.4.3. pre-commit 設定例

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
```

#### 3.4.4. メリット

1. AI 生成コードの品質担保
    - コミット前に自動チェック
    - 問題のあるコードがリポジトリに入らない

2. セキュリティリスクの軽減
    - シークレットの検出
    - 既知の脆弱性チェック

3. チーム全体での品質統一
    - 誰が書いたコードでも同じルールを適用
    - AI ツールが生成したコードも例外なし

## 4. まとめ

本記事では、Databricks Notebook 開発環境を「AI-Ready」にするための 4 つの改善策を紹介しました。

| 改善策 | 解決する課題 |
|--------|------------|
| jupyter-databricks-kernel | ローカル開発環境との乖離、AI ツールとの連携 |
| Skinny Notebook Wrapper + Pure Python | コード品質管理、テスタビリティ |
| uv による依存関係管理 | 依存関係の複雑さ、再現性 |
| ガードレール | AI 生成コードの品質・セキュリティ |

これらを組み合わせることで、以下のような開発フローが実現できます。

```text
┌─────────────────────────────────────────────────────────────┐
│                    開発者のローカル環境                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  VS Code + Jupyter + GitHub Copilot / Claude Code   │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          jupyter-databricks-kernel                   │  │
│  │     （Databricks Compute でセル実行）                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │   Skinny Notebook + Pure Python + uv 依存関係管理     │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │     pre-commit（Linter / Formatter / Security）      │  │
│  └──────────────────────────────────────────────────────┘  │
│                         │                                   │
│                         ▼                                   │
│                    git commit                               │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          ▼
               ┌──────────────────┐
               │  GitHub Actions  │
               │  + Renovate      │
               └──────────────────┘
```

AI ツールは強力ですが、それを最大限活用するためには開発環境の整備が欠かせません。本記事で紹介した改善策を参考に、皆さんの Databricks 開発環境も「AI-Ready」にしていただければ幸いです。

## 5. 参考リンク

- [jupyter-databricks-kernel (GitHub)](https://github.com/i9wa4/jupyter-databricks-kernel)
- [Databricksのノートブック管理方法2選](https://zenn.dev/genda_jp/articles/2025-12-10-organize-databricks-notebook-management)
- [Databricks で uv を活用して依存関係を管理する](https://zenn.dev/genda_jp/articles/2025-12-11-use-uv-in-databricks)
- [mise + pre-commit + Renovate で作るメンテしやすいガードレール](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)
