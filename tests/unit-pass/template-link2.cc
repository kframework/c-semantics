template<typename T> class X {};

template <typename T> void foo(class X<T> *t) {}

template void foo<int>(class X<int> *t);
