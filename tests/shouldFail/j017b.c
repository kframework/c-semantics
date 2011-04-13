#include <limits.h>
int f(int x){
	return x;
}

int main(void){
	f(INT_MAX * 2.0);
	return 0;
}
