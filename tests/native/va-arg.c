#include<stdio.h>

int main() {
  fprintf(stdout, "foo\n");
  fprintf(stdout, "%s", "foo\n");
  fprintf(stdout, "%s%s%s", "f", "o", "o\n");
  return 0;
}
