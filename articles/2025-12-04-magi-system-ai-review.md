---
title: "Vim x tmux によるレビュー用 MAGI システム (AI多数決レビューシステム)"
emoji: "🐴"
type: "tech"
topics:
  - "claudecode"
  - "codexcli"
  - "tmux"
  - "vim"
publication_name: "genda_jp"
published: true
published_at: 2025-12-04 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ3 Day 4 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

Vim と tmux を活用して複数の AI エージェント (Claude Code、Codex CLI) による多数決レビューの仕組みを構築しました。

:::message
本記事の内容は 2025年12月時点での検証結果に基づいています。
:::

## 2. MAGI システムとは

アニメ「新世紀エヴァンゲリオン」に登場する3台のスーパーコンピュータシステムです。

- MELCHIOR-1: 科学者としての赤木ナオコ
- BALTHASAR-2: 母親としての赤木ナオコ
- CASPER-3: 女としての赤木ナオコ

それぞれ異なる人格が独立に判断し、多数決で結論を下す仕組みです。

これをレビューに応用しようという試みです。

## 3. 操作デモ

話が分かりやすいように操作の様子を先に共有します。
以下は Vim から複数の AI エージェントに同じプロンプトを送信している様子です (4ペイン構成)。

<!-- rumdl-disable MD057 -->
@[youtube](AyE-ruGOGCc)
<!-- rumdl-enable MD057 -->

## 4. 構成

### 4.1. 利用ツール

#### 4.1.1. vde-layout

@[card](https://github.com/yuki-yano/vde-layout)

`vde-layout` コマンドを実行することで予め YAML で設定した tmux レイアウトを適用できます。
毎回手動でペイン分割する手間が省けて今回のユースケース以外でも活躍する激推しツールです！！

#### 4.1.2. vim-tmux-send-to-ai-cli

@[card](https://github.com/i9wa4/vim-tmux-send-to-ai-cli)

Vim から tmux 経由で AI エージェント起動中のペインにプロンプトを送信するためのプラグインです。
結局手動でプロンプトを送信することには変わりないので、半自動化といったところでしょうか。

- 送信先
    - 同一ウインドウの中で最も小さい番号のペインに送信 (デフォルト)
    - 同一ウインドウの特定のペインに送信
    - 同一ウインドウの全てのペインに送信
- 送信内容
    - カーソル行
    - 段落
    - 選択範囲
    - ファイル全体
    - 行範囲 (例: 10行目から20行目)

#### 4.1.3. ddc-source-slash-commands

@[card](https://github.com/i9wa4/ddc-source-slash-commands)

@[card](https://github.com/Shougo/ddc.vim)

この2つの Vim プラグインを利用するとカスタムスラッシュコマンドを入力補完付きで簡単に入力できます。
これで AI ツールの入力欄のクオリティに左右されずにプロンプトを作成できます。

カスタムスラッシュコマンドに対応していない AI エージェントの場合でもファイルパスをスニペットで登録しておくなどの工夫で対応可能です。

各プラグインの設定詳細はドキュメントを参照してください。

#### 4.1.4. AI エージェント

いつでも乗り替えられるような心構えで Claude Code と Codex CLI を利用しています。

@[card](https://github.com/anthropics/claude-code)

@[card](https://github.com/openai/codex)

### 4.2. ウインドウ構成 (vde-layout)

```text
+----------------------------+---------------------------+
|                            |                           |
|          pane 0            |          pane 1           |
|           Vim              |        Claude Code        |
|                            |                           |
+------------------+------------------+------------------+
|      pane 2      |      pane 3      |      pane 4      |
|    Codex CLI     |    Codex CLI     |   Claude Code    |
+------------------+------------------+------------------+
```

今は5ペイン構成 (Vim 1 + AI エージェント 4) です。

設定ファイルはこちら。

```yaml:~/.config/vde/layout.yml
presets:
  review:
    name: review
    description: review
    windowMode: current-window
    layout:
      type: vertical
      ratio: [3, 1]
      panes:
        - type: horizontal
          ratio: [1, 1]
          panes:
            - name: editor
              command: vim -c "execute 'edit' '.i9wa4/temp.md'->expand()"
              focus: true
            - name: claude
              command: claude --dangerously-skip-permissions
        - type: horizontal
          ratio: [1, 1, 1]
          panes:
            - name: codex
              command: codex --yolo
            - name: codex
              command: codex --yolo
            - name: claude
              command: claude --dangerously-skip-permissions
```

ポイント

- `windowMode: current-window` で現在のウインドウにレイアウトを適用
- 上段は Vim と Claude Code を 1:1 で配置
- 下段は Codex CLI x 2 と Claude Code を 1:1:1 で配置
- Vim にフォーカスが当たった状態で起動

トークン使用量が許せば各モデルに各種ペルソナを付与するくらいまで起動数を増やしてもよさそうです。

## 5. カスタムスラッシュコマンド

2つのカスタムスラッシュコマンドを用意しました。

レビュー手法自体は特に凝った指示をしているわけではないので、必要に応じてプロンプトを調整してください。

### 5.1. /my-review

各ペインの AI エージェントが独立してレビューを実施するコマンドです。

```markdown
# my-review

このファイルを読んだら直ちに GitHub Pull Request レビューを実施する

## 1. 事前準備

- この Worktree は Pull Request の対象ブランチである
- Pull Request 番号は `gh pr view --json number -q '.number'` で取得する
- もし Pull Request 番号が不明な場合は分岐元との差分のレビューを実施する

## 2. 差分の取得方法

- 差分は `git diff main...HEAD` で取得する (ドット3つ)

## 3. レビュー方法

- Pull Request の本文とコメントを全て読み込む
- あらゆる指摘を詳細に抽出する
- 重要度順に指摘を並べる

## 4. レビュアーとしての役割

- 以下のコマンドで取得できる tmux ペイン番号 N ごとに異なるレビュアーの役割を担う
    - `tmux display-message -p -t "${TMUX_PANE}" '#{pane_index}'`
- ペイン番号 N に応じた役割
    - N % 3 == 0:
        - セキュリティ専門家。堅実派。最新の脆弱性情報を参照する。
    - N % 3 == 1:
        - パフォーマンス専門家。せっかち。効率化のためのベストプラクティスを参照する。
    - N % 3 == 2:
        - コード品質専門家。完璧主義者。リポジトリ内の関連コードやドキュメントを可能な限り参照する。

## 5. レビュー結果の Markdown ファイル出力

- レビュー結果を以下に保存する
    - `.i9wa4/YYYYMMDD-pN-review.md` (N: tmux ペイン番号)
```

ポイント

- 出力ファイル名に tmux ペイン番号を含めることで各エージェントが同時に実行しても競合しない
- ペイン番号に応じてペルソナを切り替えることで、同じモデルでも異なる観点からレビューを受けられる
    - とはいえ同じモデルではあるので限界はあります
    - 自分自身が何者であるかを AI エージェントに自認させるのは難しいですが、自分のペイン番号は自認させることができました

### 5.2. /summarize-reviews

全ペインのレビュー結果を集約するコマンドです。

```markdown
# sumamrize-reviews

このファイルを読んだらレビュー結果を集約する

## 1. 手順

1. `.i9wa4/` ディレクトリの君以外のペインのレビュー結果を読み込む
1. すべてのレビュー結果を `.i9wa4/YYYYMMDD-all-reviews.md` に集約して改めて重要度順に並び替える
1. ファイル冒頭に指摘タイトル・重要度・指摘者 (ペイン番号) の対応表を追加する
```

ポイント

- 集約ファイルには指摘タイトル・重要度・指摘者の対応表が含まれるのでレビューの全体像を把握しやすくなっています
- 複数エージェントが同じ点を指摘した場合は確度が高いと判断できます

## 6. 全体の流れのおさらい

### 6.1. レイアウト起動

```bash
vde-layout review
```

### 6.2. 全ペインへ /my-review を一斉送信

vim-tmux-send-to-ai-cli の機能で、`/my-review` を全 AI エージェントに一斉送信します。

各エージェントは独立して PR の差分を取得し、レビューを実施します。

### 6.3. レビュー結果の収集

各エージェントからのレビュー結果は以下の形式で出力されます。

`.i9wa4/YYYYMMDD-pN-review.md`

出力例

- `.i9wa4/20251201-p1-review.md` (Claude Code)
- `.i9wa4/20251201-p2-review.md` (Codex CLI)
- `.i9wa4/20251201-p3-review.md` (Codex CLI)
- `.i9wa4/20251201-p4-review.md` (Claude Code)

### 6.4. 結果の統合

レビューが終わったあといずれかのペインに `/summarize-reviews` を送信すると、全レビュー結果を集約した `.i9wa4/YYYYMMDD-all-reviews.md` が生成されます。

## 7. その他 Tips

### 7.1. global gitignore ディレクトリの活用

ファイル出力先の `.i9wa4/` ディレクトリは私の環境では global gitignore に登録されています。
作業場所としてプロジェクト内にディレクトリがあると便利です。

参考: @mizchi さんのポスト

@[tweet](https://twitter.com/mizchi/status/1914543131888066561)

### 7.2. タスクの性質

同一プロジェクト内で複数の AI エージェントを並列実行する場合、タスクの性質を見極める必要があります。

- 並列実行に適したタスク
    - コードレビュー (読み取り専用)
    - ドキュメント生成 (出力先を分離)
    - テスト作成 (ファイル名を分離)
- 並列実行に不向きなタスク
    - 同一ファイルの編集
    - 依存関係のある連続タスク

## 8. おわりに

複数の AI エージェントを実行し、MAGI システムのようなレビュー体制を構築する方法を紹介しました。

ターミナルでの AI 活用がさらに広がることを期待しています。
