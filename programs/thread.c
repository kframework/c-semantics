#include <threads.h>
#include <stdio.h>

int f(void*) {
	printf("Inside f\n");
	printf("f() threadid = %d\n", thrd_current());
	return 0;
}

int main(void){
	thrd_t newThreadId;
	thrd_create(&newThreadId, &f, NULL);
	printf("I created a thread %d\n", newThreadId);
	printf("Main threadid = %d\n", thrd_current());
	return 0;
}
