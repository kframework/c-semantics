extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct A {
	int x1;
	int x2 = 3;
};

struct B {
	// it is not an aggregate type
	virtual void foo(){};
	int y1 = 1;
	A a;
	int y2;
};

int main() {
	B b{};
	assert(b.y1 == 1);
	assert(b.y2 == 0);
	assert(b.a.x1 == 0);
	assert(b.a.x2 == 3);
}
