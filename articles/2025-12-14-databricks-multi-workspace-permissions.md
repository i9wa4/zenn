---
title: "Databricks 公式ドキュメントを読んで権限設計を理解する"
emoji: "🔐"
type: "tech"
topics:
  - "databricks"
publication_name: "genda_jp"
published: true
published_at: 2025-12-14 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ1 Day 14 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

ならびに Databricks Advent Calendar 2025 シリーズ2 Day 14 の記事です。

@[card](https://qiita.com/advent-calendar/2025/databricks)

### 1.1. この記事について

最近 Databricks の権限設計を見直す機会がありました。
せっかくなので公式ドキュメントを読み返して正しい理解を深めておこうと思い、基本的な部分を調査した内容をまとめます。
Databricks on AWS のドキュメントを参照しています。

## 2. グループに関する基本知識

### 2.1. グループベースの権限管理

個人ではなくグループに権限を付与することを推奨しています。

> "It is best practice to assign access to workspaces and access-control policies in Unity Catalog to groups, instead of to users individually."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/best-practices)

> "Avoid direct grants to users whenever possible"

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog/best-practices)

### 2.2. グループは自動的にアカウントレベルで作成される

ワークスペース管理者がグループを作成すると、自動的にアカウントレベルで追加されます。

> "Workspace admins can also add a new user, service principal, or group directly to a workspace. This action automatically adds the identity to the account and assigns it to that workspace."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/groups)

「Define Once, Secure Everywhere」ということらしいですが、ワークスペース内で作ったグループのつもりがアカウントレベルで作成されるということになるので意識しておく必要があります。

> "Utilizing the Define Once, Secure Everywhere model, this has the added advantage of avoiding accidental data exposure in scenarios where a user's privileges are inadvertently misrepresented in one workspace."

@[card](https://www.databricks.com/blog/2022/08/26/databricks-workspace-administration-best-practices-for-account-workspace-and-metastore-admins.html)

### 2.3. ワークスペースローカルグループはレガシー

ワークスペースローカルグループはレガシー扱いです。
今回調べていて初めて存在を知りました（この頃の Databricks 環境をちゃんと触れていない……）。

> "Workspace-local groups are legacy groups. These groups are identified as having a source of Workspace. You can only use workspace-local groups in the workspace they are defined in. They cannot be assigned to additional workspaces or granted access to data in a Unity Catalog metastore."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/workspace-local-groups)

## 3. 権限設計の基礎知識

### 3.1. エンタイトルメントの種類

ワークスペースへのアクセス権限は、エンタイトルメント（＝機能利用権限）で制御します。

Consumer access、SQL access、Workspace access の3種類があって、ユーザーが Databricks のどの機能を利用できるかを決めます。

| 機能                                              | Consumer | SQL | Workspace |
| ---                                               | ---      | --- | ---       |
| 共有ダッシュボード、Genie、Databricks Apps        | ✓        | ✓   | ✓         |
| BI ツールから SQL Warehouse にクエリ              | ✓        | ✓   | -         |
| Databricks SQL オブジェクトの読み書き             | -        | ✓   | -         |
| Data Science & Engineering オブジェクトの読み書き | -        | -   | ✓         |
| Databricks Mosaic AI オブジェクトの読み書き       | -        | -   | ✓         |

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

### 3.2. Unity Catalog の権限継承

Unity Catalog では、権限が上位から下位に継承されます。
油断すると意図しない権限付与になることがあるので注意が必要です。

> "Unity Catalog offers a single place to administer data access policies that apply across all workspaces in a region."

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog)

```text
Catalog（カタログ）
  └─ Schema（スキーマ）
       └─ Table / View（テーブル・ビュー）
```

> "Securable objects in Unity Catalog are hierarchical, and privileges are inherited downward."

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog/best-practices)

テーブルからデータを読み取るには、`USE CATALOG` + `USE SCHEMA` + `SELECT` と付与されている必要があります。

> "to select data from a table, users need to have the SELECT privilege on that table and USE CATALOG privileges on its parent catalog as well as USE SCHEMA privileges on its parent schema."

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog/manage-privileges/privileges)

### 3.3. グループのネスト

Databricks はネストグループをサポートしています。ネストの深さは最大10層までです。

> "Layers of nested groups: 10"

@[card](https://docs.databricks.com/aws/en/resources/limits)

## 4. users グループと Consumer access

### 4.1. users グループのデフォルト問題

Databricks には全ユーザーが自動的にメンバーになる `users` グループがあります。
デフォルトで広いアクセス権が付与されているので権限設計時には調整が必要です。
何も設定しないと全員が Workspace access と SQL access を持ってしまいます。

> "Workspace users are granted Workspace access and Databricks SQL access by default through their membership in the `users` group."

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

### 4.2. Consumer access の活用

Databricks の Consumer access はダッシュボードが閲覧できる最小限の権限セットでビジネスユーザー向けです。
Databricks One というUI制限版を利用するための権限として最近追加されていて、権限的に手頃で助かってます。

@[card](https://docs.databricks.com/aws/en/ai-bi/consumers/)

先程の話と重複してきますが Consumer access を活用するには、`users` グループの設定を見直す必要があります。

> "To provide the Consumer access experience, you must remove the default entitlements from the `users` group (and the `account users` group, if applicable) and assign entitlements individually to specific users, service principals, or groups."

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

`users` グループのエンタイトルメントを全て OFF にし、個別のグループで制御することで、ユーザーごとに適切なアクセスレベルを設定できます。

## 5. おわりに

Databricks ワークスペースにおける権限管理について公式ドキュメントの内容をまとめました。
ごく基本的な内容ですがこれらを応用することで複数ワークスペースでの権限管理に立ち向かえるようになるのでやっぱり基本は大事です！
実験的に知ってたことが結構多かったので知識的な裏付けができてよかったです。
