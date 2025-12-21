---
title: "Notion データベースでリレーション元のプロパティを表示する (2025年3月28日時点)"
emoji: "🐴"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - "notion"
published: true
publication_name: "genda_jp"
---

## 1. はじめに

こんにちは。株式会社GENDAの MLOps エンジニア/データエンジニアの uma-chan です。

下図のように Notion データベースでリレーションプロパティ (列) にはリレーション元のプロパティも併せて表示させると便利ですよね。

![](/images/2025-03-28-display-notion-relation-property-as-section/goal.png)
*リレーションプロパティの表示設定成功例*

タイトル記載日時点で公式ドキュメントに記載された通りに設定ができなかったので手順を共有します。

一応以下が公式ドキュメントです。

@[card](https://www.notion.com/ja/help/relations-and-rollups#リレーションの表示オプション)

## 2. リレーションプロパティの表示設定

最も混乱しづらいであろう手順を以下に示します。

### 2.1. 利用するデータベースの説明

#### 2.1.1. item_master

リレーション元として利用します。

![](/images/2025-03-28-display-notion-relation-property-as-section/item_master.png)

#### 2.1.2. transaction_a

item_master をプロパティに追加させたいデータベースです。

![](/images/2025-03-28-display-notion-relation-property-as-section/transaction_a.png)

### 2.2. リレーションプロパティの追加

データベース全体の設定を行うのではなく、1アイテムを編集→全体適用でいきます。

1. transaction_a の1アイテムをサイドピークで開く
1. 右上の「…」→「レイアウトをカスタマイズ」とクリックする
    ![](/images/2025-03-28-display-notion-relation-property-as-section/01-customize-layout.png)
1. 「＋」をクリックする
    ![](/images/2025-03-28-display-notion-relation-property-as-section/02-click-plus.png)
1. リレーションプロパティを選択する
    ![](/images/2025-03-28-display-notion-relation-property-as-section/03-add-relation.png)
1. リレーション元として item_master を選択する
    ![](/images/2025-03-28-display-notion-relation-property-as-section/04-add-item-master.png)
1. リレーションを追加する
    ![](/images/2025-03-28-display-notion-relation-property-as-section/05-add-relation.png)
1. すべてのページに適用する
    ![](/images/2025-03-28-display-notion-relation-property-as-section/06-apply.png)
1. リレーションプロパティの「…」から表示させたいプロパティを選択する
    ![](/images/2025-03-28-display-notion-relation-property-as-section/07-set-property.png)
1. 完了
    ![](/images/2025-03-28-display-notion-relation-property-as-section/goal.png)
