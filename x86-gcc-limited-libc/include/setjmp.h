#ifndef _KCC_SETJMP_H
#define _KCC_SETJMP_H
#include <kcc_settings.h>
#include <stddef.h>

typedef ptrdiff_t jmp_buf[1];

#define setjmp(E) __setjmp(E)
int __setjmp(jmp_buf env);

_Noreturn void longjmp(jmp_buf env, int val);

#endif
