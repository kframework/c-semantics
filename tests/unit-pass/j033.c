#include <stdio.h>

int main(void){
      char a[] = "hello";
      a[0] = 'x';

      char (*b)[6];
      b = &"hello";
      (*b)[0];

      char c[] = "hello\n";
      c[0] = 'x';
      printf("hello\n");

      return 0;
}
