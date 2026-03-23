#!/usr/bin/env python3
"""
CTF Challenge: Reused IV (AES-CTR)

The server encrypts every message with AES-CTR using the SAME fixed nonce,
producing the same keystream each time.  This degrades to a simple XOR cipher:

    C  = P  XOR keystream
    C' = P' XOR keystream
    C  XOR C' = P XOR P'     ← XOR of any two ciphertexts = XOR of their plaintexts

Attack: encrypt a known all-zero block to recover keystream, then XOR it
against the target ciphertext to reveal the flag.

Endpoints:
    POST /encrypt  { "plaintext": "<base64>" } → { "ciphertext": "...", "nonce": "..." }
    GET  /target   → { "ciphertext": "...", "nonce": "...", "hint": "..." }

INTENTIONALLY VULNERABLE — for CTF/educational use only.
"""
import base64
import os

from Crypto.Cipher import AES
from flask import Flask, jsonify, request

app = Flask(__name__)

KEY = os.urandom(16)          # random AES-128 key, unknown to the attacker
FIXED_NONCE = os.urandom(8)   # REUSED nonce — the intentional vulnerability
FLAG = b"flag{never_reuse_iv}"
FLAG_PADDED = FLAG + b"\x00" * (-len(FLAG) % 16)


def ctr_encrypt(plaintext: bytes) -> bytes:
    """Encrypt with AES-CTR using the fixed (reused) nonce."""
    cipher = AES.new(KEY, AES.MODE_CTR, nonce=FIXED_NONCE)
    return cipher.encrypt(plaintext)


@app.route("/encrypt", methods=["POST"])
def encrypt():
    """Encryption oracle: returns AES-CTR(fixed_nonce, caller_plaintext)."""
    data = request.get_json(silent=True) or {}
    try:
        pt = base64.b64decode(data.get("plaintext", ""))
    except Exception:
        return jsonify(error="invalid base64"), 400
    ct = ctr_encrypt(pt)
    return jsonify(
        ciphertext=base64.b64encode(ct).decode(),
        nonce=base64.b64encode(FIXED_NONCE).decode(),
    )


@app.route("/target")
def target():
    """Returns the flag encrypted with the same fixed nonce."""
    ct = ctr_encrypt(FLAG_PADDED)
    return jsonify(
        ciphertext=base64.b64encode(ct).decode(),
        nonce=base64.b64encode(FIXED_NONCE).decode(),
        hint="Recover the flag using the /encrypt oracle (reused nonce!).",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5003, debug=False)
