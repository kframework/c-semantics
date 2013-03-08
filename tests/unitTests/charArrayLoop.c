#include <stdio.h>
#define A 2
#define B 5
int main(void){
	char a[A][B] = {0};

	int count = 0;
	for (int i = 0; i < A; i++){
		for (int j = 0; j < B; j++){
			a[i][j] = count++;
		}
	}
	char* p = &a[0][0];
	for (int i = 0; i < A * B; i++){
		printf("%d\n", *(p+i));
	}
}
