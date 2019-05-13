// If a class has multiple base class,
// they are located at different offsets.
// @tags: multiple-inheritance offset

extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct Base1 {
	Base1(){}
	~Base1(){}
	int x;

	int const & getx() const {
		return x;
	}
};

struct Base2 {
	Base2(){}
	~Base2(){}
	int y;

	int const & gety() const {
		return y;
	}
};


struct Derived : Base1, Base2 {
	Derived(){}
	~Derived(){}
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
}
