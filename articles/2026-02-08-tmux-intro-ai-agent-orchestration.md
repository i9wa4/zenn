---
title: "AI エージェント時代の波に乗るための tmux 入門 — マルチエージェントオーケストレーションの相棒"
emoji: "🐴"
type: "tech"
topics:
  - "tmux"
  - "vde"
  - "zeno"
  - "shell"
published: false
---

## 1. はじめに — なぜ今 tmux なのか

Claude Code や Codex CLI のような AI コーディングエージェントを複数動かし、それぞれに異なるタスクを割り当てて開発を進める手法が最近話題になっています。

並行作業をスケーラブルにするための相棒となりうる tmux の使い方を紹介します。

### 1.1. ターミナルマルチプレクサの選択肢

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
操作性に難ありですが現状はマルチエージェントオーケストレーションにために tmux を選択していくのは賢明かと思います。

### 1.2. yuki-yano 氏について

本記事では、筆者が実際に運用している tmux 設定を「真似してもらう」前提で紹介します。
ちなみに私は tmux ヘビーユーザーである yuki-yano 氏の tmux 関連記事設定とツール群 (vde-layout, zeno.zsh) に大いに影響を受けているので実質その紹介記事とも言えます。
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

### 2.1. 3層構造の構造

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

```bash
# tmux を起動
tmux

# セッションをデタッチ (バックグラウンドに退避)
Ctrl-b d

# セッションにアタッチ (復帰)
tmux attach
```

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

## 3. tmux.confで真似してほしい設定

本セクションでは、筆者の実際の設定から特に有用なものを紹介します。

tmux の設定ファイルは `~/.config/tmux/tmux.conf` に配置します (XDG Base Directory 仕様に従う場合)。従来の `~/.tmux.conf` でも動作します。設定を変更したら `tmux source-file ~/.config/tmux/tmux.conf` で再読み込みできます。

完全な設定は筆者の dotfiles を参照してください。

ファイルパス: `~/ghq/github.com/i9wa4/dotfiles/config/tmux/tmux.conf`

### 3.1. vi風ペイン操作

Vim ユーザーなら直感的に使えるキーバインドです。Vim を使わない方でも、一度覚えれば統一的に操作できます。

```conf:tmux.conf
# Panes control
bind-key -r H resize-pane -L 1
bind-key -r J resize-pane -D 1
bind-key -r K resize-pane -U 1
bind-key -r L resize-pane -R 1

bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

bind-key -n S-Left select-pane -L
bind-key -n S-Right select-pane -R
bind-key -n S-Up select-pane -U
bind-key -n S-Down select-pane -D

# Copy mode
set-window-option -g mode-keys vi
```

ポイント

- `h/j/k/l`: ペイン選択 (prefix + h で左のペインに移動)
- `H/J/K/L`: ペインリサイズ (prefix + H で左に1行拡大、repeatable なので連打可能)
- `Shift + 矢印キー`: ペイン選択 (prefix不要!)
- `mode-keys vi`: コピーモードで vi 操作

### 3.2. prefix不要の切り替え

マルチエージェント環境では、頻繁にセッション・ウインドウを切り替えます。prefix を省略できると操作が爆速になります。

```conf:tmux.conf
# Windows / Sessions control
bind-key -n M-Left previous-window
bind-key -n M-Right next-window
bind-key -n M-Up switch-client -p
bind-key -n M-Down switch-client -n
```

| 操作                     | キー             |
| ------------------------ | ---------------- |
| 前のウインドウに移動     | Alt + 左矢印     |
| 次のウインドウに移動     | Alt + 右矢印     |
| 前のセッションに移動     | Alt + 上矢印     |
| 次のセッションに移動     | Alt + 下矢印     |

![セッション/ウインドウ間移動](/images/2026-02-08-tmux-intro-ai-agent-orchestration/tmux-navigation-session-window.drawio.png)

![ペイン間移動](/images/2026-02-08-tmux-intro-ai-agent-orchestration/tmux-navigation-pane.drawio.png)

マルチエージェントの並行作業時、片手で高速に切り替えられるのが非常に便利です。

### 3.3. 現在パス継承

新しいペインやウインドウを開いたとき、現在のディレクトリを引き継ぐ設定です。

```conf:tmux.conf
# Inherit current path
bind-key % split-window -h -c "#{pane_current_path}"
bind-key '"' split-window -v -c "#{pane_current_path}"
bind-key c new-window -c "#{pane_current_path}"
```

AI エージェントが動いているディレクトリと同じ場所で、別のターミナルを開きたい場面が頻繁にあります。この設定があれば、毎回 `cd` する手間が省けます。

### 3.4. ペインボーダー設定

複数のペインを使用する際、「今どこで何が動いているか」を一目で把握できると便利です。

```conf:tmux.conf
# Options
set-option -g pane-active-border-style 'fg=red'
set-option -g pane-border-format '> #{pane_index} > #{pane_id} > #{pane_current_command} > #{history_size} Lines >'
set-option -g pane-border-status top
set-option -g pane-border-style 'fg=green'
```

ポイント

- アクティブペイン: 赤
- 非アクティブペイン: 緑
- ボーダーフォーマット: `> 0 > %1 > vim > 150 Lines >` のような形式で表示
    - ペイン番号 (`0`, `1`, ...)
    - ペイン ID (`%1`, `%2`, ...)
    - 実行中のコマンド (`vim`, `claude`, `bash` など)
    - 履歴行数 (`150 Lines`)
- ボーダー位置: 上部

これにより、どのペインで `claude` が動いているか、どのペインが `vim` かを瞬時に判別できます。マルチエージェント環境では、各ペインでどのプロセスが動いているかを一目で把握できることが重要です。

### 3.5. ステータスバー

```conf:tmux.conf
set-option -g status-interval 1
set-option -g status-left " #{=50:session_name} "
set-option -g status-left-length 52
set-option -g status-position top
set-option -g status-right "#(cd \"#{pane_current_path}\" && ~/ghq/github.com/i9wa4/dotfiles/bin/repo-status)#(~/ghq/github.com/i9wa4/dotfiles/bin/system-load)"
set-option -g status-right-length 200
```

ポイント

- 位置: 上部 (ペインボーダーと合わせて情報を集約)
- 左側: セッション名 (最大50文字)
- 右側: リポジトリ状態 + システム負荷 (カスタムスクリプト)
- 更新間隔: 1秒

リポジトリの Git 状態や CPU 負荷をリアルタイムで監視できます。

注: `status-right` で使用しているスクリプトは筆者の環境固有のものです。自分の環境に合わせてカスタマイズしてください。不要な場合は `set-option -g status-right ""` で無効化できます。

### 3.6. Ctrl-b コラム

ここまで読んで「prefix (Ctrl-b) を変更しないの?」と思った方もいるかもしれません。

筆者はデフォルトの `Ctrl-b` をそのまま使っています。理由は以下の通りです。

- ペイン移動は prefix 不要バインド (`Alt + 矢印`, `Shift + 矢印`) で済む
- ペイン分割は後述する vde-layout に任せる (手動分割をほとんど使わない)
- マウスでペイン選択も可能 (設定すれば)

つまり、prefix を叩く機会がほとんどないため、変更の必要性を感じていません。

設定で日常操作が快適になりました。次は、作業の集中を切らさないための Popup 活用です。

## 4. Popup活用と周辺ツール連携

tmux の Popup 機能を使うと、一時的な作業領域を確保できます。メイン作業を邪魔せずに、補助的なタスクを実行できるのが特徴です。

### 4.1. Popup の基本

```conf:tmux.conf
# Popup
bind-key u if-shell -F '#{==:#{session_name},_popup}' \
  { detach-client } \
  { display-popup -d '#{pane_current_path}' -w 90% -h 90% -E 'tmux attach -t _popup || tmux new -s _popup' }
bind-key f display-popup -w 60% -h 50% -E 'tmux list-sessions -F "#{session_name}" | fzf --reverse | xargs -I{} tmux switch-client -t {}'
bind-key g display-popup -d '#{pane_current_path}' -w 90% -h 90% -E 'lazygit'
```

| キー     | 機能                                                |
| -------- | --------------------------------------------------- |
| prefix u | `_popup` セッションを起動/切り離し (90% × 90%)     |
| prefix f | セッション一覧を fzf で選択 (60% × 50%)             |
| prefix g | lazygit 起動 (90% × 90%)                            |

Popup の利点

- メイン画面を隠さずに一時的な作業ができる
- 作業が終わったら `Ctrl-d` で即座に閉じられる
- `_popup` セッションは常駐しているため、入力した履歴が残る

例えば、AI エージェントの作業中に Git の状態を確認したり、簡単なコマンドを実行したりする際に重宝します。

### 4.2. TPM (Tmux Plugin Manager)

tmux のプラグインを管理するツールです。

```conf:tmux.conf
# List of plugins
set -g @plugin 'tmux-plugins/tpm'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.config/tmux/plugins/tpm/tpm'
```

インストール

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

プラグインのインストール

```bash
# tmux 内で実行
prefix + I
```

TPM を入れておくと、今後プラグインを追加する際に便利です。

Popup で集中は保てるようになりました。ただ、毎回ペインを手動で分割・配置するのは面倒です。これを解決するのが vde-layout です。

## 5. vde-layoutでレイアウトを固定する

yuki-yano 氏作の vde-layout を使うと、YAML でレイアウトを定義して一発で起動できます。

@[card](https://github.com/yuki-yano/vde-layout)

### 5.1. 課題と解決

課題 -- 手動でペインを分割・配置するのが面倒

毎回以下の作業を繰り返すのは非効率です。

1. `prefix %` で縦分割
2. `prefix "` で横分割
3. 各ペインのサイズを調整
4. 各ペインで `vim` や `claude` を起動

解決 -- YAML で一発生成

vde-layout を使えば、以下のように定義するだけで済みます。

```yaml:layout.yml
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
        - name: shell
```

起動コマンド

```bash
vde-layout main
```

これだけで、エディタとシェルが並んだレイアウトが起動します。

### 5.2. 実例: devプリセット

```yaml:layout.yml
  dev:
    name: dev
    description: dev
    windowMode: current-window
    layout:
      type: horizontal
      ratio: [1, 1]
      panes:
        - name: editor
          command: vim -c "execute 'edit' '.i9wa4/temp.md'->expand()"
          focus: true
        - name: worker
          command: claude --model opus
```

ポイント

- エディタで `.i9wa4/temp.md` を開いた状態で起動
- 右側に Claude Code (Opus モデル) を起動
- `windowMode: current-window` で現在のウインドウに展開

注意: Claude Code は各操作で確認を求めます。自動実行が必要な場合は適切な権限設定を行ってください。詳細は Claude Code の公式ドキュメントを参照してください。

起動

```bash
# 現在のウインドウにレイアウトを展開
vde-layout dev
```

このコマンド一つで、エディタと Claude Code が並んだ開発環境が即座に整います。

### 5.3. Ctrl-b問題の回収

前述の「Ctrl-b コラム」で触れたように、vde-layout を使えばペイン分割で Ctrl-b を叩く必要がなくなります。

手動分割の代わりに `vde-layout <preset>` を実行するだけで、定義済みのレイアウトが展開されます。これにより、prefix キーを使う頻度がさらに減ります。

vde-layout でレイアウトは一発で作れるようになりました。でも `vde-layout dev` っていちいち打つの、面倒じゃないですか?

## 6. zeno.zshでスニペット運用を高速化

yuki-yano 氏作の zeno.zsh を使えば、スニペットで一発入力できます。

@[card](https://github.com/yuki-yano/zeno.zsh)

### 6.1. 課題と解決

課題 -- コマンド入力が面倒

`vde-layout dev` のような頻繁に使うコマンドを毎回フルタイプするのは非効率です。

解決 -- スニペットで一発

zeno.zsh を使えば、以下のように短縮できます。

- `vd` と入力して `Space` → `vde-layout dev` に展開

### 6.2. zeno.zsh のセットアップ

zinit による導入例

ファイルパス: `~/ghq/github.com/i9wa4/dotfiles/config/zsh/zinit.zsh`

```zsh:zinit.zsh
# Zinit (manual install)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME"/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# zeno.zsh (lazy loading via zinit turbo mode)
zinit ice lucid depth"1" blockf \
  atload'
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
  '
zinit light yuki-yano/zeno.zsh
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

ファイルパス: `~/ghq/github.com/i9wa4/dotfiles/config/zeno/config.yaml`

```yaml:config.yaml
snippets:
  - name: (vde-layout) dev
    keyword: vd
    snippet: vde-layout dev

  - name: (git) status short
    keyword: gs
    snippet: git status --short --branch
```

`vd` と入力して `Space` を押すと `vde-layout dev` に展開されます。

### 6.4. ghq連携: セッション名自動リネーム

zeno.zsh の ghq-cd 機能を使うと、リポジトリ移動時に tmux セッション名が自動でリポジトリ名に変わります。

```zsh:zinit.zsh
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

複数のプロジェクトを並行して作業する際、セッション名でプロジェクトを識別できるのは非常に便利です。

tmux の設定 → Popup → vde-layout → zeno と、作業環境の自動化を進めてきました。この先にはさらに高度な連携の可能性があります。

## 7. まとめと次の一歩

### 7.1. 本記事のまとめ

本記事では、AI エージェント時代に適した tmux 環境の構築方法を紹介しました。

| 技術       | 役割                                               |
| ---------- | -------------------------------------------------- |
| tmux       | 3層構造でマルチエージェント管理                  |
| tmux.conf  | vi 風操作、prefix 不要バインド、ペインボーダー    |
| Popup      | 一時作業領域の確保                                 |
| vde-layout | YAML でレイアウト一発生成                          |
| zeno.zsh   | スニペットで高速入力                               |
| ghq        | リポジトリ一元管理                                 |

本記事の設定は「凝りすぎない実用設定」です。そのままコピーしても、部分的に取り入れても、すぐに効果を実感できるはずです。

### 7.2. tmux は「プログラマブルなマルチプロセス管理基盤」

tmux は単なるターミナル分割ツールではありません。

本記事で紹介した機能群は、より高度なマルチエージェント管理の基盤となります。

- セッション・ウインドウ・ペインという 3 層構造によるプロセス分離
- `list-panes` や `display-message` によるペイン情報の取得
- `capture-pane` によるペイン出力のキャプチャと監視
- `send-keys` や `set-buffer` + `paste-buffer` による任意ペインへのテキスト送信
- `-t` オプションによる名前/ID ベースのペインターゲティング
- vde-layout などの宣言的レイアウト管理ツール

これらの機能を組み合わせることで、AI エージェントの並行実行を効率的に管理できる基盤が構築できます。

### 7.3. 次の一歩

次回は、この tmux 基盤の上に構築するマルチエージェント連携の仕組みを紹介する予定です。

- 複数エージェントの連携方法
- 作業の分担と統合

今回紹介した tmux 環境は、その基盤となるものです。まずは本記事の設定を試してみて、マルチエージェント開発の土台を整えてみてください。

ぜひお試しください!

### 7.4. 参考リンク

- [tmux 公式 Wiki](https://github.com/tmux/tmux/wiki)
- [vde-layout](https://github.com/yuki-yano/vde-layout)
- [zeno.zsh](https://github.com/yuki-yano/zeno.zsh)
- [yuki-yano 氏の記事「tmux + ghq + fzf + zeno.zsh で快適なターミナル生活を送る」](https://qiita.com/yuki-yano/items/ef5e6b63c8f9af2f03c0)
- [筆者の dotfiles (tmux/vde/zeno 設定)](https://github.com/i9wa4/dotfiles/tree/main/config)
