#include <threads.h>
#include <stdio.h>

int f(void*) {
	printf("Inside f\n");
	printf("f() threadid = %d\n", thrd_current());
	return 7;
}

int main(void){
	thrd_t newThreadId;
	thrd_create(&newThreadId, &f, NULL);
	printf("I created a thread %d\n", newThreadId);
	printf("Main threadid = %d\n", thrd_current());
	printf("Waiting on f...\n");
	int otherThreadValue;
	int joined = thrd_join(newThreadId, &otherThreadValue);
	if (joined == thrd_success) {
		printf("f returned %d\n", otherThreadValue);
	} else {
		printf("Failed to join.  status is %d\n", joined);
	}
	return 0;
}
