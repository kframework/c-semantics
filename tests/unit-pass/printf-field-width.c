#include <stdio.h>


int main() {
      printf("------------------------\n");
      printf("Int 1: |%d|\n", 123);
      printf("Int 2: |%0d|\n", 123);
      printf("Int 3: |%15d|\n", 123);
      printf("Int 4: |%-15d|\n", 123);
      printf("Int 5: |%15.2d|\n", 123);
      printf("Int 6: |%-15.2d|\n", 123);
      printf("Int 7: |%015d|\n", 123);
      printf("Int 8: |%0-15d|\n", 123);
      printf("Int 9: |%0-15.2d|\n", 123);
      printf("------------------------\n");
}
