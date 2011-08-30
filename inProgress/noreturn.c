#include <stdlib.h>
_Noreturn void f(void){
	exit(1);
}

int main(void){
	f();
	return 5;
}
