template<typename T> class X {};

template <typename T> void foo(class X<T> *t) {}

template void foo<int>(class X<int> *t);

template <typename T> T id(T x) { return x; }

template const char * id<const char *>(const char * t);
template int id<int>(int t);
