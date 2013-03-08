#include <stdlib.h>

int main(void){
	int *p = malloc(sizeof(int));
	*p = 5;
	free(p);
	*p;
	return 0;
}
