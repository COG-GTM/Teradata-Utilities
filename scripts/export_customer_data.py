#!/usr/bin/env python3
"""
export_customer_data.py

Exports customer data from the Teradata customer_new table to a delimited flat
file. This script replaces the following legacy Teradata export scripts:

  - Export.tpt.txt       (TPT export to EXPORTOUTPUT.TXT)
  - tptscript.txt        (TPT export variant)
  - Export.bteq.txt      (BTEQ export with pipe delimiter)
  - FastExport.fexp.txt  (FastExport)
  - FastExport_1.fexp.txt (FastExport with gender filter)
  - csvexport.bteq.txt   (BTEQ CSV export)

Prerequisites:
  pip install teradatasql

Environment variables (or pass via CLI arguments):
  TD_HOST      Teradata server hostname or IP
  TD_USER      Teradata username
  TD_PASSWORD  Teradata password

Usage:
  python scripts/export_customer_data.py --output customer_export.csv --delimiter ','
  python scripts/export_customer_data.py --output customer_export.txt --delimiter '|'
  python scripts/export_customer_data.py --output males.csv --where "gender = 'M'"
"""

from __future__ import annotations

import argparse
import csv
import logging
import os
import sys
from typing import Optional

import teradatasql

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

SOURCE_TABLE = "financial.customer_new"
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


def export_data(
    host: str,
    user: str,
    password: str,
    source_table: str,
    output_path: str,
    delimiter: str,
    where_clause: Optional[str],
    include_header: bool,
) -> int:
    """
    Query *source_table* and write the results to *output_path*.

    Returns the total number of rows exported.
    """
    conn = get_connection(host, user, password)
    cursor = conn.cursor()

    try:
        col_list = ", ".join(COLUMNS)
        query = f"SELECT {col_list} FROM {source_table}"
        if where_clause:
            query += f" WHERE {where_clause}"
        query += " ORDER BY cust_id"

        logger.info("Executing: %s", query)
        cursor.execute(query)

        total_rows = 0
        with open(output_path, "w", newline="", encoding="utf-8") as fh:
            writer = csv.writer(fh, delimiter=delimiter)

            if include_header:
                writer.writerow(COLUMNS)

            while True:
                rows = cursor.fetchmany(1000)
                if not rows:
                    break
                for row in rows:
                    writer.writerow(row)
                total_rows += len(rows)
                logger.info("Exported %d rows so far ...", total_rows)

        logger.info("Export complete. Total rows: %d -> %s", total_rows, output_path)
        return total_rows

    except Exception:
        logger.exception("Error during data export")
        raise
    finally:
        cursor.close()
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export customer data from Teradata to a flat file.",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to the output file.",
    )
    parser.add_argument(
        "--delimiter",
        default=",",
        help="Field delimiter (default: ',').",
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
        "--source-table",
        default=SOURCE_TABLE,
        help=f"Source table (default: {SOURCE_TABLE}).",
    )
    parser.add_argument(
        "--where",
        default=None,
        help="Optional WHERE clause (e.g. \"gender = 'M'\").",
    )
    parser.add_argument(
        "--no-header",
        action="store_true",
        help="Omit the header row from the output file.",
    )

    args = parser.parse_args()

    if not args.host or not args.user or not args.password:
        logger.error(
            "Teradata connection details are required. "
            "Set TD_HOST, TD_USER, TD_PASSWORD environment variables or use --host, --user, --password flags."
        )
        sys.exit(1)

    export_data(
        host=args.host,
        user=args.user,
        password=args.password,
        source_table=args.source_table,
        output_path=args.output,
        delimiter=args.delimiter,
        where_clause=args.where,
        include_header=not args.no_header,
    )


if __name__ == "__main__":
    main()
