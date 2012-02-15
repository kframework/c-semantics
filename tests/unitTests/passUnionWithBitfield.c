#include <stdio.h>

union U1 {
	signed a:13;
} u1 = {123};
union U1 f1(union U1 u) { return u; }

union U2 {
	signed a:13;
	unsigned char b;
} u2 = {123};
union U2 f2(union U2 u) { return u; }

union U3 {
	signed a:13;
	int b;
} u3 = {123};
union U3 f3(union U3 u) { return u; }

int main (void) {
	printf("%d\n", f1(u1).a);
	printf("%d\n", f2(u2).a);
	printf("%d\n", f3(u3).a);
}
