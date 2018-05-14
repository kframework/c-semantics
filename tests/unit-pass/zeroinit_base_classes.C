extern "C" void abort();
#define assert(x) if(!(x)) abort();

/* zero initialization of base classes */

class Base {
	public:
		int x;
};

class Derived : public Base {
	public:
	// Ensure it is not an aggregate type
	virtual void foo(){};

	int y;
};

int main() {
	Derived d{};
	assert(d.x == 0);
	assert(d.y == 0);
}
