# Questions: annual-billing

## Pipeline-level

- [x] **Q-001** Revenue Dashboard での ARR トレンド表示（AC-004）の実装はデータ側の対応のみか、ダッシュボード側の実装も本スコープに含まれるか？
  **A:** スコープはデータマート（`mart_arr`）の提供まで。ダッシュボード実装は現場（別チーム）が対応する。

- [x] **Q-002** `mart_arr` のスナップショット粒度は年次（year_key × plan × country）か、月次でも ARR を追跡するか？
  **A:** 月次では ARR を追跡しない。年次スナップショット（`year_key × plan_id × country_code`）のみ。

## Table-level

- [x] **Q-003** `country_code` がソース CSV（`01_raw__billing_subscriptions.csv`）に存在しない。`dim_subscriptions` / `fct_subscription_events` / `mart_arr` の `country_code` はどのテーブルから取得するか？ <!-- amend -->
  **A:** 来期のシステム開発で実装予定。現時点では NULL のままで問題なし。
