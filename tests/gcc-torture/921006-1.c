#include <string.h>
#include <stdlib.h>
/* REPRODUCED:RUN:SIGNAL MACHINE:i386 OPTIONS:-O */
int main()
{
if(strcmp("X","")<0)abort();
exit(0);
}
