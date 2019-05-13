// Test for extension to allow incomplete types in an
// exception-specification for a declaration.

// { dg-do run }
// { dg-options "-fpermissive -w" }

struct A;
struct A {};

struct B
{
  void f () throw (A);
};


void B::f () throw (A) {}

int main ()
{
  B b;
  b.f();
}
