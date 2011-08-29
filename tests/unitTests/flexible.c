#include <stdlib.h>

struct _s {
	int x;
	int a[];
};

int main(void){
	struct _s *p = (struct _s*)malloc(sizeof(struct _s) + 5 * sizeof(int));
	p->a[2] = 5;
	return p->a[2];
}
