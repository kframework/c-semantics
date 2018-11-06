#define _KCC_EXPERIMENTAL_LOCALE
#include <threads.h>
#include <stdio.h>
#include <locale.h>
#include <setjmp.h>
#include <stdarg.h>

mtx_t __kcc_typeref_mtx_t; // bogus but needed by semantics. Not used since profile does not contain thread.h
FILE __kcc_typeref_file;
fpos_t __kcc_typeref_fpos_t;
struct lconv __kcc_typeref_lconv;
va_list __kcc_typeref_va_list;
jmp_buf __kcc_typeref_jmp_buf;

unsigned short __kcc_bswap16(unsigned short x) {
      return ((x & 0xfful) << 8) | ((x & 0xff00ul) >> 8);
}

unsigned int __kcc_bswap32(unsigned int x) {
      return ((x & 0xfful) << 24) | ((x & 0xff00ul) << 8)
            | ((x & 0xff0000ul) >> 8) | ((x & 0xff000000ul) >> 24); 
}

unsigned long int __kcc_bswap64(unsigned long int x) {
      return ((x & 0xffull) << 56) | ((x & 0xff00ull) << 40)
            | ((x & 0xff0000ull) << 24) | ((x & 0xff000000ull) << 8)
            | ((x & 0xff00000000ull) >> 8) | ((x & 0xff0000000000ull) >> 24)
            | ((x & 0xff000000000000ull) >> 40) | ((x & 0xff00000000000000ull) >> 56);
}
