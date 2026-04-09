# Design: Annual Billing Support

## Design Decisions

### ARR の正規化方法
年次プランの `annual_price_usd` は `sat_subscription_status` にそのまま保存する。
`fct_subscription_events` の `arr_amount` には `billing_cycle = 'annual'` の場合のみ `annual_price_usd` を格納し、月次プランは `NULL` とする。

> **理由**: MRR の正規化ロジック（`annual_price_usd / 12`）は `mart_mrr` の `arr` カラムでのみ行う。Fact テーブルに変換ロジックを持ち込むと再利用性が下がるため、生の値を保持する。

### mart_arr のグレイン
`year_key × plan_key × country_code` — 年末時点のスナップショット。

> `mart_mrr` が月次スナップショットであるのに対し、`mart_arr` は年次集計。Finance チームが ARR を年度単位の KPI として管理するため、グレインを分離する。

### mart_mrr への ARR カラム追加
`mart_mrr` に `arr` カラムを追加し、月次レポートで MRR と ARR を並列表示できるようにする。`arr` は `fct_subscription_events.arr_amount` の SUM（annual プランのみ非 NULL）。

## Affected Tables

### Direct Impact
- `sat_subscription_status`: `billing_cycle` (String) と `annual_price_usd` (Decimal) カラムを追加
- `fct_subscription_events`: `arr_amount` (Decimal, fully additive) カラムを追加
- `mart_mrr`: `arr` (Decimal) カラムと implementation measure を追加
- `mart_arr`: 新規テーブル（年次 ARR スナップショットマート）

### Indirect Impact
- `hub_subscription`: `sat_subscription_status` の upstream（Changelog エントリのみ archive 時に追記）

## Findings

### Requires Model Change
<!-- 実装中に発見した場合はここに追記して /modscape:spec:design annual-billing を再実行 -->

### Implementation Notes
<!-- モデル変更を伴わない観察事項 -->
