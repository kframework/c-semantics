#include<threads.h>
#include<setjmp.h>

mtx_t __typeref_mtx_t; // bogus but needed by semantics. Not used since profile does not contain thread.h
struct __jmp_buf_tag __typeref_jmp_buf;
