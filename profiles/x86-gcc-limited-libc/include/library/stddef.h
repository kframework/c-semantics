#ifndef _KCC_STDDEF_H
#define _KCC_STDDEF_H

typedef long int ptrdiff_t;
typedef __kcc_size_t size_t;
typedef char max_align_t;

#ifndef __cplusplus
typedef int wchar_t;
#endif

#define NULL ((void *) 0)
#define offsetof(t, m) __kcc_offsetof(t, m)

#endif
