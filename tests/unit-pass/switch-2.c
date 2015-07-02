#include<stdlib.h>

int main() {
  switch (2) {
  case 1+1:
    return 0;
  default:
    abort();
  }
}
