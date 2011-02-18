#include <threads.h>
#include <stdlib.h>

int* sneaky;

int f(void* p){
	_Thread_local int p = 5;
	sneaky = &p;
	return 0;
}

int main(void){
	int threadId;
	int retval;
	thrd_create(&threadId, f, NULL);
	thrd_join(threadId, &retval); // thread f is now dead
	return *sneaky;
}
