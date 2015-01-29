#include <limits.h>
int f(int x){
      return x;
}
int main(void){
      signed char x;
      double y = CHAR_MAX;
      x = y;

      unsigned char a;
      float b = UCHAR_MAX;
      a = b;

      f(INT_MAX);
      return 0;
}
