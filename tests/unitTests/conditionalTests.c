#include <limits.h>
#include <stdio.h>
struct S {
	int x;
	int y;
};

void f(){};

int main(void){
	struct S a = {1};
	struct S b = {2};
	struct S* p1 = &a;
	struct S* p2 = &b;


	printf("%d\n", INT_MAX + (0 ? (unsigned int) 1 : (int) 1));
	printf("%d\n", INT_MAX + (1 ? (int) 1 : (unsigned int) 1));
	printf("%d\n", (int)(100*(0 ? (double) 1.5 : (long double) 2.5)));
	printf("%d\n", (0 ? p1 : p2)->x);
	printf("%d\n", (1 ? *p1 : *p2).x);
	printf("%d\n", (0 ? &a : &b)->x);
	printf("%d\n", (1 ? a : b).x);
	(0 ? : (void)0);
	(0 ? (void)0 : f());
	(0 ? f() : (void)0);
}
