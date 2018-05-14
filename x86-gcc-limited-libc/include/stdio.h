#ifndef _KCC_STDIO_H
#define _KCC_STDIO_H
#include <stddef.h>
#include <stdarg.h>

typedef ptrdiff_t FILE;
typedef ptrdiff_t fpos_t;

extern FILE* stdin;
extern FILE* stdout;
extern FILE* stderr;

#define EOF -1

int fprintf(FILE * restrict stream, const char * restrict format, ...);
int printf(const char * restrict format, ...);
int snprintf(char * restrict s, size_t n, const char * restrict format, ...);
int sprintf(char * restrict s, const char * restrict format, ...);
int vprintf(const char * restrict format, va_list);
int vfprintf(FILE * restrict stream, const char * restrict format, va_list);
int vsnprintf(char * restrict s, size_t n, const char * restrict format, va_list);
int vsprintf(char * restrict s, const char * restrict format, va_list);

int fputc(int c, FILE *stream);
int fputs(const char * restrict str, FILE * restrict stream);
int putchar(int character);
int putc(int c, FILE *stream);
int puts(const char * str);

int fscanf(FILE * restrict stream, const char * restrict format, ...);
int scanf(const char * restrict format, ...);
int sscanf(const char * restrict s, const char * restrict format, ...);
int vfscanf(FILE * restrict stream, const char * restrict format, va_list);
int vscanf(const char * restrict format, va_list);
int vsscanf(const char * restrict s, const char * restrict format, va_list);

char * fgets(char* restrict str, int size, FILE* restrict stream);
char * gets(char *);
int fgetc(FILE *stream);
int getc(FILE * stream);
int getchar(void);

int ungetc(int c, FILE * stream);

int feof(FILE * stream);
int ferror(FILE *stream);
void clearerr(FILE *stream);

FILE* fopen(const char * restrict filename, const char * restrict mode);
FILE * freopen(const char * restrict filename, const char * restrict mode, FILE * restrict stream);
int fclose(FILE *stream);

size_t fread(void * restrict ptr, size_t size, size_t nmemb, FILE * restrict stream);
size_t fwrite(const void * restrict ptr, size_t size, size_t nmemb, FILE * restrict stream);

int fgetpos(FILE * restrict stream, fpos_t * restrict pos);
int fseek(FILE * stream, long int offset, int whence);
int fsetpos(FILE * stream, const fpos_t * pos);
long int ftell(FILE * stream);
void rewind(FILE * stream);

int fflush(FILE * stream);
int setbuffer(FILE * restrict stream, char * restrict buf, size_t size);
int setvbuf(FILE * restrict stream, char * restrict buf, int mode, size_t size);
void setbuf(FILE * restrict stream, char * restrict buf);
void setlinebuf(FILE * restrict stream);

int fileno(FILE * stream);

#endif
