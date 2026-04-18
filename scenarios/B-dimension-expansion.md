# Scenario B: Dimension Expansion — Multi-Dimensional Revenue Analytics

シナリオ A で構築した ARR パイプラインに **顧客ディメンション** と **プランディメンション** を追加し、
`mart_arr` を複数の分析軸を持つ `mart_revenue_summary` へ進化させるシナリオ。

**ポイント：**
- 新規ディメンション追加（`dim_customers`、`dim_plans`）
- 既存ファクト改修（`fct_subscription_events` に FK を追加）
- 既存マート進化（`mart_arr` → `mart_revenue_summary` へ拡張）
- シナリオ A で未解決だった `country_code`（Q-003）をここで解決

---

## 前提：追加されるソースデータ

```
data/02_raw__customers.csv    ← 顧客マスタ（country_code、セグメントなど）
data/03_raw__plans.csv        ← プランマスタ（ティア、カテゴリ、価格帯など）
```

---

## ① Requirements — `/modscape:spec:requirements`

**ユーザーのプロンプト例:**

```
/modscape:spec:requirements

BI チームから、ARR/MRR を複数の軸でスライスしたいという要件が来ました。
現在の mart_arr は plan × year でしか見られないため、以下を追加したい：

- 顧客の国・セグメント（SMB / Mid-Market / Enterprise）別に ARR を分析したい
- プランのティア（Starter / Pro / Enterprise）・カテゴリ別に MRR を分析したい

そのために顧客マスタ（raw_customers.csv）とプランマスタ（raw_plans.csv）が
新たにデータソースとして利用可能になりました。

シナリオ A で country_code が NULL になっていた問題もここで解決したい。

ゴール:
- 顧客ディメンション（dim_customers）を新規追加
- プランディメンション（dim_plans）を新規追加
- fct_subscription_events から両ディメンションを参照できるようにする
- mart_revenue_summary で ARR/MRR を多軸で集計できるようにする

ステークホルダー: BI チーム、Finance チーム
```

**AI の動作:**
- フォルダ名 `dimension-expansion` を提案
- ユーザーが承認後、`.modscape/changes/dimension-expansion/spec.md` を生成
- Q-003（country_code）が解決済みであることを `_context.yaml` から検出し、関連 AC として取り込む

**生成される `spec.md` のイメージ:**

```markdown
# Pipeline Spec: Dimension Expansion — Multi-Dimensional Revenue Analytics

## Goal
顧客ディメンションとプランディメンションを追加し、ARR/MRR を国・セグメント・
プランティアなど複数の軸でスライスできるようにする。
シナリオ A で未解決だった country_code（Q-003）もここで解決する。

## Stakeholders
- owner: BI チーム
- consumers: [Finance チーム, revenue_dashboard]

## Data Sources
- `raw_customers.csv` — 顧客マスタ（country_code, segment, industry など）
- `raw_plans.csv` — プランマスタ（tier, category, base_price_usd など）
- `fct_subscription_events` — 既存ファクト（FK 追加対象）
- `mart_arr` — 既存マート（`mart_revenue_summary` へ進化）

## Acceptance Criteria
- [ ] AC-001: dim_customers に country_code と customer_segment が保存される
- [ ] AC-002: dim_plans に plan_tier と plan_category が保存される
- [ ] AC-003: fct_subscription_events から dim_customers・dim_plans を JOIN できる
- [ ] AC-004: mart_revenue_summary で country × segment × plan_tier 別に ARR/MRR が集計できる
- [ ] AC-005: country_code が NULL だった既存レコードが dim_customers の値で補完される

## Target Tool
SQLite + SQL（出力は CSV ファイル）

## Status
requirements
```

---

## ② Design — `/modscape:spec:design dimension-expansion`

**ユーザーのプロンプト例:**

```
/modscape:spec:design dimension-expansion
```

**AI の動作:**
1. `spec.md` と `specs/*.md`、`specs/_context.yaml` を読み込み
2. `modscape extract main-model.yaml --tables fct_subscription_events,mart_arr --with-downstream` を実行
3. 抽出したテーブルを `spec-model.yaml` に配置
4. 新テーブル `stg_customers`、`stg_plans`、`dim_customers`、`dim_plans`、`mart_revenue_summary` を追加
5. `design.md` と `tasks.md` を生成

**Affected Tables の分類:**

```markdown
### Direct Impact
- `dim_customers`: 新規作成 — 顧客マスタディメンション（AC-001、Q-003 の解決）
- `dim_plans`: 新規作成 — プランマスタディメンション（AC-002）
- `fct_subscription_events`: 既存改修 — customer_hk・plan_hk の FK カラムを追加（AC-003）
- `mart_revenue_summary`: 新規作成 — 多軸 ARR/MRR 集計マート（AC-004）

### Downstream Impact — Implement
- （該当なし — mart_arr は mart_revenue_summary に置き換え）

### Downstream Impact — Context Only
- `mart_arr`: mart_revenue_summary の前身。既存 CSV はそのまま残す（後方互換）
- `dim_subscriptions`: country_code を dim_customers から補完するよう更新
```

**設計のポイントと design.md のイメージ:**

```markdown
# Design: dimension-expansion

## Design Decisions

### スタースキーマ構成
fct_subscription_events を中心に dim_customers・dim_plans・dim_subscriptions の
3ディメンションが接続するスタースキーマを採用。

### country_code の解決（Q-003）
dim_customers.country_code を正典として使用。
fct_subscription_events は customer_id を通じて国情報を取得する。
dim_subscriptions の NULL だった country_code は dim_customers から補完する。

### mart_revenue_summary のグレイン
`year_key × month_key × plan_tier × country_code × customer_segment`
ARR（annual のみ）と MRR（全プラン）を同一マートで提供する。

### mart_arr との共存
mart_arr は後方互換のため削除しない。
mart_revenue_summary が上位互換として機能する。
```

**設計されるリネージ:**

```
02_raw__customers.csv
  └─► stg_customers
        └─► dim_customers   （country_code、segment）
              │
03_raw__plans.csv            │
  └─► stg_plans              │
        └─► dim_plans        │   （tier、category）
              │              │
              ▼              ▼
         fct_subscription_events  ←── dim_subscriptions（既存）
              │
              ▼
        mart_revenue_summary   （ARR/MRR × 多軸集計）
              │
              ▼
        revenue_dashboard
```

---

## ③ Implement — `/modscape:spec:implement dimension-expansion`

**ユーザーのプロンプト例:**

```
/modscape:spec:implement dimension-expansion
```

**AI のタスク処理例（Phase 1 → 2 → 3 → 4）:**

```
Task 1/8: stg_customers を作成

raw_customers.csv を読み込み、型変換・NULL チェックを適用します。

-- sql/stg_customers.sql
CREATE TABLE IF NOT EXISTS stg_customers AS
SELECT
    customer_id,
    customer_name,
    country_code,
    customer_segment,   -- SMB | Mid-Market | Enterprise
    industry,
    created_at,
    CURRENT_TIMESTAMP AS loaded_at
FROM raw_customers;

tasks.md の [ ] を [x] に更新しました。次のタスクに進みますか？ (y/n)
```

```
Task 4/8: fct_subscription_events に customer_hk・plan_hk を追加

既存テーブルに FK カラムを追加するため、DROP & RECREATE で対応します。

-- sql/fct_subscription_events.sql（抜粋）
LEFT JOIN dim_customers  ON stg.customer_id  = dim_customers.customer_id
LEFT JOIN dim_plans      ON stg.plan_id      = dim_plans.plan_id

追加カラム:
  country_code      (dim_customers から補完 — AC-005)
  customer_segment  (dim_customers から)
  plan_tier         (dim_plans から)
  plan_category     (dim_plans から)

tasks.md の [ ] を [x] に更新しました。次のタスクに進みますか？ (y/n)
```

```
Task 6/8: mart_revenue_summary を作成

fct + 3ディメンションを JOIN して多軸集計マートを生成します。

-- sql/mart_revenue_summary.sql
SELECT
    STRFTIME('%Y', event_date)  AS year_key,
    STRFTIME('%Y-%m', event_date) AS month_key,
    plan_tier,
    plan_category,
    country_code,
    customer_segment,
    COUNT(DISTINCT subscription_id) AS active_subscriptions,
    ROUND(SUM(mrr_amount), 2)    AS total_mrr_usd,
    ROUND(SUM(arr_amount), 2)    AS total_arr_usd
FROM fct_subscription_events
WHERE event_type IN ('new_subscription', 'trial_conversion')
GROUP BY year_key, month_key, plan_tier, plan_category, country_code, customer_segment;
```

---

## ④ Archive — `/modscape:spec:archive dimension-expansion`

**ユーザーのプロンプト例:**

```
/modscape:spec:archive dimension-expansion
```

**AI の動作:**

```
main-model.yaml に以下を反映します:
  ✅ stg_customers       — 新規追加
  ✅ stg_plans           — 新規追加
  ✅ dim_customers       — 新規追加
  ✅ dim_plans           — 新規追加
  ✅ fct_subscription_events — 既存更新（+4 カラム: country_code, customer_segment, plan_tier, plan_category）
  ✅ mart_revenue_summary — 新規追加
  ⏭ mart_arr             — Context Only（変更なし）

以下の specs/ を生成・更新します:
  📄 specs/dim_customers/spec.md        (新規)
  📄 specs/dim_plans/spec.md            (新規)
  📄 specs/mart_revenue_summary/spec.md (新規)
  📝 specs/fct_subscription_events/spec.md (更新 — Changelog + Business Rules)
  📝 specs/dim_subscriptions/spec.md    (更新 — country_code の Known Issues を解決済みに)
  📝 specs/mart_arr/spec.md             (Changelog のみ)

_context.yaml を更新します:
  D-003 (country_code) を "resolved by dimension-expansion" としてクローズ

changes/dimension-expansion/ を archives/YYYY-MM-DD-dimension-expansion/ へ移動します。
```

---

## このシナリオで示せる SDD のパターン

| パターン | 該当箇所 |
|---|---|
| **新規ディメンション追加** | `dim_customers`、`dim_plans` の新規作成 |
| **既存ファクト改修** | `fct_subscription_events` への FK カラム追加 |
| **既存マートの進化** | `mart_arr` → `mart_revenue_summary` |
| **過去の未解決事項の解消** | `_context.yaml` の D-003（country_code）をクローズ |
| **Context Only の活用** | `mart_arr` を壊さず後方互換を保ちながら進化 |
| **specs の差分更新** | 既存 spec.md の Changelog / Known Issues を更新 |
