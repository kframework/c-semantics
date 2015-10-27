// Here we see we are also able to detect a buffer underflow based on the
// initialized value of a global variable found elsewhere in the program.
// Because KCC is a dynamic analysis tool, we run the program and are thus
// actually aware of the value that gi has during its assignment statement.
// No matter what logic has modified gi up to this point, if its value is zero
// when we execute:

// i = gi;
// ary[0][i-1] = 2;

// we will detect the buffer underflow on the second dimension of the array.
unsigned int gi = 0;

int main() {
  unsigned int i;
  unsigned int ary[2][50];
  i = gi;
  ary[0][i-1] = 2;
  return ary[0][i-1];
}
