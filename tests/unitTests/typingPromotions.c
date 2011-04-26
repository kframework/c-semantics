#include <stdio.h>

int main(void){
	printf("%d\n", sizeof(char));
	printf("%d\n", sizeof(int));
	printf("%d\n", sizeof((char)0 + (char)0));
	printf("%d\n", sizeof((char)0));
	printf("%d\n", sizeof(-(char)0));
	printf("%d\n", sizeof(+(char)0));
	printf("%d\n", (char)127 + (char)127 + (char)127);
}
