/*
 * Dekker's algorithm
 */
// based on code found at http://jakob.engbloms.se/archives/65
// original file written by Jakob Engblom

#include <stdio.h>
#include <stdlib.h>
#include <threads.h>

// #define INFINITE

static volatile char flag1 = 0;
static volatile char flag2 = 0;
static volatile char turn = 1;
static volatile char gSharedCounter = 0;
char gLoopCount = 1;

void critical1() {
#ifndef INFINITE
	gSharedCounter++;
#endif
}
void critical2() {
#ifndef INFINITE
	gSharedCounter++;
#endif
}

void dekker1(void) {
	flag1 = 1;
	turn = 2;
	while((flag2 == 1) && (turn == 2)) ;
	// Critical section
	critical1();
	// Let the other task run
	flag1 = 0;
}

void dekker2(void) {
	flag2 = 1;
	turn = 1;
	while((flag1 == 1) && (turn == 1)) ;
	// critical section
	critical2();
	// leave critical section
	flag2 = 0;
}

//
// Tasks, as a level of indirection
//
int task1(void* inp) {
	// printf("Starting task1\n");
#ifdef INFINITE
	while(1) {
#else
	for (char i = 0; i < gLoopCount; i++) {
#endif
		dekker1();
	}
	return 0;
}

int task2(void* inp) {
	// printf("Starting task2\n");
#ifdef INFINITE
	while(1) {
#else
	for (char i = 0; i < gLoopCount; i++) {
#endif
		dekker2();
	}
	return 0;
}

int main(void) {
	//int expected_sum = gLoopCount * 2;

	/* Start the threads */
	thrd_t thread1;
	thrd_t thread2;
	thrd_create(&thread1, task1, NULL);
	thrd_join(thread1, NULL);
	// task1(NULL);
	//thrd_create(&thread2, task2, NULL);

	/* Wait for the threads to end */
	//thrd_join(thread2, NULL);
	
	printf("Computed %d\n", gSharedCounter);
	return 0;
}
