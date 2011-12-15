// kcc-assert-error(00035)
#include <stdio.h>

int bad(void){
	int x = 5;
	int y = 0;
	const int* p = &x;
	*p = &y;
	return *p;
}
int main(void){
	bad();
	return 0;
}
