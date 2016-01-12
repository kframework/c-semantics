#include<stdio.h>

static char FILE_VERSION[32] = "\0";
extern char dns_major[];
extern char dns_mapapi[];

int main() {
  snprintf(FILE_VERSION, sizeof(FILE_VERSION),
    "RBT Image %s %s", dns_major, dns_mapapi);
  printf("%s\n", FILE_VERSION);
}
