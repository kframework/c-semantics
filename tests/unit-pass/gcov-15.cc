// PR gcov-profile/64634
// { dg-options "-fprofile-arcs -ftest-coverage" }
// { dg-do run { target native } }

extern "C" void exit(int);

void catchEx ()		// count(1)
{
  exit (0);	// count(1)
  try
  {}
  catch (int)
  {}
}

int main ()		// count(1)
{
  try
  {
    throw 5;		// count(1)
  }
  catch (...)		// count(1)
  {
    catchEx ();		// count(1)
  }
}

// { dg-final { run-gcov gcov-15.C } }
