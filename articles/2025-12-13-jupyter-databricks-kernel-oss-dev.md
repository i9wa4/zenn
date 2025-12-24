---
title: "jupyter-databricks-kernel を作りました ― OSS 開発の振り返り"
emoji: "🐴"
type: "idea"
topics:
  - "databricks"
  - "jupyter"
  - "oss"
  - "python"
publication_name: "genda_jp"
published: true
published_at: 2025-12-13 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 13 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

ローカルの Jupyter 環境から Databricks クラスタでコードを実行できる Jupyter カーネルを OSS として公開しました。

@[card](https://github.com/i9wa4/jupyter-databricks-kernel)

本記事では、約7週間の OSS 開発を振り返ります。

近日中に包括的な利用方法を解説する記事も公開予定です。

## 2. 作ったもの

Databricks クラスタ上でコードを完全リモート実行できる Jupyter カーネルです。

主な機能

- Databricks クラスタでの完全リモート実行
- ローカルファイルの自動同期 (gitignore 互換)
- セッション状態の永続化と自動再接続
- クラスタ自動起動 (停止中でも自動で起動)
- 画像/テーブル出力サポート
- 実行進捗のリアルタイム表示 (経過時間、クラスタ状態)

使い方

```bash
pip install jupyter-databricks-kernel
python -m jupyter_databricks_kernel.install
```

詳細は README を参照してください。

## 3. 開発の振り返り

### 3.1. 数字で見る開発

| 項目     | 数値                    |
| ------   | ------                  |
| 開発期間 | 約7週間 (10/23 - 12/12) |
| Issue    | 50件                    |
| PR       | 54件                    |
| リリース | 8回 (v0.1.0 → v1.1.4)  |

### 3.2. タイムライン

| 日付     | 内容                                           |
| ------   | ------                                         |
| 10/23    | Issue 作成、優先度付け (P0-P4)                 |
| 11/29    | 基盤構築 (mise + uv + pre-commit + Renovate)   |
| 11/30    | 最小限カーネル実装、CI/CD 整備                 |
| 12/03-04 | セッション状態管理、ruff 移行                  |
| 12/04-07 | ハッシュベースファイル同期、gitignore 互換     |
| 12/07-08 | ドキュメント整備、PyPI 公開 (v0.1.0 → v1.0.0) |
| 12/08    | クラスタ自動起動、hatch-vcs 導入               |
| 12/09    | 画像/テーブル出力対応、~/.databrickscfg 対応   |
| 12/10    | Git Folders 互換性対応                         |
| 12/12    | 実行進捗のリアルタイム表示 (v1.1.4)            |

## 4. やってよかったこと

### 4.1. Issue 駆動開発

開発開始時に優先度付きの Issue を作成しました。

- P0: プロジェクト基盤、最小限カーネル
- P1: CI/CD、セッション管理、ファイル同期
- P2: 出力レンダリング、セキュリティ、ドキュメント
- P3: パッケージング/PyPI

P0 を最初に完成させたことで、早期に動くものができました。
機能追加は P1 以降で段階的に行うことで、スコープクリープを防げました。

### 4.2. ガードレール整備

開発初期に以下を整備しました。

- mise: ツールバージョン管理
- uv: Python パッケージ管理
- pre-commit: Linter/Formatter 自動実行
- GitHub Actions: CI/CD

これにより、コード品質を維持しながら高速に開発を進められました。

ガードレールの詳細は以下の記事で紹介しています。

@[card](https://zenn.dev/genda_jp/articles/2025-12-06-ai-guardrails-local-cloud)

### 4.3. PyPI 公開の自動化

hatch-vcs でバージョン管理を自動化し、GitHub Actions で PyPI へのパブリッシュを自動化しました。

```yaml
# タグプッシュで自動リリース
on:
  push:
    tags:
      - 'v*'
```

タグを打つだけでリリースできる仕組みは非常に便利です。

## 5. うまくいったこと・いかなかったこと

### 5.1. うまくいったこと

- mtime ベースの同期 → ハッシュベースへの移行で信頼性向上
- Databricks CLI と同じ gitignore 形式を採用して学習コスト削減
- hatch-vcs 導入でバージョン管理の手間を削減

### 5.2. うまくいかなかったこと

- 計画から実装まで約5週間のブランク (モチベーション維持が課題)
- 最初の同期実装で `.git` や `.venv` を除外し忘れ、後から修正

## 6. 今後の展望

Open Issue として以下を検討中です。

- 理想的な Databricks プロジェクト構成の模索 (Skinny Notebook Wrapper + Pure Python)
- Python 3.11 サポート終了対応 (DBR 15.4 LTS、2027年)

## 7. おわりに

Issue でバグ報告や機能提案などお気軽にどうぞ。

@[card](https://github.com/i9wa4/jupyter-databricks-kernel)
