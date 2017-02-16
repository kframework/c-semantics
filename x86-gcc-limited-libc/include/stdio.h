#ifndef _KCC_STDIO_H
#define _KCC_STDIO_H
#include <kcc_settings.h>
#include <stddef.h>
#include <stdarg.h>

typedef ptrdiff_t FILE;

extern FILE* stdin;
extern FILE* stdout;
extern FILE* stderr;

// stdio.h
#define EOF -1
int putchar(int character);
int putc(int c, FILE *stream);
int getchar(void);
int printf(const char * restrict format, ...);
int fprintf(FILE * restrict stream, const char * restrict format, ...);
int sprintf(char * restrict s, const char * restrict format, ...);
int snprintf(char * restrict s, size_t n, const char * restrict format, ...);
int vsnprintf(char * restrict s, size_t n, const char * restrict format, va_list);
int puts(const char * str);

int getc(FILE *stream);
int feof(FILE * stream);
int ferror(FILE *stream);
void clearerr(FILE *stream);
FILE* fopen(const char * restrict filename, const char * restrict mode);
int fclose(FILE *stream);
int fgetc(FILE *stream);
int fputc(int c, FILE *stream);
char* fgets(char* restrict str, int size, FILE* restrict stream);

#endif
