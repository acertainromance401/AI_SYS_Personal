import os
from contextlib import contextmanager

import psycopg


def get_db_dsn() -> str:
    return os.getenv("DATABASE_URL", "postgresql://localhost:5432/aisys")


@contextmanager
def get_conn():
    conn = psycopg.connect(get_db_dsn())
    try:
        yield conn
    finally:
        conn.close()
