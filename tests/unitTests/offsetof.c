#include <stddef.h>
#include <stdio.h>
struct s {
	int a;
	int b;
};

int main(void){
	printf("%d\n", (int)offsetof(struct s, b));
}
