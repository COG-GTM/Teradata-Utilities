#!/usr/bin/env python3
"""
load_customer_data.py

Bulk-loads customer data from a CSV or pipe-delimited flat file into a Teradata
staging table. This script replaces the following legacy Teradata ETL scripts:

  - Customer_fastload.fl.txt  (FastLoad from pipe-delimited file)
  - Customerinsert.ml.txt     (MultiLoad insert)
  - mloadtpt.txt              (TPT load from pipe-delimited file)

Prerequisites:
  pip install teradatasql

Environment variables (or pass via CLI arguments):
  TD_HOST      Teradata server hostname or IP
  TD_USER      Teradata username
  TD_PASSWORD  Teradata password

Usage:
  python scripts/load_customer_data.py --file data_files/customer_incoming_pipe.txt --delimiter '|'
  python scripts/load_customer_data.py --file seeds/customer_incoming.csv --delimiter ','
"""

from __future__ import annotations

import argparse
import csv
import logging
import os
import sys
from typing import List, Tuple

import teradatasql

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

TARGET_TABLE = "financial.customer"
COLUMNS = [
    "cust_id",
    "income",
    "age",
    "years_with_bank",
    "nbr_children",
    "gender",
    "marital_status",
]


def get_connection(host: str, user: str, password: str) -> teradatasql.TeradataConnection:
    """Create and return a Teradata connection."""
    logger.info("Connecting to Teradata at %s as %s ...", host, user)
    conn = teradatasql.connect(
        host=host,
        user=user,
        password=password,
        tmode="ANSI",
        log=0,
    )
    logger.info("Connected successfully.")
    return conn


def load_file(
    filepath: str,
    delimiter: str,
    host: str,
    user: str,
    password: str,
    target_table: str,
    batch_size: int,
    truncate_first: bool,
) -> int:
    """
    Read *filepath* and batch-insert rows into *target_table*.

    Returns the total number of rows inserted.
    """
    conn = get_connection(host, user, password)
    cursor = conn.cursor()

    try:
        if truncate_first:
            logger.info("Truncating %s before load ...", target_table)
            cursor.execute(f"DELETE FROM {target_table}")
            logger.info("Table truncated.")

        placeholders = ", ".join(["?"] * len(COLUMNS))
        col_list = ", ".join(COLUMNS)
        insert_sql = f"INSERT INTO {target_table} ({col_list}) VALUES ({placeholders})"

        total_rows = 0
        batch: List[Tuple[str, ...]] = []

        with open(filepath, newline="", encoding="utf-8") as fh:
            reader = csv.reader(fh, delimiter=delimiter)

            # Skip header row if the first field looks like a column name
            first_row = next(reader, None)
            if first_row is None:
                logger.warning("Input file is empty: %s", filepath)
                return 0

            if first_row[0].strip().lower() == "cust_id":
                logger.info("Header row detected and skipped.")
            else:
                batch.append(tuple(field.strip() for field in first_row))

            for row in reader:
                if not row or all(field.strip() == "" for field in row):
                    continue
                batch.append(tuple(field.strip() for field in row))

                if len(batch) >= batch_size:
                    cursor.executemany(insert_sql, batch)
                    total_rows += len(batch)
                    logger.info("Inserted %d rows (total: %d) ...", len(batch), total_rows)
                    batch = []

            # Flush remaining rows
            if batch:
                cursor.executemany(insert_sql, batch)
                total_rows += len(batch)
                logger.info("Inserted %d rows (total: %d).", len(batch), total_rows)

        conn.commit()
        logger.info("Load complete. Total rows inserted: %d", total_rows)
        return total_rows

    except Exception:
        logger.exception("Error during data load")
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Load customer data from a flat file into Teradata.",
    )
    parser.add_argument(
        "--file",
        required=True,
        help="Path to the input data file (CSV or pipe-delimited).",
    )
    parser.add_argument(
        "--delimiter",
        default="|",
        help="Field delimiter (default: '|').",
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("TD_HOST", ""),
        help="Teradata host (default: $TD_HOST).",
    )
    parser.add_argument(
        "--user",
        default=os.environ.get("TD_USER", ""),
        help="Teradata user (default: $TD_USER).",
    )
    parser.add_argument(
        "--password",
        default=os.environ.get("TD_PASSWORD", ""),
        help="Teradata password (default: $TD_PASSWORD).",
    )
    parser.add_argument(
        "--target-table",
        default=TARGET_TABLE,
        help=f"Target table (default: {TARGET_TABLE}).",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1000,
        help="Number of rows per INSERT batch (default: 1000).",
    )
    parser.add_argument(
        "--truncate",
        action="store_true",
        help="Truncate the target table before loading.",
    )

    args = parser.parse_args()

    if not args.host or not args.user or not args.password:
        logger.error(
            "Teradata connection details are required. "
            "Set TD_HOST, TD_USER, TD_PASSWORD environment variables or use --host, --user, --password flags."
        )
        sys.exit(1)

    if not os.path.isfile(args.file):
        logger.error("Input file not found: %s", args.file)
        sys.exit(1)

    load_file(
        filepath=args.file,
        delimiter=args.delimiter,
        host=args.host,
        user=args.user,
        password=args.password,
        target_table=args.target_table,
        batch_size=args.batch_size,
        truncate_first=args.truncate,
    )


if __name__ == "__main__":
    main()
