# Questions: billing-job-propagation

## Pipeline-level

- [x] **Q-001** job カラムはどのテーブルまで伝播させるか？
  **Answer:** stg_billing_subscriptions, fct_subscription_events, dim_subscriptions, mart_arr, mart_revenue_summary すべてに追加する

- [x] **Q-002** mart テーブルで job カラムをどう扱うか（集計軸 or 属性列）？
  **Answer:** mart_arr および mart_revenue_summary の GROUP BY に job を追加し、職業別集計軸とする

## Table-level

- [ ] **Q-003** job カラムの NULL 値の扱いはどうするか？
  **Assumption:** NULL は許容せず、stg 層で `NULLIF(TRIM(job), '')` によるガードを実装する（unconfirmed）

- [ ] **Q-004** job カラムの取りうる値（enum）は何か？マスタリストはあるか？
  **Assumption:** マスタリストは未確定のため、現時点では String 自由文字列として受け入れる（unconfirmed）

- [ ] **Q-005** mart_arr の粒度が変わる（job が grain に追加）ことで既存の BI クエリや下流処理に影響はないか？
  **Assumption:** DROP & RECREATE での再構築が必要な可能性あり。BI チームへの確認が必要（unconfirmed）

- [ ] **Q-006** billing テーブルへの job カラム追加以前の既存レコードの job 値はどうなるか？（NULL？バックフィル？）
  **Assumption:** 既存レコードは NULL として扱い、バックフィルはしない（unconfirmed）

- [ ] **Q-007** job 値の表記揺れ（"Engineer" / "engineer" / "ENGINEER" 等）は stg 層で正規化するか？
  **Assumption:** 正規化なし、ソースの値をそのまま引き継ぐ（unconfirmed）

- [ ] **Q-008** job は「サブスクリプション登録時点の職業」か「顧客の現在の職業」か？（dim_subscriptions の SCD Type1 設計に影響する）
  **Assumption:** サブスクリプション単位の属性として扱い、dim_subscriptions で SCD Type1 保持（unconfirmed）

- [ ] **Q-009** mart テーブルで job が NULL のレコードはどう集計するか？（"Unknown" に変換してグルーピング？ NULL のまま除外？）
  **Assumption:** NULL はそのまま NULL として GROUP BY する（unconfirmed）

- [ ] **Q-010** billing テーブルの job カラムのデータ型・最大文字数に制約はあるか？（VARCHAR(N) 等）
  **Assumption:** 制約なしの String として受け入れる（unconfirmed）
