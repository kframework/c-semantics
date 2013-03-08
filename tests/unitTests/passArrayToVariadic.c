#include <stdio.h>
#include <string.h>

char code[5][3];

int main(void){
	code[2][0] = 'a';
	code[2][1] = 'b';
	code[2][2] = 0;
	int i = 2;
	
	printf("%d%s%d%d\n",i,code[i],i,strlen(code[i]));
	return 0;
}
