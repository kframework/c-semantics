// taken from c1x n1570, 6.7.2.1:19
#include <stdio.h>

struct v {
	struct { long k, l; } w;
	int m;
} v1;

int main(void){
	// v1.i = 2;
	// printf("%d\n", v1.i);
	v1.k = 3; // invalid: inner structure is not anonymous
	printf("%d\n", v1.k);
	// v1.w.k = 5;
	// printf("%d\n", v1.w.k);
	return 0;
}
