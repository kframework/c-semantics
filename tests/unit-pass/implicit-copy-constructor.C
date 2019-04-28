extern "C" void abort();
#define assert(x) if(!(x)) abort();

// const-version of copy constructors

struct B1 {
	int x;
	B1(){}
	B1(B1 const &b) : x(b.x + 1) {}
};

struct S1 : B1{
	int y;
};

S1 foo1() {
	S1 s;
	s.x = 1;
	s.y = 3;
	return s;
}

void test1() {
	S1 a;
	a.x = 3;
	a.y = 7;
	S1 b = a;
	assert(b.x == 4);
	assert(b.y == 7);
	foo1();
	// S1 c = foo1(); // does not work yet
	//assert(c.y == 3);
}

// non-const version of copy constructors
struct B2 {
	int x;
	B2(){}
	B2(B2 /*non-const*/ &b) : x(b.x + 1) {}
};

struct S2 : B2{
	// implicitly generated:
	// S2(S2 /*non-const*/ &s) : B2(s), y(s.y) {}
	int y;
};

#if 0
S2 foo2() {
	S2 s;
	s.x = 1;
	s.y = 3;
	return s;
}
#endif
void test2() {
	S2 a;
	a.x = 3;
	a.y = 7;
	S2 b = a;
	assert(b.x == 4);
	assert(b.y == 7);
	foo1();
	// S1 c = foo1(); // does not work yet
	//assert(c.y == 3);
}

int main() {
	test1();
	test2();
}
