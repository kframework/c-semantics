// Copyright (C) 2003 Free Software Foundation, Inc.
// Contributed by Nathan Sidwell 30 Jul 2003 <nathan@codesourcery.com>

// make sure statement expressions work properly

// { dg-do run }
// { dg-options "" }

extern "C" int printf (char const *, ...);
extern "C" void abort ();

static unsigned order[] = 
{
  1, 101, 2, 102,
  3, 4, 104, 103,
  5, 6, 105, 106,
  7, 107, 8, 408, 9, 109, 108,
  10, 11, 110, 411, 12, 112, 111,
  13, 113,
  14, 114,
  0
};

static unsigned point;

static void Check (unsigned t, unsigned i, void const *ptr, char const *name)
{
  printf ("%d %d %p %s\n", t, i, ptr, name);
  
  if (order[point++] != i + t)
    abort ();
}

template <int I> struct A 
{
  A () { Check (0, I, this, __PRETTY_FUNCTION__); }
  ~A () { Check (100, I, this, __PRETTY_FUNCTION__); }
  A (A const &) { Check (200, I, this, __PRETTY_FUNCTION__); }
  A &operator= (A const &) { Check (300, I, this, __PRETTY_FUNCTION__); }
  void Foo () const { Check (400, I, this, __PRETTY_FUNCTION__); }
};

A<6> foo1() { return A<5>(), A<6>(); }
A<8> foo2() { A<7>(); return A<8>(); }
A<11> foo3() { return A<10>(), A<11>(); }
A<14> foo4() { A<14> a; return a; }

int main ()
{
  {A<1> (); A<2> (); ;}
  {A<3> (), A<4> (); ;}
  foo1();
  foo2().Foo (), A<9> ();
  foo3().Foo (), A<12> ();
  {A<13> a; a; ; }
  foo4();
  Check (0, 0, 0, "end");
}
