---
title: "AI エージェント時代の波に乗るための tmux 入門 — マルチエージェントオーケストレーションの相棒"
emoji: "🐴"
type: "tech"
topics:
  - "tmux"
  - "cli"
  - "terminal"
  - "dotfiles"
  - "aiagent"
published: true
published_at: 2026-02-08 18:30
---

## 1. はじめに — なぜ今 tmux なのか

Claude Code や Codex CLI のような AI コーディングエージェントを複数動かし、それぞれに異なるタスクを割り当てて開発を進める手法が最近話題になっています。

並行作業をスケーラブルにするための相棒となりうる tmux の使い方を紹介します。

### 1.1. そもそも設定との向き合い方について

Agent Skills やそれ以外のツールの設定について地道に改善する、もしくはトークンを消費して AI に環境を改善させた時間と料金を無駄にしないために dotfiles を作ってこれらを管理していくことをおすすめしています。
作業の進め方を自分なりに改善点を見出す取り組みを始めてみると、それまでの自分って何だったんだろうと思えるような飛躍的な進化が得られます。
いま AI に環境設定を改善させる土壌を用意しておくと、生産性を AI に改善させ続けることができシンギュラリティを目指すことができると考えています。

@[card](https://i9wa4.github.io/blog/2026-01-08-why-dotfiles-still-matters-to-me.html)

### 1.2. ターミナルマルチプレクサの選択肢

筆者はマルチエージェントの協調を制御する「マルチエージェントオーケストレーション」について真剣に向き合ってみた結果、以下の要件を満たすターミナルマルチプレクサが必要だと結論づけました。

※ペインとは個々のターミナル画面のことを指します。

- 外部プロセスからの制御が可能な CLI
- ペインの動的管理 (ペインが増えたり減ったりすることへの対応)
- ペインの状態管理 (通知有無、非アクティブ時間の把握など)
- ペインのキャプチャ
- 任意ペインへのキーストローク送信
- ペインのターゲティング (名前または ID による指定)
- 宣言的レイアウト管理 (ツール連携含む)

ここに挙げた機能が1つでも欠けるツールの場合はオーケストレーション制御に不満を感じたときに対処のしようがない可能性があります。
操作性に難ありですが現状はマルチエージェントオーケストレーションのために tmux を選択していくのは賢明かと思います。

### 1.3. yuki-yano 氏について

本記事では、筆者が実際に運用している tmux 設定を「真似してもらう」前提で紹介します。
ちなみに私は tmux ヘビーユーザーである yuki-yano 氏の tmux 関連の記事、設定、ツール群 (vde-layout, zeno.zsh) に大いに影響を受けているので実質その紹介記事とも言えます。
AI エージェント時代以前から愛用させていただいていましたが、昨今更に輝きを放っていると感じています。

@[card](https://github.com/yuki-yano)

@[card](https://qiita.com/yuki-yano/items/ef5e6b63c8f9af2f03c0)

@[card](https://github.com/yuki-yano/vde-layout)

@[card](https://github.com/yuki-yano/zeno.zsh)

それではまず tmux の基本概念を整理しましょう。

## 2. tmux の基本 — セッション/ウインドウ/ペイン

本記事の内容は以下の環境で動作確認しています。

- tmux 3.6a
- vde-layout 0.1.1
- zeno.zsh 2026-02-04 版 [887edb0](https://github.com/yuki-yano/zeno.zsh/commit/887edb0367fb4eaa972dd280bb321e4cedd7903c)

### 2.1. 3層構造

tmux を理解する上で最も重要なのが、3層のモデルです。

tmux はターミナルマルチプレクサとして、セッション・ウインドウ・ペインという3層構造で複数のターミナル環境を管理できます。
これにより AI エージェントごとに独立した作業環境を用意し、効率的に監視・操作できます。

| 層         | 役割                                  | ブラウザでの例え       |
| ---        | ---                                   | ---                    |
| セッション | プロジェクトや作業単位をまとめる      | ブラウザウインドウ全体 |
| ウインドウ | セッション内の画面切り替え単位        | タブ                   |
| ペイン     | ウインドウ内の画面分割 (同時表示可能) | タブ内の分割表示       |

![tmuxの3層構造: セッション、ウインドウ、ペイン](/images/2026-02-08-tmux-intro-ai-agent-orchestration/tmux-3-layer-model.drawio.png)

yuki-yano 氏の記事でも触れられていますが、「ウインドウ = タブ、セッション = 別のブラウザウインドウ」という理解が分かりやすいです。

### 2.2. 最低限の操作

tmux をインストールしたら、以下の操作を覚えれば基本的な利用が可能です。

ペイン操作 (prefix = Ctrl-b がデフォルト)

| 操作                 | キー                   |
| -------------------- | ---------------------- |
| ペインを縦に分割     | prefix %               |
| ペインを横に分割     | prefix "               |
| ペイン間を移動       | prefix 矢印キー        |
| ペインを閉じる       | prefix x または exit   |

ウインドウ操作

| 操作                 | キー         |
| -------------------- | ------------ |
| 新規ウインドウ作成   | prefix c     |
| 次のウインドウに移動 | prefix n     |
| 前のウインドウに移動 | prefix p     |
| ウインドウを閉じる   | prefix &     |

セッション操作

| 操作                     | キー         |
| ------------------------ | ------------ |
| セッション一覧を表示     | prefix s     |
| セッション名を変更       | prefix $     |

ここまでが基本操作です。次は、日常的に使い続けるための設定を入れていきましょう。

## 3. tmux.conf で真似してほしい設定

筆者が実際に運用している設定の中から、日常的に使っているものを紹介します。

tmux の設定ファイルは `~/.config/tmux/tmux.conf` に配置します (XDG Base Directory 仕様に従う場合)。
`~/.tmux.conf` でも動作しますが以降で紹介するツールも `~/.config` に置くので合わせちゃいましょう。

### 3.1. prefix 不要の切り替え

マルチエージェント環境ではペイン・ウインドウ・セッションを頻繁に切り替えるので prefix を省略できるようにしています。

```conf:tmux.conf
# Windows / Sessions control
bind-key -n M-Left previous-window
bind-key -n M-Right next-window
bind-key -n M-Up switch-client -p
bind-key -n M-Down switch-client -n

# Panes control
bind-key -n S-Left select-pane -L
bind-key -n S-Right select-pane -R
bind-key -n S-Up select-pane -U
bind-key -n S-Down select-pane -D
```

tmux の `M-` は Meta キー (macOS では Option、Linux/Windows では Alt) を指します。

| 操作                     | キー               |
| ------------------------ | ------------------ |
| 前のウインドウに移動     | Meta + 左矢印      |
| 次のウインドウに移動     | Meta + 右矢印      |
| 前のセッションに移動     | Meta + 上矢印      |
| 次のセッションに移動     | Meta + 下矢印      |
| 左のペインに移動         | Shift + 左矢印     |
| 右のペインに移動         | Shift + 右矢印     |
| 上のペインに移動         | Shift + 上矢印     |
| 下のペインに移動         | Shift + 下矢印     |

![セッション/ウインドウ間移動](/images/2026-02-08-tmux-intro-ai-agent-orchestration/tmux-navigation-session-window.drawio.png)

![ペイン間移動](/images/2026-02-08-tmux-intro-ai-agent-orchestration/tmux-navigation-pane.drawio.png)

自分の場合、並行作業中に片手でセッションとウインドウを高速に切り替えられるおかげで、マルチエージェントオーケストレーションの監視が非常に楽になりました。

### 3.2. カレントディレクトリ継承

新しいペインやウインドウを開いたとき、カレントディレクトリを引き継ぐ設定です。

```conf:tmux.conf
# Inherit current path
bind-key % split-window -h -c "#{pane_current_path}"
bind-key '"' split-window -v -c "#{pane_current_path}"
bind-key c new-window -c "#{pane_current_path}"
```

### 3.3. ステータスバー

```conf:tmux.conf
set-option -g status-left " #{=50:session_name} "
set-option -g status-left-length 52
set-option -g status-position top
```

設定内容は以下の通りです。

- 位置: 上部 (ただの好み)
- 左側: セッション名 (最大50文字)

私は以降の設定でセッション名を自動付与させているのでそれを表示したい長さだけ表示させています。

### 3.4. prefix の Ctrl-b が押しにくい問題

ここまで読んで「prefix (Ctrl-b) を変更しないの?」と思った方もいるかもしれません。

私はデフォルトの `Ctrl-b` をそのまま使っています。理由は以下の通りです。

- ペイン移動は prefix 不要バインド (`Meta + 矢印`, `Shift + 矢印`) で済む
- ペイン分割は後述する vde-layout に任せる (手動分割をほとんど使わない)
- マウスでペイン選択も可能 (私はやっていませんが設定すればできます)

prefix を叩く機会が比較的少ないことと、気合でデフォルトキーバインドに慣れた都合で変更の必要性を感じていません。

## 4. tmux popup 活用と周辺ツール連携

ここまでの設定で日常操作はかなり快適になりました。ただ、メイン作業中にちょっとした確認作業をしたいとき、画面を切り替えると集中が途切れてしまいます。そこで活躍するのが tmux popup 機能です。

tmux popup 機能を、メイン作業を邪魔せずに一時的な確認作業をする際に使っています。

### 4.1. popup の基本

```conf:tmux.conf
# popup
bind-key u display-popup -d '#{pane_current_path}' -w 90% -h 90% -E
bind-key g display-popup -d '#{pane_current_path}' -w 90% -h 90% -E 'lazygit'
```

| キー     | 機能                                   |
| -------- | -------------------------------        |
| prefix u | tmux popup 起動 (90% x 90%)            |
| prefix g | lazygit in tmux popup 起動 (90% x 90%) |

AI エージェントの作業中に Git の状態を確認したり、簡単なコマンドを実行したりする際にこの機能を多用しています。

## 5. vde-layout でレイアウトを固定する

vde-layout (yuki-yano 氏作) は YAML でレイアウトを定義しておけばコマンド一発で複雑な tmux ウインドウ構成を再現できるツールです。

@[card](https://github.com/yuki-yano/vde-layout)

### 5.1. 手動分割の手間を省く

以前、開発環境を整えるたびに以下の作業を繰り返していました。

1. `prefix %` で縦分割 `prefix "` で横分割
2. 各ペインのサイズを調整
3. 各ペインで `vim` や `claude` を起動

この繰り返しが面倒だったので、vde-layout を導入しました。YAML で一度定義しておけば、以下のような記述だけで環境が整います。

```yaml:~/.config/vde/layout.yml
presets:
  main:
    name: main
    description: main
    windowMode: current-window
    layout:
      type: horizontal
      ratio: [1, 1]
      panes:
        - name: editor
          command: vim
          focus: true
        - name: worker
          command: claude --model opus
```

起動コマンド

```bash
vde-layout main
```

このコマンドを実行するだけで、エディタと Claude Code が並んだ状態を一発で作れます。
これは左右にペインを並べるだけの簡単な例ですが vde-layout ならスクリーンショットでよく見るような複雑なレイアウトも YAML で定義して再現できます。

また複数ウインドウにわたるレイアウトを一発で作成することも可能です。

長くなるので以下の折りたたみで詳細を紹介します。

::: details 一発で複数ウインドウのレイアウトを作成する

以下のような YAML を用意して

```console
vde-layout concierge; vde-layout orchestrator; vde-layout observers
```

などと実行すれば、3つのウインドウがそれぞれ定義通りに作成されます。
コツは最初に呼び出すレイアウトのみ `windowMode: current-window` にしておくことです。

```yaml:~/.config/vde/layout.yml
presets:
  concierge:
    name: concierge
    description: concierge
    windowMode: current-window
    layout:
      type: horizontal
      ratio: [1, 1]
      panes:
        - name: editor
          command: vim
          focus: true
        - name: claude
          command: claude

  orchestrator:
    name: orchestrator
    description: orchestrator
    windowMode: new-window
    layout:
      type: horizontal
      ratio: [1, 1]
      panes:
        - type: vertical
          ratio: [1, 1]
          panes:
            - name: claude
              command: claude
            - name: claude
              command: claude
        - type: vertical
          ratio: [1, 1]
          panes:
            - name: claude
              command: claude
            - name: codex
              command: codex

  observers:
    name: observers
    description: observers
    windowMode: new-window
    layout:
      type: horizontal
      ratio: [1, 1]
      panes:
        - type: vertical
          ratio: [1, 1]
          panes:
            - name: claude
              command: claude
            - name: claude
              command: claude
        - type: vertical
          ratio: [1, 1]
          panes:
            - name: codex
              command: codex
            - name: codex
              command: codex
```

:::

### 5.2. Ctrl-b 問題の回収

前述の「prefix の Ctrl-b が押しにくい問題」で触れたように vde-layout を使えばペイン分割で Ctrl-b を叩く必要がなくなります。

手動分割の代わりに `vde-layout <preset>` を実行するだけで、定義済みのレイアウトが展開されます。これにより、prefix キーを使う頻度がさらに減ります。

vde-layout でレイアウトは一発で作れるようになりました。でも `vde-layout main` っていちいちフルタイプするのは面倒になりそうですよね？

## 6. zeno.zsh でシェルを使いやすくする

そこで活用できるのが zeno.zsh (yuki-yano 氏作) です。
スニペットをはじめとした便利機能の入った Zsh/fish プラグインで、 スニペット機能を使えば、短い文字列で長いコマンドを呼び出せます。

@[card](https://github.com/yuki-yano/zeno.zsh)

### 6.1. スニペットの活用例

`vde-layout main` のような頻繁に使うコマンドを毎回フルタイプするのが面倒だったので、zeno.zsh で短縮入力を設定しました。

`vd` と入力して `Space` を押すだけで `vde-layout main` に展開されます。

同じことは abbrev でも実現できますがコマンド履歴をみても分かりづらいので私はスニペット機能を多用しています。

### 6.2. zeno.zsh のセットアップ

zinit (Zsh プラグインマネージャー) による導入例

```zsh:~/.zshrc
# Zinit (manual install)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME"/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# zeno.zsh
zinit light yuki-yano/zeno.zsh

if [[ -n "${ZENO_LOADED}" ]]; then
  bindkey " "  zeno-auto-snippet
  bindkey "^m" zeno-auto-snippet-and-accept-line
  bindkey "^i" zeno-completion
  bindkey "^g" zeno-ghq-cd
  bindkey "^r" zeno-history-selection
  bindkey "^x^i" zeno-insert-snippet
else
  bindkey "^r" history-incremental-search-backward
fi
```

キーバインド

| キー            | 機能                       |
| --------------- | -------------------------- |
| `Space`         | スニペット自動展開         |
| `Enter`         | スニペット展開 + 実行      |
| `Tab`           | 補完                       |
| `Ctrl-g`        | ghq リポジトリ移動         |
| `Ctrl-r`        | 履歴選択                   |
| `Ctrl-x Ctrl-i` | スニペット挿入             |

### 6.3. スニペット定義

```yaml:~/.config/zeno/config.yaml
snippets:
  - name: (vde-layout) main
    keyword: vd
    snippet: vde-layout main

  # 複数ウインドウレイアウトのスニペット例
  - name: (vde-layout) preset-a
    keyword: va
    snippet: vde-layout concierge; vde-layout orchestrator; vde-layout observers
```

### 6.4. ghq 連携: セッション名自動リネーム

ghq でリポジトリや worktree を一元管理している方向けの設定例です。
もし ghq を使ってみたい場合は以下の記事を参考にしてください。

@[card](https://zenn.dev/genda_jp/articles/2025-12-07-manage-git-worktree-with-ghq)

zeno.zsh の zeno-ghq-cd zle 機能を使うと、リポジトリ移動時に tmux セッション名が自動でリポジトリ名に変わります。

```zsh:~/.zshrc
function zeno-ghq-cd-post-hook-impl() {
  local dir="$ZENO_GHQ_CD_DIR"
  if [[ -n $TMUX ]]; then
    local repository=${dir:t}
    local session=${repository//./-}
    tmux rename-session "${session}"
  fi
}

zle -N zeno-ghq-cd-post-hook zeno-ghq-cd-post-hook-impl
```

これにより、`Ctrl-g` でリポジトリを選択して移動すると、tmux セッション名が自動的にリポジトリ名 (例: `my-project`) に変更されます。

筆者は複数のプロジェクトを並行して作業することが多いので、セッション名でプロジェクトを識別できるこの仕組みは手放せません。

ここまで tmux の設定 → popup → vde-layout → zeno と、作業環境の自動化を一通り紹介してきました。
これらの仕組みを組み合わせることで、マルチエージェント環境の運用効率を大幅に改善できています。

## 7. まとめと次の一歩

### 7.1. 本記事のまとめ

ここまで、筆者が実際に運用している tmux 環境を紹介してきました。

| 技術       | 役割                                |
| ---        | ---                                 |
| tmux       | 3層構造でマルチエージェント管理     |
| tmux.conf  | prefix を多用しすぎないキーバインド |
| tmux popup | 一時作業領域の確保                  |
| vde-layout | YAML でレイアウト一発生成           |
| zeno.zsh   | スニペットで高速入力                |
| ghq        | リポジトリ一元管理                  |

筆者が意識したのは「凝りすぎない実用設定」です。そのままコピーしても、部分的に取り入れても、実用的に使える構成になっていると思います。

### 7.2. tmux は「プログラマブルなマルチエージェントオーケストレーション基盤」

tmux は単なるターミナル分割ツールではありません。

本記事で紹介した機能群をベースにより高度なマルチエージェント管理を実現できます。

本記事ではあまり触れませんでしたが、1.2節で挙げた要件を再掲します。

> - 外部プロセスからの制御が可能な CLI
> - ペインの動的管理 (ペインが増えたり減ったりすることへの対応)
> - ペインの状態管理 (通知有無、非アクティブ時間の把握など)
> - ペインのキャプチャ
> - 任意ペインへのキーストローク送信
> - ペインのターゲティング (名前または ID による指定)
> - 宣言的レイアウト管理 (ツール連携含む)

これらの機能を見ると tmux はやっぱりマルチエージェントオーケストレーション基盤として非常に強力そうですよね。

### 7.3. 次の一歩

次回はこの tmux 利用方法をある程度取り入れていれば簡単に実現できるマルチエージェントオーケストレーションの構築方法を紹介します。
Claude Code や Codex CLI のチューニングなしに、複数種類の AI コーディングエージェントを用いることができます。
お楽しみに！

### 7.4. 参考リンク

@[card](https://github.com/tmux/tmux/wiki)

@[card](https://github.com/yuki-yano/vde-layout)

@[card](https://github.com/yuki-yano/zeno.zsh)

@[card](https://qiita.com/yuki-yano/items/ef5e6b63c8f9af2f03c0)

@[card](https://github.com/i9wa4/dotfiles)
