#include <stdio.h>


int main() {
      printf("------------------------\n");
			unsigned int c = 7;
      printf("Unsigned 1: |%.u|\n", (unsigned)42);
      printf("Unsigned 2: |%u|\n", c);
      printf("Unsigned 3: |%0u|\n", c);
      printf("Unsigned 4: |%04u|\n", c);
      printf("Unsigned 5: |%-4u|\n", c);
      printf("Unsigned 6: |%15u|\n", c);
      printf("Unsigned 7: |%15.4u|\n", c);
      printf("Unsigned 8: |%015u|\n", c);
      printf("Unsigned 9: |%15.0u|\n", (unsigned)0);
      printf("Unsigned 9: |%15.2u|\n", (unsigned)0);
      printf("------------------------\n");
}
