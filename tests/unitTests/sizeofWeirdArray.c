#include <stdio.h>

int main(void){
	int a[3];
	printf("%d\n", sizeof(a));
	printf("%d\n", sizeof(a[2]));
	printf("%d\n", sizeof(a)/sizeof(a[2]));
	printf("%d\n", sizeof(2[a]));
	printf("%d\n", sizeof(2 + &a[0]));
	printf("%d\n", sizeof(&a[0] + 2));
	printf("%d\n", sizeof(&a[1] - 1));
	printf("%d\n", sizeof(a - 1));
}
