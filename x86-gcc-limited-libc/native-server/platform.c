#include<errno.h>
#include<stdlib.h>
#include<stdio.h>
#include<string.h>

#include "platform.h"

static FILE *write_file, *read_file;

void __init_messages(const char *read_path, const char *write_path) {
  write_file = fopen(write_path, "w");
  if (!write_file) {
    int err = errno;
    char *str = strerror(err);
    printf("opening write pipe failed: %s\n", str);
    abort();
  }
  read_file = fopen(read_path, "r");
  if (!read_file) {
    int err = errno;
    char *str = strerror(err);
    printf("opening read pipe failed: %s\n", str);
    abort();
  }
}

void __send_message(void *buf, size_t len) {
  fwrite(buf, 1, len, write_file);
  if (ferror(write_file)) {
    printf("writing bytes to pipe failed\n");
    abort();
  }
}

void __recv_message(void *buf, size_t len) {
  fread(buf, 1, len, read_file);
  if (ferror(read_file)) {
    printf("reading bytes from pipe failed\n");
    abort();
  }
}

void __deinit_messages(void) {
  if (fclose(write_file)) {
    int err = errno;
    char *str = strerror(err);
    printf("closing write pipe failed: %s\n", str);
    abort();
  }
  if (fclose(read_file)) {
    int err = errno;
    char *str = strerror(err);
    printf("closing read pipe failed: %s\n", str);
    abort();
  }
}

void __flush_message(void) {
  if (fflush(write_file)) {
    int err = errno;
    char *str = strerror(err);
    printf("flushing write pipe failed: %s\n", str);
    abort();
  }
}

void __error(char *msg) {
  printf("%s\n", msg);
  abort();
}

void *__alloc(size_t size) {
  return calloc(1, size);
}
