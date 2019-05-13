extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct Base1 {
	int x;

	int const & getx() const {
		return x;
	}
};

struct Base2 {
	int y;

	int const & gety() const {
		return y;
	}
};

struct Middle1 : Base1 {};
struct Middle2 : Base2 {};


struct Derived : Middle1, Middle2 {

};

int main() {
	Derived d;
	d.x = 5;
	d.y = 6;
	assert(d.x == 5);

	Base1 & b1 = d;
	Base2 & b2 = d;

	assert(&d.x == &b1.x);
	assert(&b1.x != &b2.y);
	assert(&d.x != &d.y);
	assert(&d.y == &b2.y);
	assert((void *)&b1 != (void *)&b2);
	assert(&b1.getx() == &b1.x);
	assert(&b2.gety() == &b2.y);
}
