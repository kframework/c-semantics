#include <stdio.h>
int main(void){
	int x = 5;
	int a[x];
	int b[x][x];
	int n = 2;
	int size;
	printf("%d should be %d\n", (int)(sizeof(a)/sizeof(a[0])), x);
	printf("n is %d\n", n);
	size = sizeof(b[n++]);
	printf("n is now %d\n", n);
	printf("%d should be %d\n", (int)(sizeof(b)/sizeof(b[n++])), x+1);
	printf("n is now %d\n", n);
	
	printf("sizeof(int[n]) = %d\n", (int)sizeof(int[n++]));
	printf("n is now %d\n", n);
}
