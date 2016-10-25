#include<stdio.h>

int main() {
      int x = 5;
      {
foo:
            printf("%d", x);
            static int x = 1;
            if (x--) goto foo;
      }
}
