#include <stdio.h>


int main() {
      printf("------------------------\n");
			unsigned int c = 12;
      printf("Hex 0: |%.x|\n", (unsigned)0);
      printf("Hex 1: |%x|\n", c);
      printf("Hex 2: |%0x|\n", c);
      printf("Hex 3: |%02x|\n", c);
      printf("Hex 3: |%-2x|\n", c);
      printf("Hex 4: |%15x|\n", c);
      printf("Hex 5: |%15.4x|\n", c);
      printf("Hex 6: |%015x|\n", c);
      printf("------------------------\n");
}
