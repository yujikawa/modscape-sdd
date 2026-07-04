"""
汎用エントリーポイント。
  python run.py <table_name> <sql_path>
  sql_path はファイルでもディレクトリでも可。
"""
import sys
sys.path.insert(0, "/opt/spark/jobs")
from utils import create_spark
from runner import run_sql_path


def main(table_name: str, sql_path: str) -> None:
    spark = create_spark(table_name)
    run_sql_path(spark, sql_path)
    spark.stop()


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python run.py <table_name> <sql_path>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
