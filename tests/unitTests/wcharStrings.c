#include <stdio.h>
int main(void){
	for (int i = 0; i < sizeof(L"abcd") / sizeof(L"abcd"[0]); i++) {
		printf("%c", (int)L"abcd"[i]);
	}
	printf("\n");
}

