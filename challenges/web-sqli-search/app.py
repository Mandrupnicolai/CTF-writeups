#!/usr/bin/env python3
"""
CTF Challenge: SQLi in Search
Raw string interpolation into a SQLite LIKE query.

Endpoint: GET /search?q=<input>
Error response echoes the SQLite exception (schema disclosure).

INTENTIONALLY VULNERABLE — for CTF/educational use only.
"""
import os
import sqlite3

from flask import Flask, g, request

app = Flask(__name__)

DB_PATH = os.path.join(os.path.dirname(__file__), "challenge.db")
FLAG = "flag{union_select_ftw}"

_db_ready = False


def init_db():
    global _db_ready
    if _db_ready or os.path.exists(DB_PATH):
        _db_ready = True
        return
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT)")
    cur.execute("CREATE TABLE flags (id INTEGER PRIMARY KEY, flag TEXT)")
    cur.executemany(
        "INSERT INTO posts VALUES (?,?)",
        [(1, "Hello World"), (2, "CTF News"), (3, "How to SQLi")],
    )
    cur.execute("INSERT INTO flags VALUES (1, ?)", (FLAG,))
    conn.commit()
    conn.close()
    _db_ready = True


def get_db() -> sqlite3.Connection:
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
    return g.db


@app.teardown_appcontext
def close_db(exc=None):
    db = g.pop("db", None)
    if db:
        db.close()


@app.before_request
def ensure_db():
    init_db()


@app.route("/")
def index():
    return (
        "<h1>SQLi Search Challenge</h1>"
        '<form action="/search" method="get">'
        '<input name="q" placeholder="search posts...">'
        "<button>Search</button></form>"
    )


@app.route("/search")
def search():
    q = request.args.get("q", "")
    db = get_db()
    try:
        # VULNERABLE: unsanitised user input interpolated into SQL query
        query = f"SELECT title FROM posts WHERE title LIKE '%{q}%'"
        rows = db.execute(query).fetchall()
        results = "\n".join(r[0] for r in rows) or "(no results)"
        return f"<pre>{results}</pre>"
    except Exception as exc:
        # VULNERABLE: verbose error leaks schema information
        return f"<pre>Error near &quot;{exc}&quot; at line 1</pre>", 500


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5002, debug=False)
