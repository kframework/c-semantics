#include <stdlib.h>
int main(void){
	char* p1 = malloc(5);
	p1[0] = 'd';
	p1[4] = 'a';
	char* p2 = realloc(p1, 2);
	return p2[0];
}
