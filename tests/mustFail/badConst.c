// kcc-assert-error(00035)
#include <stdio.h>

#ifndef OMITGOOD
int good(void){
	const int x = 0;
	return x;
}
#endif

#ifndef OMITBAD
int bad(void){
	const int x = 0;
	x = 5;
	return x;
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
