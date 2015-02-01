#include <stdio.h>

int bad(void){
	printf("%d", FOO);
	printf("%d", BAZ);
	printf("%d", BAR);
}

int main(void){
	bad();
	return 0;
}
