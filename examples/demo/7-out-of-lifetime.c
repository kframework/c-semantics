// Here we come to a slightly more complex example. When this example is run
// with gcc -O3, the value stored in z can be seen as expected when the
// program exits. However, if optimizations are disabled or if a different
// compiler is used, the layout of variables on the stack may change. This
// causes the call foo(255) to overwrite the same location in memory that
// was used for the integer z in the first call to foo. Because the variable
// z's lifetime has ended when foo returns, it is undefined for us to have
// returned a pointer to it from the function. Thus we find that the pointer
// x has an indeterminate value and can be changed by subsequent calls to 
// foo. As a result of this, we see the value 255 returned from main which
// is not what we expected. This again underscores the importance of avoiding
// undefined behavior in programs, because it can lead to unexpected behaviors
// like this.
int *foo(int x) {
  int z = x;
  int *y = &z;
  return y;
}

int main() {
  int *x = foo(0);
  foo(255);
  return *x;
}  
