
#include <stdio.h>

void printfn(int a, short b, double C, float D, signed char E, char F, void *G, double *H, int I, long long J) {
	printf("%d, %d, %d, %d, %d\n", a, b, (int)(100*C), (int)(100*D), E);
	printf("%d, %ld, %d, %d, %lld\n", F, (long)*(int*)G, H==0, I, J);
}

int main() {
	int x = 5;
	printfn(12, 2, 123.234, 1231.12312f, -12, 23, (void*)&x, 0, 1234567, 123124124124LL);
	return 0;
}
