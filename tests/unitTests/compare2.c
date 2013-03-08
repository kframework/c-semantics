#include <stdio.h>
int main(void){
	int a[2];
	if (&a[0] == &a[2]) {
		printf("equal\n");
	} else {
		printf("neq\n");
	}
}

