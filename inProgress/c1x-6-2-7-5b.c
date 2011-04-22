#include <stdio.h>

int f(int (*)(), double (*)[3]);

char y = 5;
int f(int (*a)(char *), double (*b)[]){ // same as this
	printf("sizeof(b) = %d\n", sizeof(*b) / sizeof((*b)[0]));
	printf("a(&y) = %d\n", a(&y));
	for (int i = 0; i < 3; i++){
		printf("%d\n", (int)(1000*((*b)[i])));
	}
	return 0;
}


int g(char* x) {
	printf("in g\n");
	printf("%d\n", *x);
	return *x;
}

int main(void) {
	double (*p)[3]; // A pointer to an array of doubles
	double arr[3] = {1.8, 2.7, 3.6};
	p = &arr;
	return f(&g, p);
}
