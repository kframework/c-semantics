#include <stdio.h>
int main(void){
	int x = 0;
	int y;
	y = sizeof(x = 1);
	printf("%d\n", y);
}

