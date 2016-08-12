template<typename> class X;

template <typename T> void foo(class X<T> *t);

int main() {
  class X<int> *t = nullptr;
  foo(t);
}
