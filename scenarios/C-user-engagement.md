# Scenario C: User Engagement Tracking

既存の `hub_user` に新しい Satellite を追加し、CS チーム向けのヘルススコアマートを構築するシナリオ。  
既存 Hub への Satellite 追加と、完全新規テーブルの両方が含まれる。

---

## ① Requirements — `/modscape:spec:requirements`

**ユーザーのプロンプト例:**

```
/modscape:spec:requirements

CS チームから「解約しそうなアカウントを事前に特定したい」という要件が来ています。
アプリ側でユーザーのアクティビティログ (app.user_events) が取得できるようになりました。

ゴール:
- ユーザーのログイン頻度・機能使用状況をモデルに取り込む
- アカウントのヘルススコア (0-100) を計算して CS が確認できるようにする
- 既存の cs_report コンシューマーにデータを供給する

ステークホルダー: CS チーム（主）、カスタマーサクセスマネージャー
データソース: app.user_events (新規) — event_type, occurred_at, user_id
```

**AI の動作:**
- フォルダ名 `user-engagement` を提案
- ユーザーが承認後、`.modscape/changes/user-engagement/spec.md` を生成

**生成される `spec.md` のイメージ:**

```markdown
# Spec: user-engagement

## Goal
ユーザーのアクティビティデータをモデルに追加し、CS チームが解約リスクの高い
アカウントを事前に特定できるヘルススコアを提供する。

## Stakeholders
- CS チーム（主）— at-risk アカウントの週次モニタリング
- カスタマーサクセスマネージャー — 担当顧客のヘルス確認

## Data Sources
- `app.user_events` (新規) — event_type, occurred_at, user_id
  - event_type: login, feature_used, export, invite_sent, etc.

## Acceptance Criteria
- [ ] sat_user_activity に直近 30 日のログイン数・機能使用スコアが保存される
- [ ] dim_users にヘルススコアと最終アクティブ日が追加される
- [ ] mart_engagement_health で月次のヘルス tier 分類が取得できる
- [ ] cs_report コンシューマーが mart_engagement_health から供給される

## Target Tool
dbt (Snowflake)
```

---

## ② Design — `/modscape:spec:design user-engagement`

**ユーザーのプロンプト例:**

```
/modscape:spec:design user-engagement
```

**AI の動作:**
1. `spec.md` を読み込み、`hub_user` と `dim_users` が影響テーブルと判定
2. `modscape extract modscape.yaml --tables hub_user,dim_users` を実行
3. 新テーブル `sat_user_activity`、`mart_engagement_health` を `spec-model.yaml` に追加
4. `cs_report` consumer との lineage を追加
5. `design.md` と `tasks.md` を生成

**生成される `design.md` のイメージ:**

```markdown
# Design: user-engagement

## 変更対象テーブル

| テーブル | 種別 | 変更内容 |
|---|---|---|
| hub_user | 既存参照 | 変更なし（関係定義のみ） |
| sat_user_activity | 新規追加 | hub_user への新 Satellite |
| dim_users | 既存変更 | health_score, last_active_date カラム追加 |
| mart_engagement_health | 新規追加 | ヘルス tier 別月次集計マート |

## 設計判断

### スナップショット vs イベント
`sat_user_activity` は **日次スナップショット**方式を採用。
`load_dts` = スナップショット取得日。

> **理由**: CS チームは「今日時点のヘルス」が知りたい。
> イベント積み上げより日次集計の方がクエリが単純で再現性が高い。

### ヘルススコアの計算式
```
health_score = (login_score × 0.4) + (feature_score × 0.4) + (recency_score × 0.2)

login_score    = LEAST(login_count_30d / 20, 1) × 100   # 月20回以上で満点
feature_score  = feature_usage_score                     # アプリ側で算出済み (0-100)
recency_score  = CASE WHEN days_since_last_active <= 7 THEN 100
                      WHEN days_since_last_active <= 14 THEN 70
                      WHEN days_since_last_active <= 30 THEN 40
                      ELSE 0 END
```

### ヘルス tier の閾値
| Tier | 条件 |
|---|---|
| healthy | health_score >= 70 |
| at_risk | 40 <= health_score < 70 |
| critical | health_score < 40 |

### dim_users へのデンorマライズ
`dim_users` に `health_score` と `last_active_date` を追加することで、
CS がサブスクリプション情報とヘルス情報を1テーブルで参照できる。

## Requires Model Change
<!-- 実装中に発見した場合はここに追記して /modscape:spec:design を再実行 -->
```

**生成される `tasks.md` のイメージ:**

```markdown
# Tasks: user-engagement

## Model Changes
- [ ] sat_user_activity テーブルを新規作成（hub_user の Satellite）
- [ ] dim_users に health_score (Decimal), last_active_date (Date) カラムを追加
- [ ] mart_engagement_health テーブルを新規作成
- [ ] cs_report への lineage を mart_engagement_health から追加

## dbt Implementation
- [ ] `stg_app__user_events.sql` を新規作成（app.user_events のステージング）
- [ ] `sat_user_activity.sql` を新規作成（日次スナップショット集計）
- [ ] `dim_users.sql` にヘルススコアと最終アクティブ日の結合を追加
- [ ] `mart_engagement_health.sql` を新規作成

## Tests
- [ ] health_score が 0-100 の範囲内であることを確認
- [ ] health_tier が healthy | at_risk | critical のみであることを確認
- [ ] sat_user_activity の user_hk が hub_user に存在することを確認
- [ ] mart_engagement_health の月次行数が前月比 ±20% 以内であることを確認
```

---

## ③ Implement — `/modscape:spec:implement user-engagement`

**ユーザーのプロンプト例:**

```
/modscape:spec:implement user-engagement
```

**AI のタスク処理例:**

```
Task 1/8: stg_app__user_events.sql を新規作成

spec-model.yaml の sat_user_activity を確認しました。
ソース: app.user_events

-- models/staging/stg_app__user_events.sql
SELECT
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} AS user_hk,
    user_id,
    event_type,
    CAST(occurred_at AS TIMESTAMP)                      AS occurred_at,
    CURRENT_TIMESTAMP()                                 AS load_dts
FROM {{ source('app', 'user_events') }}

tasks.md の [ ] を [x] に更新しました。
次のタスクに進みますか？ (y/n)
```

```
Task 3/8: sat_user_activity.sql を新規作成

日次スナップショット方式で実装します。

-- models/vault/sat_user_activity.sql
WITH activity AS (
    SELECT
        user_hk,
        CURRENT_DATE()                                AS snapshot_date,
        COUNT_IF(event_type = 'login')                AS login_count_30d,
        COUNT_IF(event_type = 'feature_used') / 10.0  AS feature_usage_score,
        MAX(occurred_at::DATE)                        AS last_active_date,
        COUNT(DISTINCT occurred_at::DATE)             AS pages_viewed_30d
    FROM {{ ref('stg_app__user_events') }}
    WHERE occurred_at >= DATEADD(day, -30, CURRENT_DATE())
    GROUP BY user_hk
)
SELECT
    user_hk,
    snapshot_date                             AS load_dts,
    {{ dbt_utils.generate_surrogate_key([
        'login_count_30d',
        'feature_usage_score',
        'last_active_date'
    ]) }}                                     AS hash_diff,
    login_count_30d,
    LEAST(feature_usage_score, 100)           AS feature_usage_score,
    last_active_date,
    pages_viewed_30d
FROM activity

tasks.md の [ ] を [x] に更新しました。
次のタスクに進みますか？ (y/n)
```

**実装中に発見があった場合の再設計フロー:**

```
app.user_events を確認したところ、bot アカウント
(user_id LIKE 'bot-%') が大量に含まれていることがわかりました。
スコアの歪みを防ぐため除外が必要です。

design.md の ### Requires Model Change に追記して
/modscape:spec:design user-engagement を再実行してください:

### Requires Model Change
- stg_app__user_events で user_id LIKE 'bot-%' を除外する
- sat_user_activity に is_bot_excluded フラグを追加
```

---

## ④ Archive — `/modscape:spec:archive user-engagement`

**ユーザーのプロンプト例:**

```
/modscape:spec:archive user-engagement
```

**AI の動作:**

```
modscape merge modscape.yaml changes/user-engagement/spec-model.yaml --patch を実行

以下のテーブルを modscape.yaml に反映します:
  ✅ hub_user — 変更なし（参照のみ）
  ✅ sat_user_activity — 新規追加（hub_user の Satellite）
  ✅ dim_users — 2 カラム追加 (health_score, last_active_date)
  ✅ mart_engagement_health — 新規追加

lineage を更新します:
  ✅ sat_user_activity → dim_users
  ✅ mart_engagement_health → cs_report

以下の specs/*.md を生成します:
  📄 .modscape/specs/sat_user_activity.md (新規)
  📄 .modscape/specs/dim_users.md (更新)
  📄 .modscape/specs/mart_engagement_health.md (新規)
  📄 .modscape/specs/hub_user.md (更新 — Changelog のみ)

changes/user-engagement/ を archives/2024-03-15-user-engagement/ へ移動しますか？ (y/n)
```
