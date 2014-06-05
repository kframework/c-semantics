#include <stdlib.h>

int main(void){
      int* p;
      {
            int x = 5;
            p = &x;
      } // the memory for x should not be accessible now

      int y = 0;

      {
            int y = 5;
      }
      y;

      p = malloc(sizeof(int));
      *p = 5;
      free(p);

      int* q;
      {
            int x;
            q = &x;
      }

      return 0;
}
