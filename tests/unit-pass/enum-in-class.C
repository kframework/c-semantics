extern "C" void abort();
#define assert(x) if(!(x)) abort()

constexpr int a = 4;
struct C {
	enum Enum {
		a = 5,
		b = a*2
	};

	static void foo() {
		Enum e1 = Enum::a;
		assert((int)e1 == 5);

		Enum e2 = Enum::b;
		assert((int)e2 == 10);

		assert(::a == 4);
		Enum e3 = a;
		assert((int)e3 == 5);
	}
};

int main() {
	C::Enum e1 = C::a;
	assert((int)e1 == 5);

	// This does not work yet
	//C::Enum e2 = C::Enum::b;
	//assert((int)e2 == 10);

	C::foo();
}
