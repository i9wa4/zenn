---
title: "Databricks on AWS で複数ワークスペースの権限を一元管理する方法"
emoji: "🔐"
type: "tech"
topics:
  - "databricks"
  - "unitycatalog"
  - "dataengineering"
  - "datagovernance"
publication_name: "genda_jp"
published: true
published_at: 2025-12-14 07:00
---

## 1. はじめに

株式会社GENDA データエンジニア / MLOps エンジニアの uma-chan です。
この記事は GENDA Advent Calendar 2025 シリーズ1 Day 14 の記事です。

@[card](https://qiita.com/advent-calendar/2025/genda)

### 1.1. この記事について

Databricks で複数のワークスペースを運用していると権限管理が煩雑になりがちです。
ワークスペースごとにユーザーを追加し、グループを作成し、権限を設定する……これを繰り返すと管理コストが増大し、設定ミスのリスクも高まります。

本記事では Databricks on AWS を利用している前提で、振り返りのために公式ドキュメントの URL と引用を添えつつ、実践的な運用パターンをまとめます。

## 2. 結論：推奨運用パターン

複数ワークスペース環境での権限管理は、以下の運用パターンが有効です。

1. アカウントレベルでグループを定義し、権限を設定する
2. users グループのエンタイトルメントを全て OFF にする
3. ワークスペースへの招待で個別に参加者を管理する

この運用パターンは、Databricks 公式ブログで「Define Once, Secure Everywhere」モデルとして紹介されています。

> "Utilizing the Define Once, Secure Everywhere model, this has the added advantage of avoiding accidental data exposure in scenarios where a user's privileges are inadvertently misrepresented in one workspace."

@[card](https://www.databricks.com/blog/2022/08/26/databricks-workspace-administration-best-practices-for-account-workspace-and-metastore-admins.html)

また、公式ドキュメントでは Consumer access の運用として以下の 3 ステップが推奨されています。

1. Duplicate the workspace's `users` system group
2. Remove higher-privilege entitlements from the `users` group
3. Add new users as consumers

@[card](https://docs.databricks.com/aws/en/ai-bi/consumers/clone-acct-group)

この運用により、以下が実現できます。

- 招待した人だけがワークスペースにアクセスできる
- グループの権限設定は一度定義すれば全ワークスペースに適用される
- 意図しないアクセス権の付与を防げる

以降のセクションでは、なぜこのパターンが有効なのかを公式ドキュメントの引用とともに解説します。

## 3. なぜこのパターンが有効か

### 3.1. users グループのデフォルト問題

Databricks には、全ユーザーが自動的にメンバーになる `users` グループがあります。問題は、このグループにデフォルトで広いアクセス権が付与されていることです。

> "Workspace users are granted Workspace access and Databricks SQL access by default through their membership in the `users` group."

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

つまり、何も設定しないと全員が Workspace access と SQL access を持ってしまいます。

公式ドキュメントでは、これを解決するために以下を推奨しています。

> "To provide the Consumer access experience, you must remove the default entitlements from the `users` group (and the `account users` group, if applicable) and assign entitlements individually to specific users, service principals, or groups."

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

推奨される対応は、`users` グループのエンタイトルメントを全て OFF にし、個別のグループで制御することです。

### 3.2. グループベースの権限管理

公式ドキュメントでは、個人ではなくグループに権限を付与することを推奨しています。

> "It is best practice to assign access to workspaces and access-control policies in Unity Catalog to groups, instead of to users individually."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/best-practices)

> "Avoid direct grants to users whenever possible"

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog/best-practices)

グループベースの管理には以下のメリットがあります。

- メンバーの入れ替わりに柔軟に対応できる
- 監査が容易になる
- 権限設定の一貫性を保てる

### 3.3. アカウントレベルでの一元管理

権限管理の起点は Account Console です。

> "Databricks recommends that you synchronize all of the users and groups in your identity provider to the account console rather than to individual workspaces."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/best-practices)

アカウントレベルでグループを定義することで、一度定義すれば全ワークスペースに適用される（define once, secure everywhere）状態が実現できます。

### 3.4. ワークスペースローカルグループはレガシー

ワークスペースごとにグループを作成する方法は、現在はレガシー扱いです。

> "Workspace-local groups are legacy groups. These groups are identified as having a source of Workspace. You can only use workspace-local groups in the workspace they are defined in. They cannot be assigned to additional workspaces or granted access to data in a Unity Catalog metastore."

@[card](https://docs.databricks.com/aws/en/admin/users-groups/workspace-local-groups)

Unity Catalog で権限を付与するには、アカウントレベルグループを使用する必要があります。

## 4. 具体的な設計パターン

### 4.1. エンタイトルメントの種類

ワークスペースへのアクセス権限は、エンタイトルメントで制御します。

| エンタイトルメント | 利用可能な機能 |
|---|---|
| Workspace access | ノートブック、ジョブ、ML |
| Databricks SQL access | ダッシュボード、クエリ、SQL Warehouse |
| Consumer access | 共有ダッシュボード、Genie |

@[card](https://docs.databricks.com/aws/en/security/auth/entitlements)

### 4.2. グループ設計例

エンタイトルメントに対応したグループ分けの例を示します。

| グループ | 役割 | Workspace | SQL | Consumer |
|---|---|---|---|---|
| engineers | データ基盤構築・開発 | ✓ | ✓ | - |
| analysts | データ分析・レポート | ✓ | ✓ | - |
| business_users | SQL分析・ダッシュボード編集 | - | ✓ | - |
| consumers | ダッシュボード閲覧のみ | - | - | ✓ |

### 4.3. Unity Catalog の権限継承

Unity Catalog では、権限が上位から下位に継承されます。

> "Unity Catalog offers a single place to administer data access policies that apply across all workspaces in a region."

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog)

```text
Catalog（カタログ）
  └─ Schema（スキーマ）
       └─ Table / View（テーブル・ビュー）
```

> "Securable objects in Unity Catalog are hierarchical, and privileges are inherited downward."

@[card](https://docs.databricks.com/aws/en/data-governance/unity-catalog/best-practices)

テーブルからデータを読み取るには、`USE CATALOG` + `USE SCHEMA` + `SELECT` の 3 つが必要です。

### 4.4. グループのネスト（親子関係）

Databricks はネストグループをサポートしています。ネストの深さは最大 10 層までです。

> "Layers of nested groups: 10"

@[card](https://docs.databricks.com/aws/en/resources/limits)

マルチテナント環境では、親グループがグループ会社のデータを参照可能にできます。

## 5. まとめ

複数ワークスペース環境での権限管理は、以下の運用パターンで一元化できます。

```text
1. アカウントレベルでグループを定義し、権限を設定する
2. users グループのエンタイトルメントを全て OFF にする
3. ワークスペースへの招待で個別に参加者を管理する
```

これにより、「一度定義すれば、すべてのワークスペースで適用される」（define once, secure everywhere）権限管理が実現できます。

## 6. 参考リソース

### 6.1. 公式ブログ

- [Databricks Workspace Administration – Best Practices](https://www.databricks.com/blog/2022/08/26/databricks-workspace-administration-best-practices-for-account-workspace-and-metastore-admins.html)

### 6.2. 公式ドキュメント

- [Clone a workspace group to a new account group](https://docs.databricks.com/aws/en/ai-bi/consumers/clone-acct-group)
- [Manage entitlements](https://docs.databricks.com/aws/en/security/auth/entitlements)
- [Identity best practices](https://docs.databricks.com/aws/en/admin/users-groups/best-practices)
- [Unity Catalog](https://docs.databricks.com/aws/en/data-governance/unity-catalog)
- [Unity Catalog best practices](https://docs.databricks.com/aws/en/data-governance/unity-catalog/best-practices)
- [Manage privileges in Unity Catalog](https://docs.databricks.com/aws/en/data-governance/unity-catalog/manage-privileges/)
- [Groups](https://docs.databricks.com/aws/en/admin/users-groups/groups)
- [Resource limits](https://docs.databricks.com/aws/en/resources/limits)
