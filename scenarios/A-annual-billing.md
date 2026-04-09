# Scenario A: Annual Billing Support

既存の月次課金モデルに年次課金プランを追加するシナリオ。  
`sat_subscription_status` の変更と `mart_arr` の新規追加が含まれる。

---

## ① Requirements — `/modscape:spec:requirements`

**ユーザーのプロンプト例:**

```
/modscape:spec:requirements

Finance チームから年次請求プランの分析要件が来ました。
Stripe 側の実装が完了して billing.subscriptions に billing_cycle (monthly|annual) と
annual_price_usd カラムが追加されました。

ゴール:
- 年次/月次の請求サイクルをモデルに取り込む
- ARR (Annual Recurring Revenue) を MRR とは別に計算できるようにする
- Revenue Dashboard で ARR トレンドを表示できるようにする

ステークホルダー: Finance チーム、経営ダッシュボード担当
```

**AI の動作:**
- フォルダ名 `annual-billing` を提案
- ユーザーが承認後、`.modscape/changes/annual-billing/spec.md` を生成

**生成される `spec.md` のイメージ:**

```markdown
# Spec: annual-billing

## Goal
年次請求サイクルのサポートを追加する。Finance チームが ARR を MRR と並列で
追跡できるようにし、Revenue Dashboard での表示を可能にする。

## Stakeholders
- Finance チーム（主）— Revenue Dashboard での ARR 確認
- 経営チーム — ARR を成長指標として利用

## Data Sources
- `billing.subscriptions` — billing_cycle (monthly|annual), annual_price_usd が追加済み

## Acceptance Criteria
- [ ] sat_subscription_status に billing_cycle と normalized MRR が保存される
- [ ] fct_subscription_events に arr_amount カラムが追加される
- [ ] mart_arr で年次 ARR スナップショットが取得できる
- [ ] Revenue Dashboard で ARR トレンドが確認できる

## Target Tool
dbt (Snowflake)
```

---

## ② Design — `/modscape:spec:design annual-billing`

**ユーザーのプロンプト例:**

```
/modscape:spec:design annual-billing
```

**AI の動作:**
1. `spec.md` と `specs/*.md` を読み込んで影響テーブルを特定
2. `modscape extract modscape.yaml --tables sat_subscription_status,fct_subscription_events,mart_mrr` を実行
3. 抽出したテーブルを `spec-model.yaml` に配置
4. 新テーブル `mart_arr` を `spec-model.yaml` に追加
5. `modscape layout changes/annual-billing/spec-model.yaml` でレイアウト調整
6. `design.md` と `tasks.md` を生成

**生成される `design.md` のイメージ:**

```markdown
# Design: annual-billing

## 変更対象テーブル

| テーブル | 種別 | 変更内容 |
|---|---|---|
| sat_subscription_status | 既存変更 | billing_cycle, annual_price_usd カラム追加 |
| fct_subscription_events | 既存変更 | arr_amount カラム追加 |
| mart_mrr | 既存変更 | arr 比較カラム追加 |
| mart_arr | 新規追加 | ARR スナップショットマート |

## 設計判断

### ARR の正規化方法
年次プランの `annual_price_usd` を 12 で割って月次に正規化した値を
`mrr_amount` として保存する。ARR は `mrr_amount × 12` で算出。

> **理由**: 既存の MRR 集計ロジックを変更せずに済む。
> Finance チームも月次ベースでの比較を好む。

### mart_arr のグレイン
`year_key × plan_key × country_code` — 年末時点のスナップショット。

### fct_subscription_events の arr_amount
`billing_cycle = annual` の場合のみ `annual_price_usd` を格納。
月次プランは NULL。

## Requires Model Change
<!-- 実装中に発見した場合はここに追記して /modscape:spec:design を再実行 -->
```

**生成される `tasks.md` のイメージ:**

```markdown
# Tasks: annual-billing

## Model Changes
- [ ] sat_subscription_status に billing_cycle (String) カラムを追加
- [ ] sat_subscription_status に annual_price_usd (Decimal) カラムを追加
- [ ] fct_subscription_events に arr_amount (Decimal) カラムを追加
- [ ] mart_mrr に arr (Decimal) カラムを追加
- [ ] mart_arr テーブルを新規作成

## dbt Implementation
- [ ] `stg_billing__subscriptions.sql` に billing_cycle, annual_price_usd を追加
- [ ] `sat_subscription_status.sql` にカラムを追加
- [ ] `fct_subscription_events.sql` の arr_amount 計算ロジックを実装
- [ ] `mart_mrr.sql` に ARR 比較カラムを追加
- [ ] `mart_arr.sql` を新規作成（年次スナップショット）

## Tests
- [ ] billing_cycle が monthly | annual のみであることを確認
- [ ] annual プランの arr_amount = annual_price_usd であることを確認
- [ ] mart_arr の ARR = 全アクティブ annual サブスクの annual_price_usd 合計
```

---

## ③ Implement — `/modscape:spec:implement annual-billing`

**ユーザーのプロンプト例:**

```
/modscape:spec:implement annual-billing
```

**AI のタスク処理例:**

```
Task 1/7: sat_subscription_status に billing_cycle カラムを追加

spec-model.yaml を確認しました。
以下の dbt モデルを更新します:

-- models/vault/sat_subscription_status.sql
SELECT
    subscription_hk,
    load_dts,
    hash_diff,
    status,
    trial_start_date,
    trial_end_date,
    start_date,
    cancelled_date,
    mrr_amount,
    billing_cycle,          -- 追加
    annual_price_usd        -- 追加
FROM {{ source('billing', 'subscriptions') }}

tasks.md の [ ] を [x] に更新しました。
次のタスクに進みますか？ (y/n)
```

**実装中に発見があった場合の再設計フロー:**

```
実データを確認したところ、billing_cycle = 'annual' でも
annual_price_usd が NULL のレコードが存在することがわかりました。
移行期間中の古いレコードのようです。

/modscape:spec:design annual-billing を再実行してください。
design.md の ### Requires Model Change セクションに以下を追記します:

### Requires Model Change
- annual_price_usd が NULL の場合は monthly_price_usd × 12 でフォールバック
```

---

## ④ Archive — `/modscape:spec:archive annual-billing`

**ユーザーのプロンプト例:**

```
/modscape:spec:archive annual-billing
```

**AI の動作:**

```
modscape merge modscape.yaml changes/annual-billing/spec-model.yaml --patch を実行

以下のテーブルを modscape.yaml に反映します:
  ✅ sat_subscription_status — 2 カラム追加 (billing_cycle, annual_price_usd)
  ✅ fct_subscription_events — 1 カラム追加 (arr_amount)
  ✅ mart_mrr — 1 カラム追加 (arr)
  ✅ mart_arr — 新規追加

以下の specs/*.md を生成します:
  📄 .modscape/specs/sat_subscription_status.md (新規)
  📄 .modscape/specs/fct_subscription_events.md (更新)
  📄 .modscape/specs/mart_mrr.md (更新 — Changelog のみ)
  📄 .modscape/specs/mart_arr.md (新規)

changes/annual-billing/ を archives/2024-03-01-annual-billing/ へ移動しますか？ (y/n)
```
