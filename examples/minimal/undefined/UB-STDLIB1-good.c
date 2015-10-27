#include <stdlib.h>
int main(void){
	unsigned char a[5] = "abc";
	unsigned char* p = realloc(0, 5);
	p[0];
	return 0;
}
