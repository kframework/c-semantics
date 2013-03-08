#include <stdio.h>
int main(void){
	int x = 5;
	int *p = &x;
	_Bool b1 = (_Bool)p;
	_Bool b2 = (_Bool)NULL;
	_Bool b3 = (_Bool)0.0;
	_Bool b4 = (_Bool)0.1;
	if (b1 != 1) { printf("Bad b1\n"); } 
	else { printf("Good b1\n"); }
	if (b2 != 0) { printf("Bad b2\n"); }
	else {printf("Good b2\n"); }
	if (b3 != 0) { printf("Bad b3\n"); }
	else {printf("Good b3\n"); }
	if (b4 != 1) { printf("Bad b4\n"); }
	else {printf("Good b4\n"); }

}

