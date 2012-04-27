#include <stdio.h>
int main(void){
	int x = 5;
	int* p = &x;
	if (sizeof(! 0) != sizeof(int)) { printf("bad !\n"); }
	if (sizeof(5 == 6) != sizeof(int)) { printf("bad ==\n"); }
	if (sizeof(2 != 3) != sizeof(int)) { printf("bad !=\n"); }
	if (sizeof(~(char)5) != sizeof(int)) { printf("bad ~char\n"); }
	if (sizeof(3 % 1) != sizeof(int)) { printf("bad %\n"); }
	if (sizeof(*p) != sizeof(int)) { printf("bad *\n"); }
	return 0;
}

