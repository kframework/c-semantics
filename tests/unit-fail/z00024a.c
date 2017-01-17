#include<stdint.h>
// kcc-assert-error(00024a)
int main(void){
	int x = 0;
	return (intptr_t)(&x) & -7 + 146;
}
