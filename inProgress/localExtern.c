#include <stdio.h>

extern int a[2] = {11, 12};

extern int x;
extern int y = 5;
extern int z;
extern int w = 6;
int main(void){
	extern int x[];
	extern int y;
	//extern int z = 8;
	printf("%d\n", a[1]);
	
	printf("%d\n", x);
	printf("%d\n", y);
	//printf("%d\n", z);
	printf("%d\n", w);
}
