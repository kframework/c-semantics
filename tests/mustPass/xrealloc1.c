#include <stdlib.h>
int main(void){
	char* p1 = malloc(5);
	p1[3] = 'd';
	char* p2 = realloc(p1, 5);
	p2[3];
	return 0;
}
