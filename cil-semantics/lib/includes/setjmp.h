#ifndef _KCC_SETJMP_H
#define _KCC_SETJMP_H
#include <kcc_settings.h>

struct __jmp_buf_tag {
	unsigned char used;
};
typedef struct __jmp_buf_tag jmp_buf[1];
int setjmp(jmp_buf xxenv);
void longjmp(jmp_buf yyenv, int zzval);

#endif
