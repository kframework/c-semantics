extern "C" int puts(const char *);

struct A{
	A() {
		puts("A()");
	}
	~A(){puts("~A()");}

	A(A const &){
		puts("A(A const &)");
	}
};

struct B {
	~B(){puts("~B()");}
	A a1; A a2;
};

A bad(){throw 3;}

void line() {
	puts("---");
}

void test_1() {
	puts("<test1>");
	try {
		B b{{}, bad()};
		line();
	} catch(...){}
	puts("</test1>");
}

void test_2() {
	puts("<test2>");
	{
		B b{};
		line();
	}
	puts("</test2>");
}

struct C {
	C(){puts("C()");}
	~C(){puts("~C()");}
	B b{};
	A a[1]{};
};

void test_3() {
	puts("<test3>");
	{
		C c; // should not call destructors
		line();
	}
	puts("</test3>");
}

struct D {
	D(){puts("D() throwing"); throw 4;}
	~D(){puts("~D()");}
	B b1{};
};

void test_4() {
	puts("<test4>");
	try{
		//
		D d;
		line();
	} catch(...){}
	puts("</test4>");
}

int main() {
	test_1();
	test_2();
	test_3();
	test_4();
}

