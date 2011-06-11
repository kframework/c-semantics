#include <stdlib.h>
extern void abort(void);
typedef void (*frob)(void);
frob f[] = {abort};
int main()
{
  exit(0);
}
