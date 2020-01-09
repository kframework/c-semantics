/* assert() should be redefined each time this header is included. */
#undef assert
#if defined NDEBUG
#define assert(ignore) ((void)0)
#else

#ifdef __cplusplus
extern "C" {
#endif

int printf(const char * __restrict__ format, ...);
void abort(void);

#ifdef __cplusplus
}
#endif

#define assert(test) ((!(test)) ? (printf("Assertion failed: `%s', file %s, line %u\n", #test, (__FILE__), (__LINE__)), abort()) : (void)0)
#endif

#define static_assert _Static_assert
