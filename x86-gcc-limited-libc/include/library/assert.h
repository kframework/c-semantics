/* assert() should be redefined each time this header is included. */
#undef assert
#if defined NDEBUG
#define assert(ignore) ((void)0)
#else
int printf(const char * restrict format, ...);
void abort(void);
#define assert(test) ((!(test)) ? (printf("Assertion failed: `%s', file %s, line %u\n", #test, (__FILE__), (__LINE__)), abort()) : (void)0)
#endif

#define static_assert _Static_assert
