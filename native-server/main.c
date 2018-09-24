#include<stdio.h>

#include "server.h"

int main(int argc, char **argv) {
  if (argc != 3) {
    printf("usage: %s read_pipe write_pipe\n", argv[0]);
    return 1;
  }

  __server(argv[1], argv[2]);
  return 0;
}
