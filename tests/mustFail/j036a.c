// kcc-assert-error(00019)
#include <limits.h>

int main(void){
	INT_MIN % -1;
	return 0;
}

