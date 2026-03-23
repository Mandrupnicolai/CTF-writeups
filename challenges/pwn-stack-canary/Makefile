# Build on Linux:
#   make        — default 64-bit build
#   make 32bit  — 32-bit build (requires gcc-multilib)

CC      = gcc
CFLAGS  = -fstack-protector -no-pie -Wall

all: vuln

vuln: vuln.c
	$(CC) $(CFLAGS) -o vuln vuln.c

32bit: vuln.c
	$(CC) $(CFLAGS) -m32 -o vuln32 vuln.c

clean:
	rm -f vuln vuln32
