// 6.7.4p7
// This also counts as a declaration of f with external linkage, but not as an
// external definition. Therefore, this should be a link error.
inline int f(void) { return 0; }

int main(void) {
      return f();
}
