#include <stdlib.h>
int main(void){
	return sizeof(sizeof(5)) == sizeof(size_t);
}

