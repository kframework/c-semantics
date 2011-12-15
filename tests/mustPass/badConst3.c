// kcc-assert-error(00035)
#include <stdio.h>

int good(void){
	const int a[2] = {1, 2};
	return a[0];
}
int main(void){
	good();
	return 0;
}
