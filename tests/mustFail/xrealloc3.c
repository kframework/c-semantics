#include <stdlib.h>
int main(void){
	char a[5] = "abc";
	char* p = realloc(a, 5);
	return p[0];
}
