extern "C" int puts(const char *);

struct A{
	A() {puts("A()");}
	~A(){puts("~A()");}
};

struct B {
	A a1; A a2;
};
A bad(){throw 3;}

int main() {
	try {
		B b{{}, bad()};
	} catch(...) {}
}

