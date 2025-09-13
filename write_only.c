// write_only.c
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
    const char *path = (argc > 1) ? argv[1] : "test_write_only.bin";
    const size_t N = 16 * 1024 * 1024; // 16 MiB
    char *buf = malloc(N);
    if (!buf) { perror("malloc"); return 1; }
    memset(buf, 'A', N);

    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) { perror("open"); return 1; }

    size_t off = 0;
    while (off < N) {
        ssize_t n = write(fd, buf + off, N - off);
        if (n < 0) { perror("write"); close(fd); return 1; }
        off += (size_t)n;
    }

    // No fsync here. Just close.
    if (close(fd) < 0) { perror("close"); return 1; }

    free(buf);
    return 0;
}

