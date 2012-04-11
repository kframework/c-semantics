// kcc-assert-error(00035)
#include <stdio.h>

int bad(void){
	const int a[2] = {1, 2};
	a[0] = 0;
	return a[0];
}
int main(void){
	bad();
	return 0;
}
