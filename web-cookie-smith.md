---
title: "Cookie Smith"
category: "Web"
difficulty: "Medium"
tags: ["auth", "cookies", "sha1", "length-extension", "crypto-misuse"]
challenge: "challenges/web-cookie-smith/app.py"
exploit: "exploits/exploit_cookie_smith.py"
last_updated: "2026-03-23"
---

# Web: Cookie Smith

## Summary
Forge the `auth` cookie by abusing a SHA-1 length extension weakness in a naive "secret-prefix" signature.

## Challenge
- Endpoint: `GET /profile?user=guest` sets `auth=<base64(...)>`
- Cookie format (decoded): `user|role|sha1(SECRET || "user|role")`
- Protected page: `GET /admin` returns the flag if `admin` is present in the parsed fields.

## Solution
The server signs `SHA1(SECRET || message)`. Because SHA-1 is Merkle-Damgard, knowing the hash of an unknown-prefix message allows computing the hash of:

`SECRET || message || glue_padding || extra`

without knowing `SECRET`.

### Steps
1. Fetch a valid cookie via `GET /profile`.
2. Base64-decode to split `message` and `sig`.
3. Perform SHA-1 length extension to append `|admin` to the message.
4. Re-encode the forged cookie and request `GET /admin` with it.

## Reproduction
1. Run the challenge (Python + Flask): `python challenges/web-cookie-smith/app.py` (listens on `http://localhost:5001`).
2. Run the exploit: `python exploits/exploit_cookie_smith.py`.

## Flag
`flag{length_extension_broke_auth}`

## Mitigation
- Replace secret-prefix hashing with an HMAC: `HMAC-SHA256(secret, message)`.
- Do not store authorization decisions (like role) in client-controlled data unless it is strongly authenticated and validated.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

