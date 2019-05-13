extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct Base {
	int x;

	int const & getx() const {
		return x;
	}
};

struct Middle : Base {};


struct Derived : Middle {

};

int main() {
	Derived d;
	d.x = 5;
	assert(d.x == 5);

	Base & b = d;
	assert(&d.x == &b.x);
	assert(&d.x == &d.getx());
}
