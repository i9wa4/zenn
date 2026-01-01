---
title: "Zinit の遅延読み込みを活用して Zsh 起動時間を短縮する"
emoji: "🐴"
type: "tech"
topics:
  - "zsh"
  - "zinit"
  - "mise"
published: true
---

## 1. はじめに

Zinit の Turbo モード (遅延読み込み) を活用することで Zsh の起動時間を約 97ms から約 27ms に短縮した方法を紹介します。

## 2. 対象読者

- Zsh ユーザー
- Zinit を使っている、または使いたい方
- 遅延読み込みさせたいプラグイン等を使っている方
    - 今回は mise や zeno.zsh を例にしています

## 3. 環境

- macOS 26.2
- Zsh 5.9
- [Zinit](https://github.com/zdharma-continuum/zinit)
- [mise](https://github.com/jdx/mise)
- [zeno.zsh](https://github.com/yuki-yano/zeno.zsh) ([ghq](https://github.com/x-motemen/ghq), [fzf](https://github.com/junegunn/fzf) を利用するプラグイン)

## 4. 問題の特定

### 4.1. zprof による計測

Zsh の `zprof` モジュールでどの関数がボトルネックになっているかを特定します。

```zsh:~/.zshrc の先頭
zmodload zsh/zprof
```

新しいシェルを起動して `zprof` を実行すると、関数ごとの実行時間が表示されます。

なお `zprof` は関数呼び出しのみを計測するのであくまで参考値です。

```text
num  calls                time                       self            name
-----------------------------------------------------------------------------------
 1)    1          32.09    32.09   83.28%     32.09    32.09   83.28%  _mise_hook
 2)    1           3.28     3.28    8.65%      3.28     3.28    8.65%  compinit
...
```

改善前は `_mise_hook` が計測された関数の中で約 83% を占めていることが分かりました。

### 4.2. hyperfine による計測

Zsh 起動時間全体の計測には hyperfine を使います。

@[card](https://github.com/sharkdp/hyperfine)

```bash
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
```

結果

```text
Time (mean +- o):      97.2 ms +-   1.1 ms    [User: 65.6 ms, System: 45.1 ms]
```

この計測は「プロンプト表示までの時間」です。Turbo モードで遅延読み込みしたプラグインはプロンプト表示後にロードされるため、この計測には含まれません。つまり体感的な起動速度を測っています。

## 5. 解決策

### 5.1. Zinit Turbo モードとは

Zinit には Turbo モードという機能があり、プラグインをプロンプト表示後に遅延読み込みできます。

@[card](https://github.com/zdharma-continuum/zinit)

基本的な使い方は以下の通りです。

```zsh
zinit ice wait lucid
zinit light some-plugin
```

この2行で1セットです。

| コマンド               | 役割                                            |
| ---                    | ---                                             |
| `zinit ice <options>`  | 次の `zinit` コマンドに適用するオプションを設定 |
| `zinit light <plugin>` | プラグインを読み込む                            |

`ice` は「一度使うと溶ける」という意味で、次の1回の `zinit` コマンドにだけ適用されます。

| 修飾子  | 意味                           |
| ---     | ---                            |
| `wait`  | プロンプト表示後に読み込む     |
| `lucid` | 読み込み完了メッセージを非表示 |

### 5.2. 順序制御の問題

私の環境では zeno.zsh というプラグインも使っています。zeno.zsh は ghq や fzf を利用しますが、それらを mise で管理しています。また、compinit[^1] も遅延読み込みすることで起動時間を短縮できます。

つまり、compinit --> mise --> zeno.zsh の順に読み込みたいわけです。

### 5.3. wait のサブスロットによる順序制御

`wait` の数字はプロンプト表示後の待機秒数です。

| 指定      | 意味                       |
| ---       | ---                        |
| `wait'0'` | 0秒後 (プロンプト表示直後) |
| `wait'1'` | 1秒後                      |
| `wait'2'` | 2秒後                      |

さらに Zinit の公式 Wiki[^2] によると、`wait` にはサブスロット (`a`, `b`, `c`) を指定できます。

公式ドキュメントから引用します。

> Plugins from the same time-slot with suffix `a` will be loaded before plugins with suffix `b`, etc.
>
> In other words, instead of `wait'1'` you can enter `wait'1a'`, `wait'1b'` and `wait'1c'` -- to this way impose order on the loadings regardless of the order of `zinit` commands.

| サブスロット | 読み込み順 |
| ---          | ---        |
| `wait'0a'`   | 最初       |
| `wait'0b'`   | 2番目      |
| `wait'0c'`   | 3番目      |

これにより、`.zshrc` での記述順序に関係なく、読み込み順序を制御できます。

### 5.4. 実装

compinit を `wait'0a'`、mise を `wait'0b'`、zeno.zsh を `wait'0c'` で読み込むように設定します。

Zinit 自体のセットアップは公式 README の Manual Install に記載されている方法を使用しています。

@[card](https://github.com/zdharma-continuum/zinit)

```zsh:~/.zshrc
# Zinit (manual install)
# https://github.com/zdharma-continuum/zinit?tab=readme-ov-file#manual
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# compinit (lazy loading via zinit turbo mode)
zinit ice wait'0a' lucid \
  atload'
    autoload -Uz compinit
    compinit
  '
zinit light zdharma-continuum/null

# mise (lazy loading via zinit turbo mode)
zinit ice wait'0b' lucid \
  atload'eval "$(${HOME}/.local/bin/mise activate zsh --quiet)"'
zinit light zdharma-continuum/null

# zeno.zsh (lazy loading via zinit turbo mode)
zinit ice wait'0c' lucid depth"1" blockf \
  atload'
    if [[ -n "${ZENO_LOADED}" ]]; then
      bindkey " "  zeno-auto-snippet
      # ... その他の keybind
    fi
  '
zinit light yuki-yano/zeno.zsh
```

ポイント

- [zdharma-continuum/null](https://github.com/zdharma-continuum/null) は Zinit のフック実行用に用意された空のプラグイン[^3]。compinit や mise 自体はプラグインではないため、`atload` で直接コードを実行するトリガーとして使用
- compinit --> mise --> zeno.zsh の順に読み込まれるので、zeno.zsh が読み込まれる時点で ghq や fzf が PATH に存在する

## 6. 結果

### 6.1. 計測結果

hyperfine で再計測しました。

```bash
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
```

結果

```text
Time (mean +- o):      27.4 ms +-   2.3 ms    [User: 14.0 ms, System: 12.9 ms]
```

### 6.2. 比較

| 方式         | 起動時間 |
| ---          | ---      |
| 直接読み込み | 97.2ms   |
| 遅延読み込み | 27.4ms   |

かなり速くなりました！

## 7. おわりに

Zinit の Turbo モードとサブスロットによる順序制御を活用することで Zsh の起動時間を短縮できました。

私の dotfiles は以下で公開しています。

@[card](https://github.com/i9wa4/dotfiles)

[^1]: Zsh の補完システム初期化。[Zsh compinit の仕組みを理解して起動時間を短縮する](https://zenn.dev/i9wa4/articles/2026-01-01-zsh-startup-optimization-compinit)

[^2]: [Zinit Wiki - Example wait conditions](https://zdharma-continuum.github.io/zinit/wiki/Example-wait-conditions/)

[^3]: [Zinit Wiki - atload and other at ices](https://zdharma-continuum.github.io/zinit/wiki/atload-and-other-at-ices/)
