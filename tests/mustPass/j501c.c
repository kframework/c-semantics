// kcc-assert-error(00035)
#include <stdio.h>

int good(void){
	int x = 5;
	int y = 0;
	const int* p = &x;
	return *p;
}

int main(void){
	good();
	return 0;
}
