#include <stdio.h>


int main() {
      printf("------------------------\n");
			int c = 42;
      printf("Oct 1: |%.o|\n", 0);
      printf("Oct 1: |%o|\n", c);
      printf("Oct 2: |%0o|\n", c);
      printf("Oct 4: |%-2o|\n", c);
      printf("Oct 3: |%08o|\n", c);
      printf("Oct 5: |%15o|\n", c);
      printf("Oct 6: |%15.4o|\n", c);
      printf("Oct 7: |%015o|\n", c);
      printf("------------------------\n");
}
