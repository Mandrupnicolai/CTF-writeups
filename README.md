# CTF Writeups

7 concise writeups (requested range: 5-10). Each writeup uses a consistent template and includes:
- what the bug is
- how to exploit it (against the included challenge only)
- how to fix it

Every writeup has a companion intentionally vulnerable challenge under `challenges/` and a matching exploit/solver under `exploits/`.

## Writeups Index

| # | Title | Difficulty | Tags | Writeup | Challenge | Exploit |
|---|-------|------------|------|---------|-----------|---------|
| 1 | Web: Cookie Smith | Medium | `auth`, `cookies`, `sha1`, `length-extension` | [web-cookie-smith.md](web-cookie-smith.md) | [app.py](challenges/web-cookie-smith/app.py) | [exploit_cookie_smith.py](exploits/exploit_cookie_smith.py) |
| 2 | Web: SQLi in Search | Easy | `sqli`, `sqlite`, `union-select` | [web-sqli-search.md](web-sqli-search.md) | [app.py](challenges/web-sqli-search/app.py) | [exploit_sqli_search.py](exploits/exploit_sqli_search.py) |
| 3 | Pwn: Stack Canary Slip | Medium | `format-string`, `stack-canary`, `ret2win` | [pwn-stack-canary-slip.md](pwn-stack-canary-slip.md) | [vuln.c](challenges/pwn-stack-canary/vuln.c) | [exploit_stack_canary.py](exploits/exploit_stack_canary.py) |
| 4 | Pwn: Off-by-One ROP | Hard | `off-by-one`, `stack-pivot`, `leave-ret` | [pwn-off-by-one-rop.md](pwn-off-by-one-rop.md) | [vuln.c](challenges/pwn-off-by-one-rop/vuln.c) | [exploit_off_by_one.py](exploits/exploit_off_by_one.py) |
| 5 | Crypto: Reused Nonce (AES-CTR) | Easy | `aes-ctr`, `nonce-reuse`, `xor` | [crypto-reused-iv.md](crypto-reused-iv.md) | [server.py](challenges/crypto-reused-iv/server.py) | [exploit_reused_iv.py](exploits/exploit_reused_iv.py) |
| 6 | Forensics: Hidden in PDF | Easy | `pdf`, `attachments`, `pypdf` | [forensics-hidden-pdf.md](forensics-hidden-pdf.md) | [create_challenge.py](challenges/forensics-hidden-pdf/create_challenge.py) | [extract_pdf_flag.py](exploits/extract_pdf_flag.py) |
| 7 | Reversing: Flag Check | Easy | `xor`, `static-data`, `solver` | [rev-flag-check.md](rev-flag-check.md) | [flag_check.py](challenges/rev-flag-check/flag_check.py) | [solve_flag_check.py](exploits/solve_flag_check.py) |

## Repository Layout

```
ctf-writeups/
|-- *.md                      # writeups (one per challenge)
|-- challenges/
|   |-- web-cookie-smith/     # Flask app: SHA-1 length extension cookie forge
|   |-- web-sqli-search/      # Flask + SQLite: UNION injection
|   |-- crypto-reused-iv/     # Flask AES-CTR server with fixed nonce
|   |-- rev-flag-check/       # XOR flag checker (simulated binary)
|   |-- pwn-stack-canary/     # C: format-string canary leak + gets() overflow
|   |-- pwn-off-by-one-rop/   # C: off-by-one saved-RBP overwrite + pivot
|   `-- forensics-hidden-pdf/ # PDF with embedded flag.txt attachment
|-- exploits/
|   |-- exploit_cookie_smith.py
|   |-- exploit_sqli_search.py
|   |-- exploit_reused_iv.py
|   |-- solve_flag_check.py
|   |-- extract_pdf_flag.py
|   |-- exploit_stack_canary.py   # Linux/WSL
|   `-- exploit_off_by_one.py     # Linux/WSL
|-- scripts/
|   |-- test.ps1
|   `-- build_pdf.ps1
|-- tests/
|   `-- Writeups.Tests.ps1
`-- dist/
    `-- CTF-Writeups.pdf
```

## Setup

Python is only required to run the challenges and exploits. The tests and PDF bundling scripts are PowerShell-only.

```bash
python -m venv .venv
# Windows:  .venv\Scripts\activate
# Linux:    source .venv/bin/activate

pip install flask pycryptodome pypdf fpdf2 requests
# Linux/WSL pwn exploits also need: pip install pwntools
```

## Running a Challenge

```bash
# Web / Crypto challenges (Flask)
python challenges/web-cookie-smith/app.py      # http://localhost:5001
python challenges/web-sqli-search/app.py       # http://localhost:5002
python challenges/crypto-reused-iv/server.py   # http://localhost:5003

# Reversing (no server needed)
python challenges/rev-flag-check/flag_check.py

# Forensics (regenerates challenge.pdf)
python challenges/forensics-hidden-pdf/create_challenge.py

# Pwn (Linux/WSL only)
make -C challenges/pwn-stack-canary/
make -C challenges/pwn-off-by-one-rop/
```

## Running an Exploit

```bash
python exploits/exploit_cookie_smith.py    # requires web-cookie-smith running
python exploits/exploit_sqli_search.py     # requires web-sqli-search running
python exploits/exploit_reused_iv.py       # requires crypto-reused-iv running
python exploits/solve_flag_check.py        # standalone
python exploits/extract_pdf_flag.py        # requires challenge.pdf to exist
# Linux/WSL only:
python exploits/exploit_stack_canary.py
python exploits/exploit_off_by_one.py
```

## Testing (CI-Style Checks)

The checks validate:
- writeup template header/footer presence
- index table matches actual writeup files
- difficulty and tags are present for each entry

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test.ps1
# Or (PowerShell 7+):
# pwsh -File scripts/test.ps1
```

## PDF Bundle

Generate a single PDF containing all writeups:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_pdf.ps1
# Or (PowerShell 7+):
# pwsh -File scripts/build_pdf.ps1
```

Output: `dist/CTF-Writeups.pdf`

## Ethics and Safe Use
- The challenges here are intentionally vulnerable for local practice.
- Only run exploits against these included challenges or targets you own / have explicit permission to test.
