// kcc-assert-error(00015)
#include <limits.h>

int main(void){ 
	return (long long) 0 || INT_MAX+1;
}

