// At its most basic level, KCC can detect undefined behaviors in programs.
// If you run this file using clang, you get a warning about the undefined
// behavior, but it returns 3 like one might expect. A developer might choose
// to ignore this warning, not understanding its significance.

// However, then one day you decide to switch compilers and run this program
// with gcc. Suddenly, you get the entirely unexpected value of 4 on the
// command line. How is this possible? Well, GCC is allowed to optimize
// however it chooses as long as it does not affect the behavior of
// well-defined programs. So what it has chosen to do is to hoist the side
// effects out of the addition expression so that they happen before. Thus
// this program becomes:

// int x  = 0;
// x = 1;
// x = 2;
// return x + x;

// This example demonstrates how the increased optimization of compilers
// means that even quite simple and harmless-seeming undefined behaviors
// can actually affect the behavior of the program in certain situations.
int main() {
  int x = 0;
  return (x = 1) + (x = 2);
}
