#include <limits.h>
#include <stdio.h>

int main(void){
	// arithmetic conversion should occur on the two branches below, converting to an unsigned int, causing the original addition to convert to an unsigned, causing no signed overflow 
	printf("%d\n", INT_MAX + (0 ? (unsigned int) 1 : (int) 1));
}
