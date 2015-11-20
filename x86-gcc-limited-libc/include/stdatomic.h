#ifndef _KCC_STDATOMIC_H
#define _KCC_STDATOMIC_H
#include <kcc_settings.h>

// some comments below are © ISO/IEC and come from 9899:201x n1516 and n1548


/* C1X 7.17.3
The enumerated type memory_order specifies the detailed regular (non-atomic)
memory synchronization operations as defined in 5.1.2.4 and may provide for
operation ordering. Its enumeration constants are as follows:
*/
enum memory_order {
	memory_order_relaxed,
	memory_order_consume,
	memory_order_acquire,
	memory_order_release,
	memory_order_acq_rel,
	memory_order_seq_cst,
};


/* C1X 7.17.4.1
Depending on the value of order, this operation:
- has no effects, if order == memory_order_relaxed;
- is an acquire fence, if order == memory_order_acquire or order ==
memory_order_consume;
- is a release fence, if order == memory_order_release;
- is both an acquire fence and a release fence, if order ==
memory_order_acq_rel;
- is a sequentially consistent acquire and release fence, if order ==
memory_order_seq_cst.
*/
void atomic_thread_fence(memory_order order);

#endif
