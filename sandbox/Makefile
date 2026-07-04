COMPOSE = docker compose

# ── macOS (Colima) セットアップ ────────────────────────────────────────────────
# Intel Mac:
#   brew install colima docker docker-compose
#   colima start --cpu 4 --memory 8 --disk 30
#
# Apple Silicon (M1/M2/M3):
#   brew install colima docker docker-compose
#   colima start --cpu 4 --memory 8 --disk 30
#   ※ spark-notebook は platform: linux/amd64 で Rosetta エミュレーション動作
#
# Linux / WSL2:
#   curl -fsSL https://get.docker.com | sh
#   sudo usermod -aG docker $USER  # 再ログイン必要
# ───────────────────────────────────────────────────────────────────────────────

.PHONY: up down logs seed trigger clean ps colima-start colima-stop

up:          ## イメージビルド & 全サービス起動
	$(COMPOSE) up -d --build

down:        ## サービス停止
	$(COMPOSE) down

logs:        ## ログをストリーミング表示
	$(COMPOSE) logs -f

ps:          ## サービスの状態確認
	$(COMPOSE) ps

seed:        ## raw テーブルにサンプルデータを投入（up 後に一度実行）
	$(COMPOSE) exec airflow-scheduler python /opt/spark/jobs/seed_raw.py

trigger:     ## annual_billing_pipeline DAG を手動実行
	$(COMPOSE) exec airflow-webserver airflow dags trigger annual_billing_pipeline

query-arr:   ## mart_arr の内容を確認
	$(COMPOSE) exec airflow-scheduler python -c "\
import sys; sys.path.insert(0,'/opt/spark/jobs'); \
from utils import create_spark; \
s=create_spark('query'); \
s.sql('SELECT * FROM local.mart.mart_arr').show(truncate=False); \
s.stop()"

clean:         ## コンテナ・ボリューム・ローカルイメージをすべて削除
	$(COMPOSE) down -v --rmi local

colima-start:  ## [macOS] Colima 起動（初回のみ）
	colima start --cpu 4 --memory 8 --disk 30

colima-stop:   ## [macOS] Colima 停止
	colima stop
