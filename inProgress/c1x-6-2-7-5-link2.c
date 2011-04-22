#include <stdio.h>
char y = 5;
int f(int (*a)(char *), double (*b)[3]){ // same as this
	printf("sizeof(b) = %d\n", sizeof(*b) / sizeof((*b)[0]));
	printf("a(&y) = %d\n", a(&y));
	for (int i = 0; i < 3; i++){
		printf("%d\n", (int)(1000*((*b)[i])));
	}
	return 0;
}

