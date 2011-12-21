#include <threads.h>
#include <stdlib.h>

int* sneaky;
_Thread_local int p = 5;

int f(void* p){
	sneaky = &p;
	return 0;
}

int main(void){
	int threadId;
	int retval;
	thrd_create(&threadId, f, NULL);
	thrd_join(threadId, &retval); // thread f is now dead
	*sneaky;
	return 0;
}
