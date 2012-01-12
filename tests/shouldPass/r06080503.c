#include <stdio.h>

int f1() {
	enum {a, b};
	{
		int i, j = b;
		printf("b=%d, j=%d\n", b, j);
		for (i = a; i < j; i += sizeof(enum {b, a}))
			//j += b;
			printf("b=%d, i=%d, j=%d\n", b, i, j += b);
	}
	return 0;
}

int f2() {
	enum {a, b}; 
	{
		int i, j = b; 
		printf("b=%d, j=%d\n", b, j);
		i = a;
		while (i < j) { 
			// j += b; // which b? 
			printf("b=%d, i=%d, j=%d\n", b, i, j += b);
			i += sizeof(enum {b, a}); // declaration of b moves 
		}
	}
	return 0;
}

int f3() {
	int i, j = 1;
	for (i = 0; i < j; i += sizeof(enum {b, a}))
		printf("b=%d, i=%d, j=%d\n", b, i, j += b);
	return 0;
}

int main(void){
	printf("test1:\n");
	f1();
	printf("test2:\n");
	f2();
	printf("test3:\n");
	f3();
}
