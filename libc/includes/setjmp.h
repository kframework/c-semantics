#ifndef _KCC_SETJMP_H
#define _KCC_SETJMP_H
#include <kcc_settings.h>

struct jmp_buf_ {
	unsigned char used;
};
typedef struct jmp_buf_ jmp_buf[1];
int setjmp(jmp_buf xxenv);
void longjmp(jmp_buf yyenv, int zzval);

#endif
