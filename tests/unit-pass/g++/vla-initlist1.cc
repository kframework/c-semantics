// { dg-do run { target c++1y } }

#include <initializer_list>

struct A
{
  int i;
  A(std::initializer_list<int>) { }
  A(int i): i{i} { }
  ~A() {}
};

int x = 4;
int main(int argc, char **argv)
{
  { int i[4] = { 42, 42, 42, 42 }; }
  {
    A a[4] = { argc };
    if (a[1].i != 42)
      __builtin_abort ();
  }
}
