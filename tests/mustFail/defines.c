#include <stdio.h>

#ifndef OMITGOOD
int good(void){
	printf("%d", 0);
	printf("%d", 1);
	printf("%d", 2);
}
#endif

#ifndef OMITBAD
int bad(void){
	printf("%d", FOO);
	printf("%d", BAZ);
	printf("%d", BAR);
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
