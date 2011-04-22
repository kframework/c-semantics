#include <stdio.h>

int f(int (*)(), double (*)[3]);
int f(int (*)(char *), double (*)[]);

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
