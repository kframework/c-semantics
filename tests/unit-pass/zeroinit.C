extern "C" void abort();
#define assert(x) if(!(x)) abort();

// C is not an aggregate type (it has virtual function).
// Therefore value initialization should perform (only) zero initialization.
struct C {
	virtual void foo() {};
	int a;
	int c;
};

void test1() {
	C c{};
	assert(c.a == 0);
	assert(c.c == 0);
}

// D has non-trivial default constructor and is not an aggregate type.
// Therefore value initialization should perform zero initialization and then default initialization.
struct D {
	private:
	int m = 3; // It has to be there. Otherwise no zero initialization would happen.
	int p;
	public:
	int getm() const { return m; }
	int getp() const { return p; }
	int n;
};

void test2() {
	D d{};
	assert(d.getm() == 3);
	assert(d.getp() == 0);
	assert(d.n == 0);
}

int main() {
	test1();
	test2();
}
