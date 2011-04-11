#include <stdio.h>

struct S {
	int a;
	int b[2];
};

struct S s = {1, {2, 3}};
static struct S f(void) {
	return s;
}
int main(void){
	printf("%d\n", f().a);
	printf("%d\n", f().b[0]);
	return 0;
}
