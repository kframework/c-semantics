#include <stdio.h>
int f(int a[]);
int main(void){
	int x[5] = {1, 2, 3};
	
	return f(x);
}
int f(int a[5]) {
	printf("sizeof(a)=%d\n", (int)sizeof(a));
	return a[1];
}


