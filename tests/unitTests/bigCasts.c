#include <limits.h>
#include <stdio.h>
int main(void){
	unsigned int a = (unsigned int)(2 * (unsigned long long)UINT_MAX + 3702);
	printf("%d\n", (int)a);
}

