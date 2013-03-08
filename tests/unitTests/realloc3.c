#include <stdlib.h>
int main(void){
	char* p1 = malloc(5);
	p1[3] = 'd';
	char* p2 = realloc(p1, 10);
	return p2[3];
}
