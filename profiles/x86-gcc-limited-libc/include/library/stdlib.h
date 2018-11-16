#ifndef _KCC_STDLIB_H
#define _KCC_STDLIB_H
#include <stddef.h>

#define EXIT_FAILURE 1
#define EXIT_SUCCESS 0
#define RAND_MAX 2147483647
typedef struct div_t_ {int quot; int rem;} div_t;
typedef struct ldiv_t_ {long int quot; long int rem;} ldiv_t;

#ifdef __cplusplus
extern "C" {
#endif

void *malloc(size_t size);
void *realloc(void *ptr, size_t size);
void free(void *pointer);
void *calloc(size_t nelem, size_t elsize);
_Noreturn void exit(int status);
_Noreturn void quick_exit(int status);
void __debug(int i);
void srand (unsigned int seed);
int rand (void);
_Noreturn void abort(void);
int atoi (const char * str);
int atexit(void (*func)(void));
int at_quick_exit(void (*func)(void));

#ifdef __cplusplus
}
#endif

#endif
