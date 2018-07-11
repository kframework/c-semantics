#include <stdio.h>

int main(void) {
      int buf[5] = {0};
      for (int i = 5, j = 0; buf[i] == 0 && j != 5; i++, j++) {
            printf("%d\n", i);
      }
}
