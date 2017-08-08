#include<stdlib.h>
#include<stdio.h>
#include<stdint.h>

int main(int argc, char **argv) {
  long long ll = atoll(argv[1]);
  int64_t i64 = (int64_t)ll;
  fwrite(&i64, 8, 1, stdout);
}
