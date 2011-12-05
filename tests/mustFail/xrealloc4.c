
#include <stdlib.h>
int main(void){
	char* p1 = malloc(5);
	p1[4] = 'd';
	char* p2 = realloc(p1, 3);
	return p2[4];
}
