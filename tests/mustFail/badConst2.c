// kcc-assert-error(00035)
#include <stdio.h>

#ifndef OMITGOOD
int good(void){
	int x = 5;
	int y = 0;
	const int* p = &x;
	return *p;
}
#endif

#ifndef OMITBAD
int bad(void){
	int x = 5;
	int y = 0;
	const int* p = &x;
	*p = &y;
	return *p;
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
