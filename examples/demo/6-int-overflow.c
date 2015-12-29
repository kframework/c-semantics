// KCC is also able to detect integer overflow operations that occur while the
// program is executing.  According to the C standard, integer overflow
// operations fall under the category of implementation defined behavior,
// which is unspecified behavior where each implementation documents how
// the choice is made.  KCC can be instantiated with different profiles
// corresponding to different implementation choices (type kcc -v to see the
// existing profiles; contact https://runtimeverification.com/support if you
// are interested in a specific profile that is not available).  For example,
// while with conventional compilers the program below reports no errors
// when executed, with the default KCC profile (x86, 64 bit, linux) it
// reports an integer overflow, but no error is reported if you declare
// variable a as an int instead of short int, or if you iterate 14 times
// instead of 15:

int main() {
  short int a = 1;
  int i;
  for (i = 0; i < 15; i++) {
    a *= 2;
  }
  return a;
}
