#include <stdio.h>

int main(void){
	char s[] = "hello\n";
	s[0] = 'x';
	printf("hello\n");
	return 0;
}
