---
title: "Reused Nonce (AES-CTR)"
category: "Crypto"
difficulty: "Easy"
tags: ["aes-ctr", "nonce-reuse", "xor", "keystream-recovery"]
challenge: "challenges/crypto-reused-iv/server.py"
exploit: "exploits/exploit_reused_iv.py"
last_updated: "2026-03-23"
---

# Crypto: Reused Nonce (AES-CTR)

## Summary
Recover the flag by exploiting AES-CTR nonce reuse, which reuses the same keystream for every encryption.

## Challenge
- The server encrypts user-provided plaintext via `POST /encrypt`.
- It also returns a target ciphertext via `GET /target` (the flag encrypted).
- Vulnerability: AES-CTR is used with a fixed nonce (`FIXED_NONCE`) for all requests.

## Solution
In CTR mode:
- `C = P XOR keystream`

If the same nonce is reused, the keystream repeats. If we can ask the server to encrypt a known plaintext (like all-zero bytes), we directly learn the keystream:
- `encrypt(00..00) = keystream`

Then decrypt:
- `P = C XOR keystream`

## Reproduction
1. Run the challenge: `python challenges/crypto-reused-iv/server.py` (listens on `http://localhost:5003`).
2. Run the exploit: `python exploits/exploit_reused_iv.py`.

## Flag
`flag{never_reuse_iv}`

## Mitigation
- Never reuse a CTR nonce for the same key.
- Prefer AEAD constructions (AES-GCM or ChaCha20-Poly1305) with correct nonce handling.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

