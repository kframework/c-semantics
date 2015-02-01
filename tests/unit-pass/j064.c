#include <string.h>

int main(void){
      const int x = 0;
      const int* p = &x;

      const char q[] = "hello";
      char *r = strchr(q, q[0]);
      r[0];

      return x;
}
