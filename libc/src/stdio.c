#include <stdio.h>
#include <stdlib.h>

// TODO(chathhorn): placeholder.
int fprintf(FILE *stream, const char *format, ...) {
      return 0;
}

int getc(FILE *stream){
	return fgetc(stream);
}

int puts(const char * str){
	return printf("%s\n", str);
}

int __fslPutc(unsigned char c, int handle);
int __fslOpenFile(const char* filename, const char* mode);
int __fslCloseFile(int handle);
int __fslFGetC(int handle, unsigned long long int offset);
int __fsl_next_fd = 3;

int fputc (int c, FILE* stream) {
	return __fslPutc(c, stream->handle);
}

int putc(int c, FILE *stream) {
	return fputc(c, stream);
}

int putchar(int c) {
	return putc(c, stdout);
}


FILE stdin_file = {0, 0, 0, 0};
FILE stdout_file = {0, 1, 0, 0};
FILE stderr_file = {0, 2, 0, 0};
FILE* stdin = &stdin_file;
FILE* stdout = &stdout_file;
FILE* stderr = &stderr_file;
FILE* fopen(const char *filename, const char *mode){
	//int nextHandle = __fsl_next_fd++;
	//int retval = __fslOpenFile(filename, nextHandle);
	int nextHandle = __fslOpenFile(filename, mode);
	// if (retval) {
		// return NULL;
	// }
	
	FILE* newFile = (FILE*)malloc(sizeof(FILE));
	newFile->offset = 0;
	newFile->handle = nextHandle;
	newFile->eof = 0;
	newFile->error = 0;	

	return newFile;
}

int fclose(FILE* stream){
	int retval = __fslCloseFile(stream->handle);
	if (retval) {
		return EOF;
	}
	free(stream);
	
	return 0;
}

int feof ( FILE * stream ) {
	return stream->eof;
}

int ferror (FILE *stream) {
	return stream->error;
}

int fgetc(FILE* stream){
	if (stream->eof) {
		return EOF;
	}
	int retval = __fslFGetC(stream->handle, 0); // offset is not being used
	if (retval == -1) {
		// stream->offset++;
	// } else {
		stream->eof = 1;
		return EOF;
	}
	if (retval == -2) {
		stream->error = 1;
		return EOF;
	}
	//printf("read %x\n", retval);
	return retval;
}

int getchar() {
	return getc(stdin);
}

char* fgets (char* restrict str, int size, FILE* restrict stream){
	if (size < 2){ return NULL; }
	int i = 0;
	while (i < size - 1){
		int oneChar = fgetc(stream);
		if (oneChar == EOF) {
			if (i == 0) {
				return NULL;
			} else {
				break;
			}
		}
		str[i] = oneChar;
		if (oneChar == '\n') {
			break;
		}
		
		i++;
	}
	str[i + 1] = '\0';
	return str;
}

