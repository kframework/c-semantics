#include <stdio.h>

#ifndef OMITGOOD
struct s {
	int x;
};
int good(void){
	return 0;
}
#endif

#ifndef OMITBAD
struct s {

};
int bad(void){
	return 0;
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
