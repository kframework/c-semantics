#include<stdio.h>
#include<stdlib.h>

struct qsortArgs {
	int* b;
	int* e;
};

struct qsortArgs a1;
int a[] = {7, 5, 9, 10,};

int main(void) {
	a1 = (struct qsortArgs){a, a + sizeof(a) / sizeof(a[0])};
	for (int i = 0; i < sizeof(a) / sizeof(a[0]); i++) {
		printf("%d;", a[i]);
	}
	printf("\n");
	return 0;
}




