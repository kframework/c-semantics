#ifndef _KCC_STDDEF_H
#define _KCC_STDDEF_H
#include <kcc_settings.h>

typedef _KCC_PTRDIFF_T ptrdiff_t;
typedef _KCC_SIZE_T size_t;
typedef char max_align_t;
typedef _KCC_WCHAR_T wchar_t;

#define NULL _KCC_NULL
#define offsetof(t, m) __kcc_offsetof(t, m)

#endif
