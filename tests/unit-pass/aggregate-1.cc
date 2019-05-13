// @ref n4296  8.5.1:2
struct A {
  int x;
  struct B {
    int i;
    int j;
  } b;
} a = { 1, { 2, 3 } };
 int main () {
 return a.b.i - 2;
}
