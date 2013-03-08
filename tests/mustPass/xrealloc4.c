#include <stdlib.h>
int main(void){
	char* p1 = malloc(5);
	p1[4] = 'd';
	char* p2 = realloc(p1, 5);
	p2[4];
	return 0; 
}
