// 6.7.4p7
// This also counts as a declaration of f with external linkage, but not as an
// external definition.
inline int f(void) { return 0; }

// This makes the definition above an "external definition."
extern int f(void) ;

int main(void) {
      return f();
}
