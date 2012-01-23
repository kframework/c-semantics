#include <stdio.h>
#include <stdlib.h>
int main(void) {
	int x = 5;
	int *p = &x;
	int a[5] = {0};
	
	if (&(*(p)) == p) {
		printf("1\n");
	}	
	if (&(*((char*)0)) == (char*)0) {
		printf("2\n");
	}
	if (&(*(NULL)) == NULL) {
		printf("3\n");
	}
	if (&(a[3]) == a+3) {
		printf("4\n");
	}
	if (&(*(&(*(void**)NULL))) == (void**)NULL) {
		printf("5\n");
	}
	// if (&(&(*(*(void**)NULL))) == (void**)NULL) {
	// 	printf("6\n");
	// }
}
