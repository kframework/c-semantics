#ifndef _KCC_STDDEF_H
#define _KCC_STDDEF_H

typedef long int ptrdiff_t;
typedef unsigned int size_t;
typedef char max_align_t;
typedef int wchar_t;

#define NULL ((void *) 0)
#define offsetof(t, m) __kcc_offsetof(t, m)

#endif
