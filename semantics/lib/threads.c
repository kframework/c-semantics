/* 
implementation of threads.h functions
look in threads.h for documentation

not currently used
*/

#include <threads.h>

// enum { __mutex_idle, __mutex_busy, };

static int __mtx_counter = 0;

// int mtx_init(mtx_t *mtx, int type) {
	// if (! __test_and_set(__init_sync, 1)) {
		// mtx->status = __mutex_idle;
		// mtx->id = __mtx_counter++;
		// mtx->type = type;
		
		// __init_sync = 0;
		// return thrd_success;
	// }
	// return thrd_error;
// }

// unsafe
int mtx_init(mtx_t *mtx, int type) {
	mtx->owner = 0;
	mtx->id = __mtx_counter++;
	mtx->type = type;
	mtx->owned = 0;
	mtx->flag = 0;
	mtx->alive = 1;
	return thrd_success;
}

int mtx_lock(mtx_t *mtx) {
	int myId = thrd_current(void);
	while (1) {
		while (__test_and_set(mtx->flag, 1)) ; // eventually someone sets it to 0
		if (!mtx->alive) { return thrd_error; }
		if (!mtx->owned) {
			mtx->owner = myId;
			mtx->owned = 1;
			mtx->flag = 0; // we're done
			return thrd_success;
		}
	}
	return thrd_error;
}


int mtx_unlock(mtx_t *mtx) {
	int myId = thrd_current(void);
	while (1) {
		while (__test_and_set(mtx->flag, 1)) ; // eventually someone sets it to 0
		if (!mtx->alive) { return thrd_error; }
		if (mtx->owned && mtx->owner == myId) {
			mtx->owner = 0;
			mtx->owned = 0;
			mtx->flag = 0; // we're done
			return thrd_success;
		} else {
			return thrd_error;
		}
	}
	return thrd_error;
}


void mtx_destroy(mtx_t *mtx) {
	while (__test_and_set(mtx->flag, 1)) ; // eventually someone sets it to 0
	mtx->alive = 0;
	mtx->owned = 0;
	mtx->owner = 0;
	mtx->flag = 0;
}



int thrd_equal(thrd_t thr0, thrd_t thr1) {
	return thr0 == thr1;
}
