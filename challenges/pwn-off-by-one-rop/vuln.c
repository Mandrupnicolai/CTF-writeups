/*
 * CTF Challenge: Off-by-One ROP
 *
 * Vulnerability:
 *   read() accepts up to 129 bytes into a 128-byte buffer.
 *   The extra byte (index 128) overwrites the least-significant byte (LSB)
 *   of the saved RBP on the stack.
 *
 * Exploit (stack pivot via leave; ret):
 *   1. Place a fake stack frame + ROP chain at the start of buf.
 *   2. Overwrite LSB of saved RBP so it points into buf.
 *   3. Function epilogue:  "leave" sets RSP = RBP, then "ret" jumps to
 *      the address in the fake frame → ROP chain executes win().
 *
 * Build (Linux, 64-bit):
 *   gcc -fno-stack-protector -no-pie -o vuln vuln.c
 *
 * INTENTIONALLY VULNERABLE — for CTF/educational use only.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static const char FLAG[] = "flag{off_by_one_stack_pivot}";

void win(void) {
    puts(FLAG);
    exit(0);
}

void vuln(void) {
    char buf[128];

    printf("Input: ");
    fflush(stdout);

    /* BUG: limit is 129 instead of 128 — off-by-one overwrites LSB of saved RBP */
    ssize_t n = read(STDIN_FILENO, buf, 129);
    if (n > 0)
        write(STDOUT_FILENO, buf, (size_t)n);
}

int main(void) {
    setbuf(stdout, NULL);
    /*
     * Stack layout (inside vuln, 64-bit):
     *   [buf 128B][saved RBP 8B][saved RIP 8B]
     *   index 128 → first byte of saved RBP (the LSB on little-endian x86-64)
     *
     * To exploit:
     *   - Fill buf[0..7]  with fake RBP  (ignored on pivot).
     *   - Fill buf[8..15] with addr(win) — executed when epilogue ret fires.
     *   - Fill buf[16..127] with padding.
     *   - Set buf[128] to the new LSB that redirects saved RBP into buf.
     */
    vuln();
    return 0;
}
