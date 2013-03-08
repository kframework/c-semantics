#include <stdio.h>
int main(void){
	int i = 0;
	do {
		printf("%cx", i = getchar());
	} while (i != '.');
}
