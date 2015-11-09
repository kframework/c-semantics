#include <stdio.h>

int main(void) {
      int buf[5] = {0};
      for (int i = 5; buf[i] == 0; i++) {
            printf("%d\n", i);
      }
}
