#include <stdlib.h>
int main(void){
	char a[5] = "abc";
	char* p = realloc(a, 5);
	p[0];
	return 0;
}
