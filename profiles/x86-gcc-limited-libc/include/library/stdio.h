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

#ifdef __cplusplus
extern "C" {
#endif

int fprintf(FILE * __restrict__ stream, const char * __restrict__ format, ...);
int printf(const char * __restrict__ format, ...);
int snprintf(char * __restrict__ s, size_t n, const char * __restrict__ format, ...);
int sprintf(char * __restrict__ s, const char * __restrict__ format, ...);
int vprintf(const char * __restrict__ format, va_list);
int vfprintf(FILE * __restrict__ stream, const char * __restrict__ format, va_list);
int vsnprintf(char * __restrict__ s, size_t n, const char * __restrict__ format, va_list);
int vsprintf(char * __restrict__ s, const char * __restrict__ format, va_list);

int fputc(int c, FILE *stream);
int fputs(const char * __restrict__ str, FILE * __restrict__ stream);
int putchar(int character);
int putc(int c, FILE *stream);
int puts(const char * str);

int fscanf(FILE * __restrict__ stream, const char * __restrict__ format, ...);
int scanf(const char * __restrict__ format, ...);
int sscanf(const char * __restrict__ s, const char * __restrict__ format, ...);
int vfscanf(FILE * __restrict__ stream, const char * __restrict__ format, va_list);
int vscanf(const char * __restrict__ format, va_list);
int vsscanf(const char * __restrict__ s, const char * __restrict__ format, va_list);

char * fgets(char* __restrict__ str, int size, FILE* __restrict__ stream);
char * gets(char *);
int fgetc(FILE *stream);
int getc(FILE * stream);
int getchar(void);

int ungetc(int c, FILE * stream);

int feof(FILE * stream);
int ferror(FILE *stream);
void clearerr(FILE *stream);

FILE* fopen(const char * __restrict__ filename, const char * __restrict__ mode);
FILE * freopen(const char * __restrict__ filename, const char * __restrict__ mode, FILE * __restrict__ stream);
int fclose(FILE *stream);

size_t fread(void * __restrict__ ptr, size_t size, size_t nmemb, FILE * __restrict__ stream);
size_t fwrite(const void * __restrict__ ptr, size_t size, size_t nmemb, FILE * __restrict__ stream);

int fgetpos(FILE * __restrict__ stream, fpos_t * __restrict__ pos);
int fseek(FILE * stream, long int offset, int whence);
int fsetpos(FILE * stream, const fpos_t * pos);
long int ftell(FILE * stream);
void rewind(FILE * stream);

int fflush(FILE * stream);
int setbuffer(FILE * __restrict__ stream, char * __restrict__ buf, size_t size);
int setvbuf(FILE * __restrict__ stream, char * __restrict__ buf, int mode, size_t size);
void setbuf(FILE * __restrict__ stream, char * __restrict__ buf);
void setlinebuf(FILE * __restrict__ stream);

int fileno(FILE * stream);

#ifdef __cplusplus
}
#endif

#endif
