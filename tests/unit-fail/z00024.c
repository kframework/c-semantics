// kcc-assert-error(00024a)
#include<stdint.h>
int main(void){
	int x = 0;
	return (intptr_t)(&x) & 7 + 132;
}

