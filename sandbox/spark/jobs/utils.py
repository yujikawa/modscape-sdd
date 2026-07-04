import os
from pyspark.sql import SparkSession

_PACKAGES = ",".join([
    "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.5.2",
    "org.apache.hadoop:hadoop-aws:3.3.4",
    "com.amazonaws:aws-java-sdk-bundle:1.12.262",
])


def create_spark(app_name: str) -> SparkSession:
    minio = os.getenv("MINIO_ENDPOINT", "http://minio:9000")
    key   = os.getenv("AWS_ACCESS_KEY_ID", "admin")
    secret = os.getenv("AWS_SECRET_ACCESS_KEY", "password")
    warehouse = os.getenv("ICEBERG_WAREHOUSE", "s3a://warehouse/")

    return (
        SparkSession.builder
        .appName(app_name)
        .master("local[*]")
        .config("spark.jars.packages", _PACKAGES)
        .config("spark.sql.extensions",
                "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.defaultCatalog", "local")
        .config("spark.sql.catalog.local",
                "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.local.type", "hadoop")
        .config("spark.sql.catalog.local.warehouse", warehouse)
        .config("spark.hadoop.fs.s3a.endpoint", minio)
        .config("spark.hadoop.fs.s3a.access.key", key)
        .config("spark.hadoop.fs.s3a.secret.key", secret)
        .config("spark.hadoop.fs.s3a.path.style.access", "true")
        .config("spark.hadoop.fs.s3a.impl",
                "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("spark.hadoop.fs.s3a.aws.credentials.provider",
                "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false")
        .getOrCreate()
    )
