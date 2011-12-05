#include <stdlib.h>
int main(void){
	char* p = realloc(0, 5);
	p[3] = 'd';
	return p[3];
}
