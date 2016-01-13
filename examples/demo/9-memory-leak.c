// Not all cases of dynamically detectable defects in code necessarily arise
// from undefined behavior. In some cases it may be desirable for users to 
// be able to detect certain categories of behavior that may be indicative
// of bugs even though they can also occur in strictly-conforming C programs.
// For example, the program below exhibits a memory leak, wherein memory
// is allocated by malloc but never freed. Other types of scenarios that may be
// of interest include unsigned integer overflow, terminating a thread while
// holding a lock, allocating more memory on the heap than is allowed by the
// operating system, and others.

// kcc can detect these errors in any of its profiles simply by enabling the
// -Wlint flag to kcc. This does not alter the semantics of the program in any
// way aside from assigning a maximum memory size configurable using -fheap-size
// beyond which heap-allocation functions like malloc will report a warning and
// return a null pointer. However, it enables many more checks which can be
// reported on standard error. Some of these results may be false positives in
// the sense that the behavior being detected did in fact occur, but this was
// the intention of the programmer writing the code. However, we still have
// no false positives in the sense that if a warning is reported as a result of
// this flag, then there really exists a real code execution for which the specific
// behavior being detected did occur.

#include<stdlib.h>

int main() {
  int *x = malloc(sizeof(int));
  *x = 0;
  return *x;
}
