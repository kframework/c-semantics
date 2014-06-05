#include <string.h>

int main(void){
	const char p[] = "hello";
	char *q = strchr(p, p[0]);
	q[0] = 'x';
	return 0;
}
