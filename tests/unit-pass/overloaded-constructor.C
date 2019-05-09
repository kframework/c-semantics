
// No best viable overload.
struct A {
  A(int){}
  A(A const &){}
};

int main() {
  A y(5); // direct-initialization
}
