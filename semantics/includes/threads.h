// some comments below are © ISO/IEC and come from 9899:201x n1516
#include <time.h>
// expands to a value that can be used to initialize an object of type once_flag
#define ONCE_FLAG_INIT

// expands to an integer constant expression representing the maximum number of times that destructors will be called when a thread terminates.
#define TSS_DTOR_ITERATIONS 1

typedef int cnd_t;
typedef int thrd_t;
typedef int tss_t;
typedef int mtx_t;
typedef void (*tss_dtor_t)(void*) ;
typedef int (*thrd_start_t)(void*);
typedef int once_flag;
typedef struct {time_t sec; long nsec;} xtime;
// which is a structure type that holds a time specified in seconds and nanoseconds. 

enum {
	mtx_plain = 0, // which is passed to mtx_init to create a mutex object that supports neither timeout nor test and return;
	mtx_recursive = 1, // which is passed to mtx_init to create a mutex object that supports recursive locking;
	mtx_timed = 2, // which is passed to mtx_init to create a mutex object that supports timeout;
	mtx_try = 3, // which is passed to mtx_init to create a mutex object that supports test and return;
};
enum {
	thrd_success = 0, //which is returned by a function to indicate that the requested operation succeeded;
	thrd_error = 1, // which is returned by a function to indicate that the requested operation failed; and
	thrd_timeout = 2, //which is returned by a timed wait function to indicate that the time specified in the call was reached without acquiring the requested resource;
	thrd_busy = 3, // which is returned by a function to indicate that the requested operation failed because a resource requested by a test and return function is already in use;
	thrd_nomem = 4 // which is returned by a function to indicate that the requested operation failed because it was unable to allocate memory.
};

/* C1X 7.25.5.1
The thrd_create function creates a new thread executing func(arg). If the
thrd_create function succeeds, it sets the thread thr to a value that uniquely
identifies the newly created thread. 

The thrd_create function returns thrd_success on success, or thrd_nomem if
no memory could be allocated for the thread requested, or thrd_error if the request
could not be honored.
*/
int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);

/**************************************************
The below are fully defined in C
**************************************************/

/* C1X 7.25.5.4
The thrd_equal function will determine whether the thread identified by thr0 refers
to the thread identified by thr1.

The thrd_equal function returns zero if the thread thr0 and the thread thr1 refer to
different threads. Otherwise the thrd_equal function returns a nonzero value.
*/
int thrd_equal(thrd_t thr0, thrd_t thr1) {
	return thr0 == thr1;
}
