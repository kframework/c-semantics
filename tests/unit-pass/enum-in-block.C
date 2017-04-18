extern "C" void abort();
#define assert(e) if(!(e)) abort();

int foo()
{
	enum E { A = 5 };
	return (int)A;
}

int bar()
{
	enum E { A = 7 };
	{ int x = (int)E::A + 1;} // nested block
	return (int)A + 1;
}

int main()
{
	enum E { A = 4, B };
	E e = A;
	int x = (int)A;
	assert(x == 4);

	int y = foo();
	assert(y == 5);

	assert(bar() == 8);

	x = (int)B;
	assert(x == 5);
}
