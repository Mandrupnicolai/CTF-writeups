# Build on Linux:
#   make

CC     = gcc
CFLAGS = -fno-stack-protector -no-pie -Wall

all: vuln

vuln: vuln.c
	$(CC) $(CFLAGS) -o vuln vuln.c

clean:
	rm -f vuln
