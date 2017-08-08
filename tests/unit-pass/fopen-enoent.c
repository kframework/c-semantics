#include<stdio.h>
#include<errno.h>
#include<stdlib.h>
#include<string.h>

int main() {
  FILE *in = fopen("nonexistent", "r");
  int err = errno;
  if(in != NULL) abort();
  printf("%s\n", strerror(err));
}
