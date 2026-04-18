# Design: Annual Billing Support

## Design Decisions

### パイプライン全体構成
`billing.subscriptions` (CSV) → Staging → Dimension + Fact → Mart → Dashboard のディメンショナルモデル構成。
Target tool は SQLite + SQL（Python `sqlite3` でパイプライン実行）、各ステップの結果を CSV にエクスポートする。

> ⚠ Amended 2026-04-18: Target tool を pandas → SQLite + SQL に変更。

### annual_price_usd NULL フォールバック（AC-005）
`billing_cycle = annual` かつ `annual_price_usd` が NULL の場合（例: sub_007 のような移行期レコード）、
Staging 層で `monthly_price_usd × 12` に補完する。以降のすべての下流テーブルはフォールバック済みの値を使う。

### MRR 正規化
annual プランの `mrr_amount` は `annual_price_usd / 12` として算出する。
これにより `sat_subscription_status` の `mrr_amount` は monthly・annual を同一スケールで比較できる。

### arr_amount の配置
`fct_subscription_events` に `arr_amount` カラムを追加（AC-002）。
monthly プランは NULL、annual プランのみ `annual_price_usd` を格納する。

### mart_arr の粒度
`year_key × plan_id × country_code` の年次スナップショット（Q-002 の仮定を採用）。
Revenue Dashboard の ARR トレンド表示（AC-003, AC-004）に対応する。

### Consumer ノード
`revenue_dashboard` を Consumer として YAML に定義し、`mart_arr` からの Lineage を明示する。

## Affected Tables

> ⚠️ This Affected Tables classification is an AI proposal. Edit directly if the classification is incorrect.

### Direct Impact
- `stg_billing_subscriptions`: 新規作成 — Staging 層。NULL フォールバックを含む型変換を担う
- `dim_subscriptions`: 新規作成 — billing_cycle / annual_price_usd / mrr_amount を保持するディメンション（AC-001）
- `fct_subscription_events`: 新規作成 — arr_amount カラムを持つイベントファクト（AC-002）
- `mart_arr`: 新規作成 — plan × country 粒度の ARR スナップショット（AC-003）

### Downstream Impact — Implement
（初回全テーブル新規作成のため該当なし）

### Downstream Impact — Context Only
- `revenue_dashboard` (Consumer): mart_arr の出力を受け取るダッシュボード。データ側の実装スコープ外（Q-001 仮定）

## Findings

### Requires Model Change
（なし）

### Implementation Notes
- raw データ `01_raw__billing_subscriptions.csv` の `sub_007` は `annual_price_usd` が空。Staging でフォールバック処理が必須。
- ディメンショナルモデルに変更したため、Data Vault 固有の `subscription_hk` / `hash_diff` は不要。`subscription_id` を自然キーとして使用する。
- CSV を SQLite に TEXT でロードすると空文字列 `""` が `CAST("" AS REAL) = 0.0` になり COALESCE が機能しない。`TRIM(col) = ''` のガードが必要（`01_stg_billing_subscriptions.sql` で対応済み）。
- `country_code` はソース CSV に存在しない。`dim_subscriptions` / `fct_subscription_events` では NULL を格納し `-- TODO` を付与（Q-003）。
