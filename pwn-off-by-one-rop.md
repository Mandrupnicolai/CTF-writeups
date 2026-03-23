---
title: "Off-by-One ROP"
category: "Pwn"
difficulty: "Hard"
tags: ["off-by-one", "stack-pivot", "leave-ret", "ret2win"]
challenge: "challenges/pwn-off-by-one-rop/vuln.c"
exploit: "exploits/exploit_off_by_one.py"
last_updated: "2026-03-23"
---

# Pwn: Off-by-One ROP

## Summary
Abuse a 1-byte overflow to corrupt the least significant byte (LSB) of saved `RBP`, then pivot the stack into attacker-controlled data and return into `win()`.

## Challenge
- Bug: `read(STDIN, buf, 129)` reads up to 129 bytes into a 128-byte buffer.
- Impact: byte index 128 overwrites the first byte of saved `RBP` (on x86-64, little-endian).
- Mitigations: stack protector is disabled here (`-fno-stack-protector`) to keep focus on the pivot.

## Solution
### Why the LSB matters
If we can nudge saved `RBP` to point into our buffer, the function epilogue (`leave; ret`) effectively does:
- `leave`: `RSP = RBP; RBP = [RSP]`
- `ret`: `RIP = [RSP+8]`

So if `RSP` is pivoted into our buffer, we control the return target.

### Steps
1. Place a fake stack frame at the start of `buf`:
   - fake `RBP` (8 bytes)
   - fake `RIP` (8 bytes) set to `win()`
2. Send 129 bytes so the final byte overwrites the LSB of saved `RBP` and points it into `buf`.
3. Let the function return; execution reaches `win()`.

## Reproduction
This challenge is intended for Linux (or WSL).
1. Build: `make -C challenges/pwn-off-by-one-rop/`
2. Run the exploit: `python exploits/exploit_off_by_one.py`

## Flag
`flag{off_by_one_stack_pivot}`

## Mitigation
- Use correct bounds (`read(..., sizeof(buf))`) and always check return values.
- Keep hardening on (PIE, RELRO, stack protector) in real applications; it raises the bar substantially.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

