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

//#define NUM_PHILOSOPHERS	3
#define MAX_PHILOSOPHERS 10

int NUM_PHILOSOPHERS;

/*--------------------------------------------------------------------------*/

// Each chopstick is represented by a lock.  We also need a lock to control modifications of the shared variables.
char chopstick[MAX_PHILOSOPHERS];
char mutex;

int total_number_of_meals = 0;

/*
 * Simulate a philosopher - endlessly cycling between eating and thinking
 * until his "life" is over.  Since this is called via pthread_create(), it
 * must accept a single argument which is a pointer to something.  In this
 * case the argument is a pointer to an array of two integers.  The first
 * is the philosopher number and the second is the duration (in seconds)
 * that the philosopher sits at the table.
 */
void philosopher( int n ) {
	while(1) {
		/* Hungry */
		
		// obtain chopsticks
	    if ( n % 2 == 0 ) {
			/* Even number: Left, then right */
			lock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
			lock(&chopstick[n]);
		} else {
			// /* Odd number: Right, then left */
			lock(&chopstick[n]);
			lock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
		}
		
		/* Eating */
		
		// release chopsticks
		unlock(&chopstick[n]);
		unlock(&chopstick[(n+1) % NUM_PHILOSOPHERS]);
		
		/* Think */
    }
}

/*==========================================================================*/

int main( int argc, char *argv[] ) {
	NUM_PHILOSOPHERS = atoi(argv[1]);

	// Create a thread for each philosopher.
	for (int i = 0; i < NUM_PHILOSOPHERS; i++ ) {
		spawn(philosopher, i);
	}

	// Wait for the philosophers to finish.
	sync();

	// Produce the final report.
	printf("Total meals served = %d\n", total_number_of_meals );

	return 0;
}
