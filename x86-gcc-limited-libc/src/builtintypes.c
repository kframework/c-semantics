#define _KCC_EXPERIMENTAL_LOCALE
#include <threads.h>
#include <stdio.h>
#include <locale.h>

mtx_t __typeref_mtx_t; // bogus but needed by semantics. Not used since profile does not contain thread.h
FILE __typeref_file;
fpos_t __typeref_fpos_t;
struct lconv __typeref_lconv;
