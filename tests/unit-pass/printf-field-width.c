#include <stdio.h>


int main() {
      printf("------------------------\n");
      printf("Int -1: |%.d|\n", 0);
      printf("Int  0: |%.d|\n", 42);
      printf("Int  1: |%d|\n", 123);
      printf("Int  2: |%0d|\n", 123);
      printf("Int  3: |%15d|\n", 123);
      printf("Int  4: |%-15d|\n", 123);
      printf("Int  5: |%15.5d|\n", 123);
      printf("Int  6: |%-15.2d|\n", 123);
      printf("Int  7: |%015d|\n", 123);
//      printf("Int  8: |%015.0d|\n", 123);
      printf("Int  9: |%15.0d|\n", 0);
//      printf("Int 10: |%015.4d|\n", 0);
      printf("Int 11: |%0-15d|\n", 123);
      printf("Int 12: |%*.d|\n", 15, 123);
      printf("Int 13: |%.*d|\n", 15, 123);
      printf("------------------------\n");
}
