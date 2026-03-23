#!/usr/bin/env python3
"""
CTF Challenge: Flag Check (Reversing)

Simulates a stripped binary that validates a flag via XOR comparison.
Static arrays KEY and TARGET are visible in .rodata (objdump / strings).

Disassembly pseudo-code:
    for i in range(len(KEY)):
        if input[i] ^ KEY[i] != TARGET[i]:
            print("Nope"); exit(1)
    print("Correct!")

Solver: flag[i] = KEY[i] ^ TARGET[i]  — see exploits/solve_flag_check.py
"""
import sys

# Visible in .rodata via:  objdump -s -j .rodata flag_check
KEY = bytes([
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
    0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50,
    0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
])  # b'ABCDEFGHIJKLMNOPQRSTUVW'  (23 bytes = len of flag)

TARGET = bytes([
    0x27, 0x2e, 0x22, 0x23, 0x3e, 0x3e, 0x28, 0x3a,
    0x16, 0x23, 0x38, 0x13, 0x23, 0x21, 0x3b, 0x0f,
    0x32, 0x20, 0x2a, 0x24, 0x21, 0x39, 0x2a,
])  # KEY[i] ^ TARGET[i] = flag[i]


def check_flag(flag: str) -> bool:
    if len(flag) != len(KEY):
        return False
    return all(ord(c) ^ k == t for c, k, t in zip(flag, KEY, TARGET))


def main():
    flag = input("Enter flag: ").strip()
    if check_flag(flag):
        print("Correct!")
    else:
        print("Nope")


if __name__ == "__main__":
    main()
