#include <stdio.h>
int main(void){
	struct s {int x; int y; } s0 = {1, 2};
	struct s s1 = {2, 3};
	int x;

	x = sizeof(5 ? s0 : s1);
	printf("%d\n", x);
	
	int a1[5] = {0};
	int a2[5] = {2, 3};
	x = sizeof(5 ? a1 : a2);
	printf("%d\n", x);
}
