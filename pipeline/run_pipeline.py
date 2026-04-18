"""
Annual Billing Pipeline — SQLite runner
  1. Load raw CSV → SQLite
  2. Run SQL steps in order
  3. Export each step's table → data/*.csv
  4. Run tests and report results
"""

import csv
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
DATA = ROOT / "data"
SQL  = Path(__file__).parent / "sql"

STEPS = [
    ("01_stg_billing_subscriptions.sql", "stg_billing_subscriptions", "02_stg__billing_subscriptions.csv"),
    ("02_dim_subscriptions.sql",          "dim_subscriptions",          "03_dim__subscriptions.csv"),
    ("03_fct_subscription_events.sql",    "fct_subscription_events",    "04_fct__subscription_events.csv"),
    ("04_mart_arr.sql",                   "mart_arr",                   "05_mart__arr.csv"),
]


def load_raw(con: sqlite3.Connection) -> None:
    con.execute("DROP TABLE IF EXISTS raw_billing_subscriptions")
    with open(DATA / "01_raw__billing_subscriptions.csv", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    if not rows:
        raise RuntimeError("raw CSV is empty")
    cols = ", ".join(f'"{c}" TEXT' for c in rows[0])
    con.execute(f"CREATE TABLE raw_billing_subscriptions ({cols})")
    placeholders = ", ".join("?" for _ in rows[0])
    con.executemany(
        f"INSERT INTO raw_billing_subscriptions VALUES ({placeholders})",
        [list(r.values()) for r in rows],
    )
    print(f"  [load]  raw_billing_subscriptions — {len(rows)} rows")


def run_step(con: sqlite3.Connection, sql_file: str, table: str, out_csv: str) -> None:
    con.execute(f"DROP TABLE IF EXISTS {table}")
    sql = (SQL / sql_file).read_text()
    con.executescript(sql)
    cur = con.execute(f"SELECT * FROM {table}")
    rows = cur.fetchall()
    cols = [d[0] for d in cur.description]
    out_path = DATA / out_csv
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(cols)
        writer.writerows(rows)
    print(f"  [step]  {table} — {len(rows)} rows → {out_csv}")


def run_tests(con: sqlite3.Connection) -> bool:
    sql = (SQL / "05_tests.sql").read_text()
    # Keep only blocks that contain a SELECT (skip pure comment blocks)
    raw_blocks = [s.strip() for s in sql.split(";") if s.strip()]
    statements = [b for b in raw_blocks if any(ln.lstrip().upper().startswith("SELECT") for ln in b.splitlines())]
    passed = failed = 0
    for stmt in statements:
        cur = con.execute(stmt)
        rows = cur.fetchall()
        select_line = next(ln for ln in stmt.splitlines() if ln.lstrip().upper().startswith("SELECT"))
        label = select_line.replace("SELECT '", "").replace("SELECT '", "").split("'")[0].lstrip("SELECT ").strip("'").split(" AS ")[0]
        if rows:
            print(f"  [FAIL]  {label}")
            for r in rows:
                print(f"          {r}")
            failed += 1
        else:
            print(f"  [PASS]  {label}")
            passed += 1
    print(f"\n  Tests: {passed} passed, {failed} failed")
    return failed == 0


def main() -> None:
    con = sqlite3.connect(":memory:")
    con.row_factory = sqlite3.Row

    print("\n── Load ──────────────────────────────────")
    load_raw(con)

    print("\n── Steps ─────────────────────────────────")
    for sql_file, table, out_csv in STEPS:
        run_step(con, sql_file, table, out_csv)

    print("\n── Tests ─────────────────────────────────")
    ok = run_tests(con)

    con.close()
    print("\n── Done ──────────────────────────────────")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
