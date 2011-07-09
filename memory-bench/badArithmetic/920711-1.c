#include <stdlib.h>
int f(long a){return (--a > 0);}
int main(){if(f(0x80000000L)==0)abort();exit(0);}
