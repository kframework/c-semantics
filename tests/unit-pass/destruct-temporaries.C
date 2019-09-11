extern "C" void abort();
#define assert(x) if(!(x)) abort();

int x = 0;
struct A {
	A(){}
	A(int){}
	A(int, int){}
	~A(){x++;}
};

int foo(A const &r){return 0;}
int bar(A const &r){throw 5;}

struct B {
	int x;
	B() : x(foo(A(5,6))){}
	B(int) : x(bar(A(7,8))){}
};


// TODO conversion from int
void goo(A const &r = A(2,3)){}

int main() {
	A();
	assert(x == 1);

	foo(A(1,2));
	assert(x == 2);

	try {
		bar(A(3,4));
	} catch(...) {
		assert(x == 3)
	}

	B b1;
	assert(x == 4);

	try {
		B b2{0};
	} catch(...) {
		assert(x == 5);
	}

	goo();
	assert(x == 6);

	A(3);
	assert(x == 7);
}
