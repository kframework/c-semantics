#ifndef _KCC_STRING_H
#define _KCC_STRING_H
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

size_t strlen(const char *str);
int strcmp(const char *str1, const char *str2);
char *strcpy(char * __restrict__ s1, const char * __restrict__ s2);
char *strncpy(char *__restrict__ dest, const char *__restrict__ src, size_t n);
char *strcat(char *__restrict__ dest, const char *__restrict__ src);
char *strncat(char *__restrict__ s1, const char *__restrict__ s2, size_t n);
char *strchr(const char *s, int c);
void *memset(void *ptr, int value, size_t num );
void *memcpy(void *__restrict__ destination, const void *__restrict__ source, size_t num );
void *memmove(void *s1, const void *s2, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
void *memchr(const void *s, int c, size_t n);
char *strrchr(const char *, int );
int strncmp(const char *s1, const char *s2, size_t n);
size_t strcspn(const char *s1, const char *s2);
char *strpbrk(const char *s1, const char *s2);
size_t strspn(const char *s1, const char *s2);
char *strstr(const char *haystack, const char *needle);
char *strtok(char *__restrict__ s1, const char *__restrict__ delimiters);
char *strtok_r(char *__restrict__ s, const char *__restrict__ delimiters, char **__restrict__ lasts);

#ifdef __cplusplus
}
#endif

#endif
