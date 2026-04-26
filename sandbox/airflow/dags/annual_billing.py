"""
DAG: annual_billing_pipeline
pipeline.json を読み込んでタスクグラフを動的に構築する。
depends_on で並列実行できるタスクは Airflow が自動で並列化する。
"""
import importlib.util
import json
import sys
from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator

JOBS_PATH = "/opt/spark/jobs"
SQL_BASE  = "/opt/spark/sql"
PIPELINE_JSON = f"{SQL_BASE}/pipeline.json"

default_args = {"owner": "modscape", "retries": 1}


def _run(table_name: str, sql_path: str) -> None:
    if JOBS_PATH not in sys.path:
        sys.path.insert(0, JOBS_PATH)
    spec = importlib.util.spec_from_file_location("run", f"{JOBS_PATH}/run.py")
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.main(table_name, sql_path)


with DAG(
    dag_id="annual_billing_pipeline",
    description="pipeline.json から動的に構築される annual-billing パイプライン",
    schedule_interval=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["modscape", "annual-billing", "iceberg"],
) as dag:

    with open(PIPELINE_JSON) as f:
        pipeline: dict = json.load(f)

    # タスクを生成
    tasks = {
        name: PythonOperator(
            task_id=name,
            python_callable=_run,
            op_args=[name, f"{SQL_BASE}/{config['sql_path'].removeprefix('sql/')}"],
        )
        for name, config in pipeline.items()
    }

    # 依存関係を設定
    for name, config in pipeline.items():
        for dep in config.get("depends_on", []):
            tasks[dep] >> tasks[name]
