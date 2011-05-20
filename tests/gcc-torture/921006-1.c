void exit(int status);
void abort(void);
#include <string.h>
/* REPRODUCED:RUN:SIGNAL MACHINE:i386 OPTIONS:-O */
main()
{
if(strcmp("X","")<0)abort();
exit(0);
}
