// based on example by Derek Jones

#include <stdio.h>
#include <stddef.h>

int g(int v) {
	return 0;
}

struct s {
	int (*f1)(int);
	int (*f2)(int);
} x;

int (**pf)(int);

int main(void) {
	x.f2 = g;
	pf = &x.f1;
	pf = (int (**)(int))((char*)pf + offsetof(struct s, f2));
	(**pf)(2);
}
