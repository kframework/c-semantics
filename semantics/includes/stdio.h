#ifndef _K_STDIO_H
#define _K_STDIO_H

#define NULL ((void *)0)
typedef unsigned int size_t; // this needs to correspond to cfg:sizeut

typedef struct {
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
int putchar ( int character );
int getchar ( void );
int printf(const char *format, ...);
int puts (const char * str);

//int getc(FILE *stream);
int getc(FILE *stream);
int feof ( FILE * stream );
FILE* fopen(const char *filename, const char *mode);
int fclose(FILE *stream);
int fgetc(FILE *stream);
char* fgets (char* restrict str, int size, FILE* restrict stream);

#endif
