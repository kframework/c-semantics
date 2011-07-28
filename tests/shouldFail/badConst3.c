// kcc-assert-error(00035)
#include <stdlib.h>
int main(void) {
	const int a[2] = {1, 2};
	a[0] = 0;
	return a[0];
}
