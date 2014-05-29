#ifndef _KCC_STRING_H
#define _KCC_STRING_H
#include <kcc_settings.h>
#include <stddef.h>

// string.h
size_t strlen(const char *str);
int strcmp(const char *str1, const char *str2);
char *strcpy(char *s1, const char *s2);
char *strncpy(char *restrict dest, const char *restrict src, size_t n);
char *strcat(char *restrict dest, const char *restrict src);
char *strncat(char *restrict s1, const char *restrict s2, size_t n);
char *strchr(const char *s, int c);
void *memset(void *ptr, int value, size_t num );
void *memcpy(void *restrict destination, const void *restrict source, size_t num );
void *memmove(void *s1, const void *s2, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
void *memchr(const void *s, int c, size_t n);
char *strrchr(const char *, int );
int strncmp(const char *s1, const char *s2, size_t n);
size_t strcspn(const char *s1, const char *s2);
char *strpbrk(const char *s1, const char *s2);
size_t strspn(const char *s1, const char *s2);
char *strstr(const char *haystack, const char *needle);
char *strtok(char *restrict s1, const char *restrict delimiters);
char *strtok_r(char *restrict s, const char *restrict delimiters, char **restrict lasts);

#endif
