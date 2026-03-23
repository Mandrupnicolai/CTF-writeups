---
title: "Flag Check"
category: "Reversing"
difficulty: "Easy"
tags: ["xor", "static-data", "rodata", "solver"]
challenge: "challenges/rev-flag-check/flag_check.py"
exploit: "exploits/solve_flag_check.py"
last_updated: "2026-03-23"
---

# Reversing: Flag Check

## Summary
Recover the expected flag by reversing a simple XOR-based check that compares input bytes against static arrays.

## Challenge
The checker validates:
`ord(flag[i]) XOR KEY[i] == TARGET[i]`

Both `KEY` and `TARGET` are static, so the flag can be derived offline:
`flag[i] = KEY[i] XOR TARGET[i]`

## Solution
### Steps
1. Extract `KEY` and `TARGET` from the binary (or, in this repo, from `flag_check.py`).
2. Compute each flag byte as `KEY[i] XOR TARGET[i]`.
3. Print the reconstructed string.

## Reproduction
1. Run the solver: `python exploits/solve_flag_check.py`
2. (Optional) Verify: `python challenges/rev-flag-check/flag_check.py` and paste the output.

## Flag
`flag{xor_is_not_crypto}`

## Mitigation
- Do not embed secrets in client-side binaries if the attacker controls execution.
- Move validation and secrets server-side, or use a design that remains secure under reverse engineering.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

