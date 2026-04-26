# modscape-sdd

[Modscape](https://github.com/yujikawa/modscape) を使った **Spec-Driven Data Engineering (SDD)** のサンプルリポジトリです。

[English version is here](README.md)

---

## 仕様駆動データエンジニアリングとは？

従来のデータエンジニアリングでは、要件はチケットに書かれ、設計判断は Slack に埋もれ、唯一残るドキュメントは SQL だけ——という状況になりがちです。**SDD** は仕様を唯一の信頼源（Single Source of Truth）として扱うことでこの問題を解決します。最初のビジネス会話からアーカイブされたテーブルドキュメントまで、すべてが一本のワークフローでつながります。

ワークフローは4つのフェーズで構成され、それぞれスラッシュコマンドで進みます：

```
/modscape:spec:requirements   →  「なぜ」を書く
/modscape:spec:design         →  「何を」設計する
/modscape:spec:implement      →  「どう」作るかを実装する
/modscape:spec:archive        →  「完了」を永続化する
```

すべての決定・質問・変更は作業フォルダ（`.modscape/changes/<name>/`）に記録され、パイプラインがリリースされるとアーカイブされます。

---

## ウォークスルー：年次課金 ARR パイプライン

このリポジトリには SDD ワークフローの完全な実行例が含まれています。
シナリオ：Stripe が `billing_cycle` と `annual_price_usd` を追加したため、Finance チームが **ARR（Annual Recurring Revenue）** を MRR とは別に追跡したい。

### ソースデータ

データソースとして生 CSV を1ファイル用意しています：

```
data/01_raw__billing_subscriptions.csv   ← Stripe から10件のサブスクリプションデータ
```

パイプラインを実行すると SQLite 上で SQL が動き、4つの CSV が出力されます：

```
data/02_stg__billing_subscriptions.csv   ← 型変換・NULL補完済みステージング層
data/03_dim__subscriptions.csv           ← サブスクリプションディメンション（billing_cycle、MRR）
data/04_fct__subscription_events.csv     ← イベントファクト（arr_amount は annual のみ）
data/05_mart__arr.csv                    ← ARR スナップショット（plan × year）
```

パイプラインの実行：

```bash
python pipeline/run_pipeline.py
```

---

## ステップ別ウォークスルー

### Step 1 — 要件定義 `/modscape:spec:requirements`

ビジネス要件を自然言語で伝えます。AI が質問しながら受け入れ基準に `AC-NNN` の ID を付与し、`spec.md` を書き出します。

**プロンプト例：**
```
Finance チームから年次請求プランの分析要件が来ました。
ゴール: ARR を MRR とは別に計算できるようにする
ステークホルダー: Finance チーム、経営ダッシュボード担当
```

**出力：** `.modscape/changes/annual-billing/spec.md`

```markdown
## Acceptance Criteria
- [ ] AC-001: dim_subscriptions に billing_cycle と annual_price_usd が保存される
- [ ] AC-002: fct_subscription_events に arr_amount カラムが追加される
- [ ] AC-003: mart_arr で年次 ARR スナップショットが取得できる
- [ ] AC-004: Revenue Dashboard が ARR トレンドを表示できる
- [ ] AC-005: annual_price_usd が NULL の場合は monthly_price_usd × 12 でフォールバック

## Target Tool
SQLite + SQL（出力は CSV ファイル）
```

未解決の質問は `questions.md` に記録され、`/modscape:spec:answer` で回答します：

```
Q-001: ダッシュボード実装はスコープに含まれるか？
→ A: データマートまでがスコープ。ダッシュボードは現場対応。

Q-002: mart_arr の粒度は年次か月次か？
→ A: 年次スナップショットのみ。月次 ARR 追跡なし。
```

---

### Step 2 — モデル設計 `/modscape:spec:design annual-billing`

AI が `spec.md` を読み込み、ディメンショナルモデルを設計し、`modscape` CLI コマンドで `spec-model.yaml` を構築します。

**設計したリネージ：**

```
01_raw (CSV)
  └─► stg_billing_subscriptions   [staging]    NULL補完・型変換
        ├─► dim_subscriptions      [dimension]  billing_cycle、annual_price_usd、mrr_amount
        │     └─► fct_subscription_events  [fact]  arr_amount（annual のみ）、mrr_delta
        │               └─► mart_arr       [mart]  ARR スナップショット：year × plan × country
        │                         └─► revenue_dashboard  [consumer]
```

`design.md` に記録された主な設計判断：

| 判断 | 理由 |
|---|---|
| `annual_price_usd` NULL → `monthly_price_usd × 12` | Stripe 移行期の古いレコードにフィールドが存在しない |
| `arr_amount` は monthly プランで NULL | monthly/annual のセマンティクスを明示（AC-002） |
| `mart_arr` の粒度：`year_key × plan_id × country_code` | 年次スナップショットのみ。月次 ARR 追跡はスコープ外 |
| `country_code` は NULL | ソースデータに存在しない。来期のシステム開発で追加予定 |

**出力：** `spec-model.yaml`、`design.md`、`tasks.md`

設計の途中で **Data Vault**（サテライト）から **ディメンショナルモデル**（ディメンションテーブル）に変更しました。設計コマンドは何度でも再実行でき、変更は非破壊的に適用されます。

---

### Step 3 — 実装 `/modscape:spec:implement annual-billing`

AI が `tasks.md` を1件ずつこなしながら SQL ファイルを生成し、チェックボックスを更新します。

**生成されたファイル：**

```
pipeline/
  run_pipeline.py               ← SQLite ランナー：CSV 読み込み → SQL 実行 → CSV 出力
  sql/
    01_stg_billing_subscriptions.sql   ← COALESCE フォールバック・空文字列ガード
    02_dim_subscriptions.sql           ← SCD Type 1 ディメンション
    03_fct_subscription_events.sql     ← UNION ALL：新規 + 解約イベント
    04_mart_arr.sql                    ← GROUP BY year_key, plan_id, country_code
    05_tests.sql                       ← データ品質アサーション 7 件
```

実装中にバグを発見：SQLite は CSV カラムを TEXT として読み込むため、空文字列が `CAST("" AS REAL) = 0.0` となり COALESCE が機能しない。明示的な空文字列ガードで修正しました：

```sql
-- 修正前（CSV からロードした空文字列で壊れる）
COALESCE(CAST(annual_price_usd AS REAL), monthly_price_usd * 12)

-- 修正後（AC-005 対応）
CASE WHEN annual_price_usd IS NULL OR TRIM(annual_price_usd) = ''
     THEN CAST(monthly_price_usd AS REAL) * 12
     ELSE CAST(annual_price_usd AS REAL)
END
```

テスト結果：

```
Tests: 7 passed, 0 failed
  [PASS] stg.subscription_id: unique
  [PASS] stg.subscription_id: not_null
  [PASS] stg.billing_cycle: monthly または annual のみ
  [PASS] stg.annual_price_usd: annual 行は not_null          ← AC-005
  [PASS] dim.subscription_id: unique
  [PASS] dim.subscription_id: not_null
  [PASS] fct.arr_amount: monthly 行は NULL                   ← AC-002
```

---

### Step 4 — アーカイブ `/modscape:spec:archive annual-billing`

AI が `spec-model.yaml` をメインモデルにマージし、テーブル単位の永続スペックを書き出し、作業フォルダをアーカイブに移動します。

**作成された永続スペック：**

```
.modscape/specs/
  stg_billing_subscriptions/spec.md   ← ビジネスコンテキスト + 既知の問題
  dim_subscriptions/spec.md
  fct_subscription_events/spec.md
  mart_arr/spec.md
  _context.yaml                        ← テーブル横断の設計判断（D-001 〜 D-003）
```

**作業フォルダのアーカイブ：**

```
.modscape/archives/2026-04-18-annual-billing/
  spec.md         ← 当初の要件
  design.md       ← 設計判断 + 実装中の発見
  tasks.md        ← 完了済みチェックリスト
  questions.md    ← 全 Q&A
  spec-model.yaml
```

---

## ウォークスルー：ディメンション拡張 — 顧客・プランアナリティクス

年次課金パイプラインを土台に、Finance チームと BI チームが多軸のレベニュー分析を必要としました。ARR / MRR を顧客セグメント × プランティア × 国コードでスライスできるようにします。

### ソースデータ

2つの新しい生 CSV を追加：

```
data/02_raw__customers.csv   ← 顧客マスタ（country_code、セグメント、業種）
data/03_raw__plans.csv       ← プランマスタ（ティア、カテゴリ、価格）
```

拡張パイプラインを実行すると5つの CSV が追加出力されます：

```
data/06_stg__customers.csv          ← ステージング済み顧客データ
data/07_stg__plans.csv              ← ステージング済みプランデータ
data/08_dim__customers.csv          ← 顧客ディメンション
data/09_dim__plans.csv              ← プランディメンション
data/10_mart__revenue_summary.csv   ← 多軸 ARR/MRR サマリマート
```

---

### Step 1 — 要件定義 `/modscape:spec:requirements`

**プロンプト例：**
```
既存の ARR パイプラインを拡張して、顧客・プランのディメンションを追加したい。
ARR/MRR を customer_segment × plan_tier × country_code でスライスできるようにする。
```

**出力：** `.modscape/changes/dimension-expansion/spec.md`

```markdown
## Acceptance Criteria
- [ ] AC-001: dim_customers に country_code と customer_segment が保存される
- [ ] AC-002: dim_plans に plan_tier と plan_category が保存される
- [ ] AC-003: fct_subscription_events に customer_segment, plan_tier, plan_category が補完される
- [ ] AC-004: fct の country_code NULL が dim_customers で解決される
- [ ] AC-005: mart_revenue_summary で year × month × plan_tier × country_code × customer_segment の粒度で集計できる

## Target Tool
SQLite + SQL（出力は CSV ファイル）
```

`/modscape:spec:answer` で回答した質問：

```
Q-001: customer_id は fct_subscription_events と一致するか？
→ A: 一致する

Q-002: mart_revenue_summary の粒度は？
→ A: year × month × plan_tier × country_code × customer_segment で大丈夫

Q-003: fct に dim_customers を JOIN できるか？
→ A: JOIN できる
```

---

### Step 2 — モデル設計 `/modscape:spec:design dimension-expansion`

**設計したスタースキーマ：**

```
raw_customers ──► stg_customers ──► dim_customers ──┐
                                                      │ N:1
raw_plans ──────► stg_plans ────► dim_plans ─────────┤
                                                      ▼
                              dim_subscriptions ──► fct_subscription_events
                              (N:1)                    ├──► mart_arr            （既存）
                                                       └──► mart_revenue_summary ──► revenue_dashboard
```

`design.md` に記録された主な設計判断：

| 判断 | 理由 |
|---|---|
| `country_code` は `dim_customers` JOIN で解決 | 請求データには存在しない。D-003 をここでクローズ |
| `fct_subscription_events` は DROP & RECREATE | SQLite は ALTER TABLE + UPDATE JOIN ができない（D-005） |
| `mart_revenue_summary` と `mart_arr` を共存 | 後方互換のため既存の `mart_arr` は削除しない（D-004） |
| dim→fct の接続は**リレーション**（N:1）、リネージではない | リネージ = データフロー依存。FK 参照 = リレーション |

**出力：** `spec-model.yaml`、`design.md`、`tasks.md`

---

### Step 3 — 実装 `/modscape:spec:implement dimension-expansion`

**新規ファイル：**

```
pipeline/sql/
  06_stg_customers.sql          ← 顧客データのステージング
  07_stg_plans.sql              ← プランデータのステージング（CAST あり）
  08_dim_customers.sql          ← 顧客ディメンション
  09_dim_plans.sql              ← プランディメンション
  10_mart_revenue_summary.sql   ← 多軸 ARR/MRR マート（year × month × tier × country × segment）
```

**更新ファイル：**

```
pipeline/sql/03_fct_subscription_events.sql   ← DROP & RECREATE。dim_customers・dim_plans を LEFT JOIN
pipeline/sql/05_tests.sql                     ← 9 件のアサーションを追加（計 16 件）
pipeline/run_pipeline.py                      ← 9 ステップに拡張
```

`fct_subscription_events` の主要な拡張：

```sql
LEFT JOIN dim_customers dc ON stg.customer_id = dc.customer_id
LEFT JOIN dim_plans dp ON stg.plan_id = dp.plan_id
...
COALESCE(dc.country_code, dim_sub.country_code) AS country_code,  -- AC-004
dc.customer_segment,                                               -- AC-003
dp.plan_tier, dp.plan_category                                     -- AC-003
```

テスト結果：

```
Tests: 16 passed, 0 failed
  [PASS] dim_customers.customer_id: unique
  [PASS] dim_customers.customer_id: not_null
  [PASS] dim_customers.country_code: not_null                      ← AC-001
  [PASS] dim_plans.plan_id: unique
  [PASS] dim_plans.plan_tier: not_null                             ← AC-002
  [PASS] fct → dim_customers: 孤立した customer_id なし           ← AC-003
  [PASS] fct → dim_plans: 孤立した plan_id なし                   ← AC-003
  [PASS] fct.country_code: エンリッチ後は not_null                 ← AC-004
  [PASS] mart_revenue_summary grain: ユニーク                      ← AC-005
  ... （annual-billing の既存テスト 7 件）
```

---

### Step 4 — アーカイブ `/modscape:spec:archive dimension-expansion`

**作成・更新された永続スペック：**

```
.modscape/specs/
  stg_customers/spec.md          ← 新規
  stg_plans/spec.md              ← 新規
  dim_customers/spec.md          ← 新規
  dim_plans/spec.md              ← 新規
  mart_revenue_summary/spec.md   ← 新規
  fct_subscription_events/spec.md  ← 更新（D-003 解決、country_code NULL クローズ）
  mart_arr/spec.md               ← Changelog のみ（構造変更なし）
  _context.yaml                  ← D-003 クローズ、D-004・D-005 追加
```

**作業フォルダのアーカイブ：**

```
.modscape/archives/2026-04-18-dimension-expansion/
  spec.md         ← 当初の要件
  design.md       ← 設計判断 + 実装中の発見
  tasks.md        ← 完了済みチェックリスト
  questions.md    ← 全 Q&A
  spec-model.yaml
```

---

## サンドボックス環境

`sandbox/` ディレクトリに **Apache Spark + Apache Iceberg + Apache Airflow** の実行環境が含まれています。SDD で設計したパイプラインを実際に動かして確認できます。

### 構成

| サービス | 役割 | URL |
|---|---|---|
| Apache Airflow | パイプライン実行・スケジューリング | http://localhost:8080 |
| Apache Iceberg | Spark 上のテーブルフォーマット（MinIO に保存） | — |
| MinIO | S3 互換オブジェクトストレージ | http://localhost:9001 |
| Jupyter Notebook | インタラクティブな Spark SQL 探索 | http://localhost:8888 |

### 前提条件

**Linux / WSL2:**
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# 再ログイン後に有効
```

**macOS (Colima):**
```bash
brew install colima docker docker-compose
colima start --cpu 4 --memory 8 --disk 30
```

### 起動

```bash
cd sandbox
make up      # イメージビルド & 全サービス起動
make ps      # 状態確認（全サービスが Up になるまで待つ）
```

### パイプライン実行

```bash
make trigger     # annual_billing_pipeline DAG を実行
make query-arr   # mart_arr（ARR スナップショット）を確認
```

または Airflow UI（http://localhost:8080、admin / admin）から `annual_billing_pipeline` を手動トリガー。

> **初回実行時**: `seed_raw` タスクで PySpark が Maven から JAR を自動ダウンロードします（3〜5 分）。2 回目以降はキャッシュが効くため高速です。

### パイプラインの4フェーズ

```
seed_raw → stg_billing → core_vault → mart_arr
```

| フェーズ | Airflow タスク | 内容 |
|---|---|---|
| Phase 0 | `seed_raw` | `raw.billing_subscriptions` にサンプルデータを投入 |
| Phase 1 | `stg_billing` | `stg_billing__subscriptions`（ステージング） |
| Phase 2 | `core_vault` | `hub_subscription` / `sat_subscription_status` / `fct_subscription_events` |
| Phase 3 | `mart_arr` | `mart_arr`（grain: year × plan × country） |

`sat_subscription_status` の `billing_cycle`・`annual_price_usd` と `fct_subscription_events` の `arr_amount` は `annual-billing` チェンジの受け入れ条件に対応しています。

### 停止・削除

```bash
make down        # サービス停止（データは保持）
make clean       # コンテナ・ボリューム・イメージをすべて削除
```

---

## リポジトリ構成

```
modscape-sdd/
├── main-model.yaml              ← メインデータモデル（9 テーブル、アーカイブ時に更新）
├── data/
│   ├── 01_raw__billing_subscriptions.csv    ← ソース（annual-billing）
│   ├── 02_raw__customers.csv                ← ソース（dimension-expansion）
│   ├── 03_raw__plans.csv                    ← ソース（dimension-expansion）
│   ├── 02_stg__billing_subscriptions.csv    ← ステージング出力
│   ├── 03_dim__subscriptions.csv            ← ディメンション出力
│   ├── 04_fct__subscription_events.csv      ← ファクト出力（エンリッチ済み）
│   ├── 05_mart__arr.csv                     ← ARR マート
│   ├── 06_stg__customers.csv
│   ├── 07_stg__plans.csv
│   ├── 08_dim__customers.csv
│   ├── 09_dim__plans.csv
│   └── 10_mart__revenue_summary.csv         ← 多軸 ARR/MRR マート
├── pipeline/
│   ├── run_pipeline.py          ← エントリーポイント: python pipeline/run_pipeline.py
│   └── sql/
│       ├── 01_stg_billing_subscriptions.sql
│       ├── 02_dim_subscriptions.sql
│       ├── 03_fct_subscription_events.sql   ← DROP & RECREATE + ディメンションエンリッチ
│       ├── 04_mart_arr.sql
│       ├── 05_tests.sql                     ← アサーション 16 件
│       ├── 06_stg_customers.sql
│       ├── 07_stg_plans.sql
│       ├── 08_dim_customers.sql
│       ├── 09_dim_plans.sql
│       └── 10_mart_revenue_summary.sql
└── .modscape/
    ├── rules.md                 ← モデリング規約
    ├── specs/                   ← テーブル単位の永続ドキュメント（9 テーブル）
    │   ├── _context.yaml        ← テーブル横断の設計判断（D-001 〜 D-005）
    │   └── <table-id>/spec.md
    ├── changes/                 ← アクティブな作業フォルダ（アーカイブ後は空）
    └── archives/
        ├── 2026-04-18-annual-billing/       ← シナリオ 1
        └── 2026-04-18-dimension-expansion/  ← シナリオ 2
```

---

## SDD ワークフロー図

```
ビジネス要件
      │
      ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:requirements                                │
│  AI が確認：ゴール？ステークホルダー？AC？対象ツール？      │
│  出力: changes/<name>/spec.md  +  questions.md              │
└──────────────────────┬──────────────────────────────────────┘
                       │  /modscape:spec:answer  （Q&A ループ）
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:design <name>                               │
│  AI がモデル設計 → CLI が spec-model.yaml を構築           │
│  出力: design.md  +  tasks.md                              │
│  再実行可能：発見を追記 → 再実行 → モデルが更新            │
└──────────────────────┬──────────────────────────────────────┘
                       │  /modscape:spec:amend   （実装中の変更）
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:implement <name>                            │
│  AI がタスクを1件ずつ実装し tasks.md のチェックを更新      │
│  バグ・発見 → design.md の Findings に記録                 │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  /modscape:spec:archive <name>                              │
│  spec-model.yaml → main-model.yaml にマージ                │
│  specs/<table-id>/spec.md  +  _context.yaml を書き出し     │
│  changes/<name>/ → archives/YYYY-MM-DD-<name>/ に移動      │
└─────────────────────────────────────────────────────────────┘
```

---

## セットアップ

```bash
# Claude Code 用に SDD スキルをインストール
modscape init --claude --sdd
```

`.modscape/changes/modscape-spec.custom.md.example` を `modscape-spec.custom.md` にリネームするとデフォルト動作をカスタマイズできます。

> **Tip:** `/modscape:spec:review <name>` をいつでも実行すると、未解決の質問・AC カバレッジ・Go/No-Go サマリーを確認できます。
