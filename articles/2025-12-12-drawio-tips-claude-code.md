---
title: "Claude Code に draw.io の図を描かせるコツ"
emoji: "🐴"
type: "tech"
topics:
  - "claudecode"
  - "drawio"
publication_name: "genda_jp"
published: true
published_at: 2025-12-12 07:00
---

:::message
[2025-12-16 追記] 手っ取り早く手元で使いたい方は「6.1. drawio のインストール」を済ませてこちらの記事をチェック！

@[card](https://zenn.dev/genda_jp/articles/2025-12-15-drawio-skills-claude-code)
:::

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ4 Day 12 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

### 1.1. この記事について

Claude Code に draw.io 形式の図を描かせようとすると、意外とハマりポイントが多いです。

- フォントが反映されない
- 矢印がラベルと被る
- テキストが意図しない改行をする

本記事では、私が実際にプレゼン資料の図を Claude Code に描かせる中で学んだコツをまとめます。

### 1.2. なぜ Claude Code に draw.io を描かせるのか

draw.io の GUI で図を作成するのは時間がかかります。一方、Claude Code は XML を直接編集できるため、以下のメリットがあります。

- 自然言語で「こういう図を作って」と指示できる
- 複数要素の一括変更が高速 (例: 全要素のフォントサイズを変更)
- 既存の図をベースに派生図を作成しやすい
- PNG を読み込ませてレイアウトのレビューも依頼できる
- Git でバージョン管理できる (差分が見やすい XML 形式)
- ルールや学びをカスタムスラッシュコマンド・メモリ・Skill・Rules等に記載して「図の描き方」を育てていける

特に最後の点が重要です。draw.io の罠にハマったら、その解決策をルールとして追記していくことで、そのリポジトリ内の図の品質が継続的に向上します。

ただし、Claude Code は draw.io 特有の挙動を知らないため、いくつかの罠にハマりやすいです。

## 2. draw.io の基本構造

draw.io ファイルは XML 形式で記述されます。

```xml
<mxfile host="Electron">
  <diagram name="Page-1" id="xxx">
    <mxGraphModel dx="1200" dy="800" ...>
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- ここに要素を追加 -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

各図形は `mxCell` 要素として表現され、`style` 属性で見た目を制御します。

## 3. フォント設定の罠

### 3.1. defaultFontFamily だけでは不十分

`mxGraphModel` に `defaultFontFamily` を指定しても、PNG 出力時にフォントが反映されないことがあります。

```xml
<!-- これだけでは不十分 -->
<mxGraphModel defaultFontFamily="Noto Sans JP" ...>
```

### 3.2. 各要素に fontFamily を明示する

各テキスト要素の `style` 属性に `fontFamily` を追加する必要があります。

```xml
<!-- 悪い例: fontFamily が未指定 -->
<mxCell id="label" value="テキスト"
  style="text;html=1;fontSize=18;" />

<!-- 良い例: fontFamily を明示 -->
<mxCell id="label" value="テキスト"
  style="text;html=1;fontSize=18;fontFamily=Noto Sans JP;" />
```

:::message
Claude Code に指示する際は「すべてのテキスト要素に `fontFamily=フォント名;` を追加して」と明示すると確実です。
:::

## 4. 矢印の配置テクニック

### 4.1. 矢印は最背面に配置する

draw.io では XML の記述順が描画順になります。矢印を先に記述することで、他の要素の下に表示されます。

```xml
<root>
  <mxCell id="0" />
  <mxCell id="1" parent="0" />

  <!-- 矢印を先に記述 (最背面) -->
  <mxCell id="arrow" style="edgeStyle=..." edge="1" parent="1">
    ...
  </mxCell>

  <!-- ボックスを後に記述 (前面) -->
  <mxCell id="box" style="rounded=1;..." vertex="1" parent="1">
    ...
  </mxCell>
</root>
```

### 4.2. 矢印とラベルの被りを避ける

矢印ラベルは矢印から最低20px以上離す必要があります。

悪い例: ラベルが矢印と被っている

```xml
<!-- Y=220 の矢印に Y=210 のラベル → 被る -->
<mxCell id="arrow" ...>
  <mxGeometry>
    <mxPoint x="280" y="220" as="sourcePoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="label" value="処理" ...>
  <mxGeometry x="310" y="210" width="60" height="20" />
</mxCell>
```

良い例: ラベルを矢印の上に配置

```xml
<!-- Y=220 の矢印に Y=180 のラベル → 40px離れている -->
<mxCell id="arrow" ...>
  <mxGeometry>
    <mxPoint x="280" y="220" as="sourcePoint"/>
  </mxGeometry>
</mxCell>
<mxCell id="label" value="処理" ...>
  <mxGeometry x="310" y="180" width="60" height="20" />
</mxCell>
```

### 4.3. テキスト要素への矢印接続

テキスト要素に矢印を接続する場合、`exitY` や `entryY` が期待通りに動作しないことがあります。

```xml
<!-- 悪い例: exitY/entryY が効かない場合がある -->
<mxCell id="arrow" source="label1" target="label2"
  style="exitX=0.5;exitY=1;entryX=0.5;entryY=0;" />

<!-- 良い例: 明示的に座標を指定 -->
<mxCell id="arrow" style="..." edge="1" parent="1">
  <mxGeometry relative="1" as="geometry">
    <mxPoint x="190" y="300" as="sourcePoint"/>
    <mxPoint x="490" y="300" as="targetPoint"/>
  </mxGeometry>
</mxCell>
```

## 5. テキスト要素のサイズ設定

### 5.1. フォントサイズは1.5倍を推奨

PDF やスライドで表示する場合、標準のフォントサイズでは小さすぎて読みづらいことがあります。

```xml
<!-- 悪い例: デフォルトサイズ (12px) では小さい -->
<mxCell id="label" value="テキスト"
  style="text;html=1;fontSize=12;fontFamily=Noto Sans JP;" />

<!-- 良い例: 1.5倍 (18px) で読みやすく -->
<mxCell id="label" value="テキスト"
  style="text;html=1;fontSize=18;fontFamily=Noto Sans JP;" />
```

:::message alert
フォントサイズを変更すると、テキストがボックスからはみ出したり、レイアウトが崩れたりします。サイズ変更後は必ず PNG で確認し、`mxGeometry` の調整が必要です。
:::

### 5.2. 日本語テキストの幅を十分に確保する

日本語テキストは英語より幅を取ります。width を十分に確保しないと意図しない改行が発生します。

```xml
<!-- 悪い例: 幅が狭すぎて改行される -->
<mxCell id="title" value="シンプルなフロー図" ...>
  <mxGeometry x="240" y="60" width="200" height="40" />
</mxCell>

<!-- 良い例: 十分な幅を確保 -->
<mxCell id="title" value="シンプルなフロー図" ...>
  <mxGeometry x="140" y="60" width="400" height="40" />
</mxCell>
```

:::message
目安として、日本語1文字あたり約30-40px を確保すると安全です。
:::

## 6. PNG 変換と視覚確認

### 6.1. draw.io のインストール

PNG 変換には draw.io が必要です。

macOS の場合

```sh
brew install --cask drawio
```

macOS 以外の場合は [公式リリースページ](https://github.com/jgraph/drawio-desktop/releases) からダウンロードしてください。

### 6.2. pre-commit hook で自動変換

手動で毎回 PNG 変換するのは面倒です。pre-commit hook を使えば、コミット時に自動で PNG を生成できます。

`.pre-commit-config.yaml` の設定例

```yaml
repos:
  - repo: local
    hooks:
      - id: convert-drawio-to-png
        name: Convert draw.io to PNG
        entry: bash .github/scripts/convert-drawio-to-png.sh
        language: system
        files: \.drawio$
        pass_filenames: true
```

変換スクリプト `.github/scripts/convert-drawio-to-png.sh`

```sh
#!/bin/bash
set -e

# drawio コマンドの存在確認
if ! command -v drawio &> /dev/null; then
  echo "Error: drawio CLI is not installed."
  exit 1
fi

for drawio in "$@"; do
  png="${drawio}.png"
  drawio -x -f png -s 2 -t -o "$png" "$drawio" 2>/dev/null
  git add "$png"
done
```

これにより、`.drawio` ファイルを編集してコミットすると、自動的に `.drawio.png` が生成されてステージングされます。

### 6.3. drawio CLI のオプション

```sh
drawio -x -f png -s 2 -t -o output.drawio.png input.drawio
```

| オプション | 説明 |
|-----------|------|
| `-x` | エクスポートモード |
| `-f png` | PNG フォーマットで出力 |
| `-s 2` | 2倍スケール (高解像度) |
| `-t` | 透明背景 |
| `-o` | 出力ファイルパス |

### 6.4. 必ず PNG で確認する

draw.io アプリでの見た目と PNG 出力の見た目が異なることがあります。

Claude Code に図を描かせたら、以下のフローで確認します。

1. drawio CLI で PNG を生成
2. PNG を目視で確認 (画像ビューアで開く)
3. Claude Code に PNG を読み込ませてレビューを依頼
4. 問題があれば修正を依頼
5. 1-4 を繰り返す

```sh
# 変換
drawio -x -f png -s 2 -t -o /tmp/review.png my-diagram.drawio

# PNG を開いて目視確認
open /tmp/review.png  # macOS の場合
```

Claude Code に PNG を読み込ませるには、Read ツールで画像ファイルを直接指定します。「この図のレイアウトに問題はないか確認して」と依頼すると、テキストの被りやレイアウトのズレを指摘してくれます。

## 7. ベストプラクティスまとめ

### 7.1. Claude Code への指示テンプレート

以下のような指示を出すと、品質の高い図が得られやすいです。

```text
draw.io で図を作成してください。以下のルールに従ってください。

- mxGraphModel に defaultFontFamily="フォント名" を設定
- すべてのテキスト要素の style に fontFamily=フォント名; を追加
- フォントサイズは標準の1.5倍 (18px程度) を使用
- 矢印は XML の先頭に配置 (最背面)
- 矢印とラベルは 20px 以上離す
- 日本語テキストの width は十分に確保 (1文字あたり 30-40px)
- 背景色は設定しない (透明)
- page="0" を設定
```

### 7.2. チェックリスト

結構みなさん心当たりがあると思うのですがチェックリストを作らせないと作業漏れが発生しがちなので、学びを活かしてチェックリストを守らせると良いです。

Claude Code に図を描かせた後の確認項目

- [ ] 全テキスト要素に fontFamily が設定されているか
- [ ] フォントサイズは十分か (18px 以上推奨)
- [ ] 矢印が最背面に配置されているか
- [ ] 矢印とラベルが被っていないか
- [ ] 日本語テキストが意図しない改行をしていないか
- [ ] PNG で視覚確認したか

## 8. おわりに

Claude Code は draw.io の XML を直接編集できるため、図の作成や修正を高速に行えます。
ただし、いくつかの罠があるため、本記事で紹介したコツを押さえておくと作業がスムーズになります。

特に重要なのは以下の3点です。

1. fontFamily は各テキスト要素に明示する
2. 矢印は最背面に配置し、ラベルとの被りを避ける
3. 必ず PNG で視覚確認する

Claude Code と draw.io の組み合わせで効率的な図の作成を試してみてください。

## 9. 参考リンク

- [draw.io (diagrams.net)](https://www.drawio.com/)
- [draw.io Desktop Releases (CLI を含む)](https://github.com/jgraph/drawio-desktop/releases)
- [Claude Code Documentation](https://code.claude.com/docs)
- [pre-commit](https://pre-commit.com/)
