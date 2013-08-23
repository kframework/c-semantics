#ifndef _KCC_THREADS_H
#define _KCC_THREADS_H
#include <kcc_settings.h>

// some comments below are © ISO/IEC and come from 9899:201x n1516 and n1548
#include <time.h>
// expands to a value that can be used to initialize an object of type
// once_flag
#define ONCE_FLAG_INIT 0

// expands to an integer constant expression representing the maximum number of
// times that destructors will be called when a thread terminates.
#define TSS_DTOR_ITERATIONS 1

typedef int cnd_t;
typedef int thrd_t;
typedef int tss_t;
typedef struct { int id; int type; thrd_t owner; int owned; int flag; int alive; } mtx_t;
typedef void (*tss_dtor_t)(void*);
typedef int (*thrd_start_t)(void*);
typedef int once_flag;
typedef struct {time_t sec; long nsec;} xtime;
// which is a structure type that holds a time specified in seconds and
// nanoseconds. 

enum {
	mtx_plain = 0, // which is passed to mtx_init to create a mutex object that supports neither timeout nor test and return;
	mtx_recursive = 1, // which is passed to mtx_init to create a mutex object that supports recursive locking;
	mtx_timed = 2, // which is passed to mtx_init to create a mutex object that supports timeout;
	mtx_try = 4, // which is passed to mtx_init to create a mutex object that supports test and return;
};
enum {
	thrd_success = 0, //which is returned by a function to indicate that the requested operation succeeded;
	thrd_error = 1, // which is returned by a function to indicate that the requested operation failed; and
	thrd_timeout = 2, //which is returned by a timed wait function to indicate that the time specified in the call was reached without acquiring the requested resource;
	thrd_busy = 3, // which is returned by a function to indicate that the requested operation failed because a resource requested by a test and return function is already in use;
	thrd_nomem = 4 // which is returned by a function to indicate that the requested operation failed because it was unable to allocate memory.
};

// our threading primitive
int __test_and_set(int *p, int value);

/* C1X 7.25.2.1
The call_once function uses the once_flag pointed to by flag to ensure that
func is called exactly once, the first time the call_once function is called
with that value of flag. Completion of an effective call to the call_once
function synchronizes with all subsequent calls to the call_once function with
the same value of flag.
*/
void call_once(once_flag *flag, void (*func)(void));

/* C1X 7.25.4.1
The mtx_destroy function releases any resources used by the mutex pointed to by
mtx. No threads can be blocked waiting for the mutex pointed to by mtx.

The mtx_destroy function returns no value.
*/
void mtx_destroy(mtx_t *mtx);

/* C1X 7.25.4.2
The mtx_init function creates a mutex object with properties indicated by type,
which must have one of the six values:

mtx_plain for a simple non-recursive mutex,
mtx_timed for a non-recursive mutex that supports timeout,
mtx_try for a non-recursive mutex that supports test and return,
mtx_plain | mtx_recursive for a simple recursive mutex,
mtx_timed | mtx_recursive for a recursive mutex that supports timeout, or
mtx_try | mtx_recursive for a recursive mutex that supports test and return.

If the mtx_init function succeeds, it sets the mutex pointed to by mtx to a
value that uniquely identifies the newly created mutex.

The mtx_init function returns thrd_success on success, or thrd_error if the
request could not be honored.

Note: the committee may be removing mtx_try, as discussed in
http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1521.htm
*/
int mtx_init(mtx_t *mtx, int type);

/* C1X 7.25.4.3
The mtx_lock function blocks until it locks the mutex pointed to by mtx. If the
mutex is non-recursive, it shall not be locked by the calling thread. Prior
calls to mtx_unlock on the same mutex shall synchronize with this operation.

The mtx_lock function returns thrd_success on success, or thrd_busy if the
resource requested is already in use, or thrd_error if the request could not be
honored.
*/
int mtx_lock(mtx_t *mtx);

/* C1X 7.25.4.4
The mtx_unlock function unlocks the mutex pointed to by mtx. The mutex pointed
to by mtx shall be locked by the calling thread.

The mtx_unlock function returns thrd_success on success or thrd_error if the
request could not be honored.
*/
int mtx_unlock(mtx_t *mtx);

/* C1X 7.25.5.1
The thrd_create function creates a new thread executing func(arg). If the
thrd_create function succeeds, it sets the thread thr to a value that uniquely
identifies the newly created thread. 

The thrd_create function returns thrd_success on success, or thrd_nomem if no
memory could be allocated for the thread requested, or thrd_error if the
request could not be honored.
*/
extern int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);

/* C1X 7.25.5.2
The thrd_current function identifies the thread that called it.

The thrd_current function returns a value that uniquely identifies the thread
that called it.
*/
extern thrd_t thrd_current(void);

/* C1X 7.25.5.3
The thrd_detach function tells the operating system to dispose of any resources
allocated to the thread identified by thr when that thread terminates. The
value of the thread identified by thr value shall not have been set by a call
to thrd_join or thrd_detach.

The thrd_detach function returns thrd_success on success or thrd_error if the
request could not be honored.
*/
extern int thrd_detach(thrd_t thr);

/* C1X 7.25.5.4
The thrd_equal function will determine whether the thread identified by thr0
refers to the thread identified by thr1.

The thrd_equal function returns zero if the thread thr0 and the thread thr1
refer to different threads. Otherwise the thrd_equal function returns a nonzero
value.
*/
int thrd_equal(thrd_t thr0, thrd_t thr1);

/* C1X 7.25.5.5
The thrd_exit function terminates execution of the calling thread and sets its
result code to res.

The thrd_exit function returns no value.
*/
extern void thrd_exit(int res);

/* C1X 7.25.5.6
The thrd_join function blocks until the thread identified by thr has
terminated. If the parameter res is not a null pointer, it stores the
thread's result code in the integer pointed to by res. The value of the
thread identified by thr shall not have been set by a call to thrd_join or
thrd_detach.

The thrd_join function returns thrd_success on success or thrd_error if the
request could not be honored.
*/
extern int thrd_join(thrd_t thr, int *res);

#endif
