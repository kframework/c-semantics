extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct A {
	char c1;
	int i1;
	char c2;
	int i2;
};

// Make sure class A is zero-initialized although it is an aggregate type
struct B {
	virtual void foo(){}
	A a;
};

int main() {
	B my_b{};

	assert(my_b.a.c1 == 0);

	// It does not work without the int cast.
	int const alig_size_1 = int(((char *)&my_b.a.i1 - &my_b.a.c1) - sizeof(my_b.a.c1));
	assert(alig_size_1 > 0);
	for (int i = 0; i < alig_size_1; i++) {
		assert(*(&my_b.a.c1 + 1 + i) == 0);
	}

	int const alig_size_2 = int(((char *)&my_b.a.i2 - &my_b.a.c2) - sizeof(my_b.a.c2));
	assert(alig_size_2 > 0);
	for (int i = 0; i < alig_size_2; i++) {
		assert(*(&my_b.a.c2 + 1 + i) == 0);
	}
}
