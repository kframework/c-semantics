#ifndef _KCC_STDIO_H
#define _KCC_STDIO_H
#include <kcc_settings.h>
#include <stddef.h>

typedef struct FILE_ {
	unsigned long long int offset;
	unsigned short handle;
	unsigned char eof;
} FILE;

extern FILE stdin_file;
extern FILE stdout_file;
extern FILE stderr_file;

extern FILE* stdin;
extern FILE* stdout;
extern FILE* stderr;

// stdio.h
#define EOF -1
int putchar(int character);
int getchar(void);
int printf(const char * restrict format, ...);
int fprintf(FILE *stream, const char *format, ...);
int sprintf(char * restrict s, const char * restrict format, ...);
int snprintf(char * restrict s, size_t n, const char * restrict format, ...);
int puts(const char * str);

int getc(FILE *stream);
int feof(FILE * stream);
FILE* fopen(const char *filename, const char *mode);
int fclose(FILE *stream);
int fgetc(FILE *stream);
char* fgets(char* restrict str, int size, FILE* restrict stream);

#endif
