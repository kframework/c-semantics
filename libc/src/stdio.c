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

int __fslPutc(char c, int handle);
int __fslOpenFile(const char* filename, const char* mode);
int __fslCloseFile(int handle);
int __fslFGetC(int handle, unsigned long long int offset);
int __fsl_next_fd = 3;

int putc (char c, FILE* stream) {
	return __fslPutc(c, stream->handle);
}


FILE stdin_file = {0, 0, 0};
FILE stdout_file = {0, 1, 0};
FILE stderr_file = {0, 2, 0};
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

int fgetc(FILE* stream){
	int retval = __fslFGetC(stream->handle, 0); // offset is not being used
	if (retval < 0) {
		// stream->offset++;
	// } else {
		stream->eof = 1;
	}
	//printf("read %x\n", retval);
	return retval;
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

