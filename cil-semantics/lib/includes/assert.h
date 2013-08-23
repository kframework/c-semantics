// #ifndef _KCC_ASSERT_H // these can't be here since assert is supposed to be redefined each time it is included
// #define _KCC_ASSERT_H
#include <kcc_settings.h>

#undef assert
#if defined NDEBUG
#define assert(ignore) ((void)0)
#else
int printf(const char * restrict format, ...);
void abort(void);
#define assert(test) ((!(test)) ? (printf("Assertion failed: `%s', file %s, line %u\n", #test, (__FILE__), (__LINE__)), abort()) : (void)0)
#endif

#define static_assert _Static_assert

// #endif
