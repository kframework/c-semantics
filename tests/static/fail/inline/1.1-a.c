// 6.7.4p7
// This also counts as a declaration of f with external linkage, but not as an
// external definition.
// 
// Because there's also an external definition of f(), it's unspecified which
// one should be chosen (this isn't an error, really). GCC really should
// compile this but KCC probably shouldn't.
inline int f(void) { return 0; }

int main(void) {
      return f();
}
