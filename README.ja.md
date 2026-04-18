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

## リポジトリ構成

```
modscape-sdd/
├── main-model.yaml              ← メインデータモデル（アーカイブ時に生成）
├── data/
│   ├── 01_raw__billing_subscriptions.csv    ← ソースデータ
│   ├── 02_stg__billing_subscriptions.csv    ← ステージング出力
│   ├── 03_dim__subscriptions.csv            ← ディメンション出力
│   ├── 04_fct__subscription_events.csv      ← ファクト出力
│   └── 05_mart__arr.csv                     ← マート出力
├── pipeline/
│   ├── run_pipeline.py          ← エントリーポイント: python pipeline/run_pipeline.py
│   └── sql/
│       ├── 01_stg_billing_subscriptions.sql
│       ├── 02_dim_subscriptions.sql
│       ├── 03_fct_subscription_events.sql
│       ├── 04_mart_arr.sql
│       └── 05_tests.sql
└── .modscape/
    ├── rules.md                 ← モデリング規約
    ├── specs/                   ← テーブル単位の永続ドキュメント
    │   ├── _context.yaml        ← テーブル横断の設計判断
    │   └── <table-id>/spec.md
    ├── changes/                 ← アクティブな作業フォルダ（アーカイブ後は空）
    └── archives/
        └── 2026-04-18-annual-billing/   ← 完了済みスペック
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
