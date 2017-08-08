#include <setjmp.h>
#include <stdio.h>

jmp_buf env;

void f(void) { longjmp(env, 0); }

int main(void) {
      f();
}
