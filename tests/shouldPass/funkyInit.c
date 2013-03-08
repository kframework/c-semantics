#include <stdio.h>
typedef struct { int codes[1]; char name[6]; } Word;

Word words[] = {1, {"foo"}};

int main(void){
	printf("%d\n", words[0].codes[0]);
}
