// kcc-assert-error(00035)
#include <stdio.h>

#ifndef OMITGOOD
int good(void){
	const int a[2] = {1, 2};
	return a[0];
}
#endif

#ifndef OMITBAD
int bad(void){
	const int a[2] = {1, 2};
	a[0] = 0;
	return a[0];
}
#endif

int main(void){
#ifndef OMITGOOD
	printf("Calling good()...\n");
	good();
	printf("Finished good()\n");
#endif
#ifndef OMITBAD
	printf("Calling bad()...\n");
	bad();
	printf("Calling bad()...\n");
#endif
	return 0;
}
