/*
 * based on code by  J. Senning
 * 
 * 
 * A solution to the dining philosophers problem, using pthreads, semaphores
 * and shared memory.
 *
 * Written 02/22/1998 by J. Senning based on code provided by R. Bjork
 * Revised 01/04/2000 by J. Senning
 */

#include <stdio.h>
#include <stdlib.h>
#include <threads.h>

//#define NUM_PHILOSOPHERS	3
#define MAX_PHILOSOPHERS 10
#define MAX_MEALS 1

int NUM_PHILOSOPHERS;

typedef struct {
	int n;
} phil_arg;

/*--------------------------------------------------------------------------*/

// Each chopstick is represented by a lock.  We also need a lock to control modifications of the shared variables.
mtx_t chopstick[MAX_PHILOSOPHERS + 1];
phil_arg phil_args[MAX_PHILOSOPHERS];
// mtx_t mutex;

int total_number_of_meals = 0;

/*
 * Simulate a philosopher - endlessly cycling between eating and thinking
 * until his "life" is over.  Since this is called via pthread_create(), it
 * must accept a single argument which is a pointer to something.  In this
 * case the argument is a pointer to an array of two integers.  The first
 * is the philosopher number and the second is the duration (in seconds)
 * that the philosopher sits at the table.
 */
void philosopher(void* arg) {
	int n = ((phil_arg*)arg)->n;
	//while(total_number_of_meals < MAX_MEALS) {
	while(1) {
		/* Hungry */
		
		// obtain chopsticks
	    if ( n % 2 == 0 ) {
			/* Even number: Left, then right */
			mtx_lock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
			mtx_lock(&chopstick[n]);
		} else {
			// /* Odd number: Right, then left */
			mtx_lock(&chopstick[n]);
			mtx_lock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
		}
		
		/* Eating */
		// total_number_of_meals++;
		
		// release chopsticks
		mtx_unlock(&chopstick[n]);
		mtx_unlock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
		
		/* Think */
    }
}

/*==========================================================================*/

int main(int argc, char *argv[]) {
	if (argc == 2) {
		NUM_PHILOSOPHERS = atoi(argv[1]);
	} else {
		NUM_PHILOSOPHERS = 2;
	}
	if (NUM_PHILOSOPHERS > MAX_PHILOSOPHERS) {
		printf("Too many philosophers\n");
		return 0;
	}
	
	thrd_t philosophers[NUM_PHILOSOPHERS];
	
	// initialize mutexes (chopsticks)
	for (int i = 0; i < NUM_PHILOSOPHERS + 1; i++) {
		mtx_init(&chopstick[i], mtx_plain);
	}
	
	// Create a thread for each philosopher.
	for (int i = 0; i < NUM_PHILOSOPHERS; i++) {
		phil_args[i].n = i;
		thrd_create(&philosophers[i], philosopher, &phil_args[i]);
	}
	
	// Wait for the philosophers to finish.
	for (int i = 0; i < NUM_PHILOSOPHERS; i++) {
		thrd_join(philosophers[i], NULL);
	}
	
	// Produce the final report.
	// printf("Total meals served = %d\n", total_number_of_meals );

	return 0;
}
