---
title: "Stack Canary Slip"
category: "Pwn"
difficulty: "Medium"
tags: ["format-string", "stack-canary", "ret2win", "buffer-overflow"]
challenge: "challenges/pwn-stack-canary/vuln.c"
exploit: "exploits/exploit_stack_canary.py"
last_updated: "2026-03-23"
---

# Pwn: Stack Canary Slip

## Summary
Leak a stack canary via a format string bug, then reuse it to bypass stack protector and redirect execution to `win()`.

## Challenge
- Vulnerabilities (in `vuln()`):
  - `printf(buf)` format string (stack leak)
  - `gets(buf)` buffer overflow
- Mitigation present: stack canary (`-fstack-protector`)
- Win condition: call `win()` which prints `flag{canary_leak_then_smash}` and exits.

## Solution
### High level
1. Use the format string to leak the canary value from the stack.
2. Overflow the buffer again, but include the exact canary bytes so the check passes.
3. Overwrite the saved return address with the address of `win()`.

### Notes on offsets
The correct `%n$p` offset for the canary is environment- and build-dependent. The intended workflow is to fuzz offsets until you see a value that ends with `00` (canaries typically have a null least significant byte).

## Reproduction
This challenge is intended for Linux (or WSL).
1. Build: `make -C challenges/pwn-stack-canary/`
2. Run the exploit: `python exploits/exploit_stack_canary.py`

## Flag
`flag{canary_leak_then_smash}`

## Mitigation
- Never pass user input as a format string: use `printf("%s", buf)`.
- Avoid unsafe input APIs like `gets()`: use `fgets()` with bounds.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

