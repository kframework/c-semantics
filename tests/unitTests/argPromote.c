#include <stdio.h>

int f(int x){
	return x;
}
unsigned char g(signed char x){
	printf("%d\n", x); 
	return x+1;
}
int main(void){
	signed char x = 12;
	printf("%d\n", f(5));
	printf("%d\n", g(6));
	printf("%d\n", (unsigned char)8);
	printf("%d\n", x);
}
