extern "C" int puts(const char *);
struct A{
	A() {puts("A()");}
	~A(){puts("~A()");}
	A(A const &){puts("A(A const &)");}
};
A foo(){return {};}

void test1() {
	A a = foo();
}

struct B{
	B() {puts("B()"); throw 5;}
	~B(){puts("~B()");}
	B(B const &){puts("B(B const &)");}
};

B bar(){return {};}

void test2() {
	try {
		B b = bar();
	} catch(...){}
}

int main() {
	test1();
	test2();
}
