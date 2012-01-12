#include <stdio.h>

/* 
(n1570) 6.2.4:8
A non-lvalue expression with structure or union type, where the structure or union
contains a member with array type (including, recursively, members of all contained
structures and unions) refers to an object with automatic storage duration and temporary
lifetime.36)Its lifetime begins when the expression is evaluated and its initial value is the
value of the expression. Its lifetime ends when the evaluation of the containing full
expression or full declarator ends. Any attempt to modify an object with temporary
lifetime results in undefined behavior.
*/

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
	printf("%d\n", *(f().b + 0));
	printf("%d\n", *(f().b));
	return 0;
}
