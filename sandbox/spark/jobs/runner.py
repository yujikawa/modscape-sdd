"""
SQL ファイル実行エンジン。
- run_sql_file: 1ファイル内の複数ステートメントを `;` 区切りで順次実行
- run_sql_dir : ディレクトリ内の *.sql をファイル名順に実行
"""
import os
from pathlib import Path
from pyspark.sql import SparkSession


def run_sql_file(spark: SparkSession, path: str) -> None:
    with open(path) as f:
        content = f.read()

    statements = [s.strip() for s in content.split(";")]
    statements = [s for s in statements if s and not s.lstrip().startswith("--")]

    for stmt in statements:
        preview = stmt[:80].replace("\n", " ")
        print(f"[runner] {os.path.basename(path)}: {preview}...")
        spark.sql(stmt)


def run_sql_dir(spark: SparkSession, dir_path: str) -> None:
    files = sorted(Path(dir_path).glob("*.sql"))
    if not files:
        raise FileNotFoundError(f"No .sql files found in {dir_path}")
    for f in files:
        run_sql_file(spark, str(f))


def run_sql_path(spark: SparkSession, path: str) -> None:
    """ファイルかディレクトリかを自動判別して実行する。"""
    p = Path(path)
    if p.is_dir():
        run_sql_dir(spark, path)
    elif p.is_file():
        run_sql_file(spark, path)
    else:
        raise FileNotFoundError(f"sql_path not found: {path}")
