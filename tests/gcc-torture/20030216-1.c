#include <stdlib.h>
void link_error (void);
const double one=1.0;
int main ()
{
#ifdef __OPTIMIZE__
  if ((int) one != 1)
    link_error ();
#endif
  return 0;
}
