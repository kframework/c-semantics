#include<stdlib.h>
#include<limits.h>
#include<stdarg.h>

// Here we see a quite convoluted and tricky program. The function
// process_something takes an integer that it assumes to be positive, adds
// two to it, allocates a string based on the resulting size, and calls a
// va_list function with the value of the string, which in turn reads its
// value. A casual viewer of C may assume that this is correct. They see the 
// line:

// if (size > size+2)

// and assume that this line will correctly prevent further evaluation of the
// program if size+2 is greater than the maximum value stored in an int.
// However, in point of fact, because size is a signed integer, the behavior
// that occurs when an exceptional condition like overflow occurs is
// considered undefined. Thus, when this program is run with gcc -O3, gcc
// assumes that size > size+2 does not trigger an exceptional condition,
// and therefore can be optimized to:

// if (0)

// As you can see, this removes the error check entirely, leading to continued
// execution of the function. At this point, size+2 has wrapped around
// and become a very large negative number, so when malloc is called, we
// do not end up with a pointer to valid memory as a result. Thus, when the
// call to foo is made, the application actually segfaults.

// This once again underscores the vital imperative that applications contain
// no undefined behavior, because a modern compiler will not guarantee the
// behavior that seems most intuitive in all cases with regards to undefined
// programs.

void foo(int n, ...) {
  va_list l;
  va_start(l, n);
  char *x = va_arg(l, char *);
  x[0];
  x[1];
  va_end(l);
}

void process_something(int size) {
  if (size < 0)
    abort();
  // check for overflow
  if (size > size+2)
    return;
  char *string = malloc(size+2);
  string[0] = 'f';
  string[1] = '\000';
  char x[2];
  foo(1, string);
}

int main() {
  process_something(2);
  process_something(INT_MAX);
}

