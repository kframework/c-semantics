#include <stdio.h>

struct v {
	struct { long k, l; } w;
	int m;
} v1;

int main(void){
	v1.w.k = 5;
	printf("%d\n", v1.w.k);
	return 0;
}
