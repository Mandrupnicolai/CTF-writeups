/*
 * CTF Challenge: Stack Canary Slip
 *
 * Vulnerabilities:
 *   1) printf(buf)  — format string: leaks stack values including canary
 *   2) gets(buf)    — unbounded read: smashes canary+RIP once canary is known
 *
 * Stack layout (64-bit, approx):
 *   [buf 64B][canary 8B][saved RBP 8B][saved RIP 8B]
 *
 * Exploit steps:
 *   1. Leak canary:  send "%<n>$p" until you see the canary (ends in 00).
 *   2. Build payload: 'A'*64 + canary + 'B'*8 + addr(win)
 *   3. Trigger gets() overflow → win() executes → flag printed.
 *
 * Build (Linux):
 *   gcc -fstack-protector -no-pie -o vuln vuln.c
 *   # Use -m32 for 32-bit layout matching the writeup
 *
 * INTENTIONALLY VULNERABLE — for CTF/educational use only.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char FLAG[] = "flag{canary_leak_then_smash}";

void win(void) {
    puts(FLAG);
    exit(0);
}

void vuln(void) {
    char buf[64];

    /* Phase 1: format string leak */
    printf("Prompt> ");
    fflush(stdout);
    fgets(buf, sizeof(buf), stdin);
    buf[strcspn(buf, "\n")] = '\0';
    printf(buf);          /* VULNERABLE: format string — no "%s" wrapper */
    fputc('\n', stdout);
    fflush(stdout);

    /* Phase 2: unbounded overflow */
    printf("Input> ");
    fflush(stdout);
    gets(buf);            /* VULNERABLE: no length check */
}

int main(void) {
    setbuf(stdout, NULL);
    /*
     * Canary is at a predictable offset from buf on the stack.
     * Typical offset for "%p" leak: fuzz with %1$p, %2$p, … until you
     * see a value ending in 0x00 (canary always has a null LSB).
     */
    vuln();
    return 0;
}
