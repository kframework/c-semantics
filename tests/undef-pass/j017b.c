#include <limits.h>
int f(int x){
	return x;
}

int main(void){
	f(INT_MAX);
	return 0;
}
