#include <stdio.h>

void f(double d){
	printf("%d\n", (int)((-d) * 100));
}


int main(void){
	double x = 5;
	f(6.2);
	printf("%d\n", (int)((-((double)(3.5))) * 100));
	printf("%d\n", sizeof(-x));
}
