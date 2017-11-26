#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>

jmp_buf jb;

int* p;

int main(void) {
      if (setjmp(jb)) {
            *p;
      } else {
            int x = 1;
            p = &x;
            longjmp(jb, 2);
      }
}
