#include <stdio.h>
#include <threads.h>

struct farg {
	int x;
	int y;
};

int g(int x, int y){
	printf("(%d, %d)\n", x, y);
	return 0;
}

int f(void* arg) {
	struct farg* a = arg;
	printf("inside f: %d\n", a->x);
	g(a->x, 0);
	//spawn(g, x, 0);
	//spawn(g, x, 1);
	return 0;
}
int main(void){
	thrd_t newThreadId1;
	thrd_t newThreadId2;
	thrd_create(&newThreadId1, &f, (void*)&((struct farg){1}));
	thrd_create(&newThreadId2, &f, (void*)&((struct farg){1}));	
	int otherThreadValue;
	thrd_join(newThreadId1, &otherThreadValue);
	thrd_join(newThreadId2, &otherThreadValue);
	
	return 0;
}

/*
4! == 24
< output > String "(0, 0)\n(0, 1)\n(1, 0)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(0, 0)\n(0, 1)\n(1, 1)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(0, 0)\n(1, 0)\n(0, 1)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(0, 0)\n(1, 0)\n(1, 1)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(0, 0)\n(1, 1)\n(0, 1)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(0, 0)\n(1, 1)\n(1, 0)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(0, 0)\n(1, 0)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(0, 0)\n(1, 1)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(1, 0)\n(0, 0)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(1, 0)\n(1, 1)\n(0, 0)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(1, 1)\n(0, 0)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(0, 1)\n(1, 1)\n(1, 0)\n(0, 0)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(0, 0)\n(0, 1)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(0, 0)\n(1, 1)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(0, 1)\n(0, 0)\n(1, 1)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(0, 1)\n(1, 1)\n(0, 0)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(1, 1)\n(0, 0)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(1, 0)\n(1, 1)\n(0, 1)\n(0, 0)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(0, 0)\n(0, 1)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(0, 0)\n(1, 0)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(0, 1)\n(0, 0)\n(1, 0)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(0, 1)\n(1, 0)\n(0, 0)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(1, 0)\n(0, 0)\n(0, 1)\n"(.List{K}) </ output > 
< output > String "(1, 1)\n(1, 0)\n(0, 1)\n(0, 0)\n"(.List{K}) </ output > 

*/
