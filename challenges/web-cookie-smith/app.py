#!/usr/bin/env python3
"""
CTF Challenge: Cookie Smith
SHA-1 length extension vulnerability in auth cookie.

Cookie format: BASE64(user|role|SHA1(SECRET || "user|role"))

INTENTIONALLY VULNERABLE — for CTF/educational use only.
"""
import base64
import hashlib
import os

from flask import Flask, make_response, request

app = Flask(__name__)

SECRET = os.environ.get("COOKIE_SECRET", "s3cr3t_k3y_42").encode()
FLAG = "flag{length_extension_broke_auth}"


def sign(message: bytes) -> str:
    """SHA-1(SECRET || message) — vulnerable to length extension attacks."""
    return hashlib.sha1(SECRET + message).hexdigest()


def make_auth_cookie(user: str, role: str) -> str:
    message = f"{user}|{role}".encode()
    sig = sign(message)
    raw = f"{user}|{role}|{sig}"
    return base64.b64encode(raw.encode()).decode()


def verify_cookie(cookie_b64: str):
    """
    Parse BASE64(fields...|sha1sig).
    Splits on the LAST '|' to separate signature from message body.
    Returns (is_valid, parts_list).
    """
    try:
        raw = base64.b64decode(cookie_b64).decode("latin-1")
        idx = raw.rfind("|")
        if idx < 0:
            return False, []
        sig = raw[idx + 1 :]
        message = raw[:idx]
        if sign(message.encode("latin-1")) != sig:
            return False, []
        return True, message.split("|")
    except Exception:
        return False, []


@app.route("/")
def index():
    return (
        "<h1>Cookie Smith Challenge</h1>"
        '<p><a href="/profile?user=guest">Login as guest</a></p>'
        '<p><a href="/admin">Try /admin</a></p>'
        "<p>Hint: GET /profile sets an auth cookie. Forge it to get admin.</p>"
    )


@app.route("/profile")
def profile():
    user = request.args.get("user", "guest").replace("|", "")
    cookie = make_auth_cookie(user, "user")
    resp = make_response(f"<p>Logged in as <b>{user}</b> (role=user)</p>")
    resp.set_cookie("auth", cookie)
    return resp


@app.route("/admin")
def admin():
    cookie_b64 = request.cookies.get("auth", "")
    valid, parts = verify_cookie(cookie_b64)
    if not valid:
        return "<p>401: Invalid or missing auth cookie.</p>", 401
    if "admin" in parts:
        return f"<p>Welcome, admin! Flag: <b>{FLAG}</b></p>"
    return "<p>403: admin role required.</p>", 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)
