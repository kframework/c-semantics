extern "C" void abort();
#define assert(x) if(!(x)) abort()

enum class E { A = 7, B = 9 };

E & hoo() {
	static E e = E::B;
	return e;
}

enum UE { UE_C = 67 };

void foo(E /*e*/) {

}

void assign_to_enum() {
	E e = E::A;
	e = E::B;
	E const f = E::A;
	E & r = e;
	r = f;
	foo(r);
	foo(hoo() = e);
	assert((int)hoo() == (int)e);
}

E volatile & goo() {
	static E volatile e = E::A;
	return e;
}

void assign_to_volatile_enum() {
	E e = E::A;
	volatile E g = E::B;
	E const f = E::A;
	e = g;
	e = f;
	g = e;
	g = E::A;
	goo() = f;
	assert((int)goo() == (int)f);
}

void assign_to_int() {
	UE ue = UE_C;
	int x = 5;
	x = ue;
	assert(x == (int)UE_C);
}

int main() {
	assign_to_enum();
	assign_to_volatile_enum();
	assign_to_int();
#if 0
	assert(E::A < E::B);
	assert((int)e == (int)E::B);
	E * p_e = &e;
	E f = *p_e;
	assert(f <= e);
	assert(f == e);
	assert(f >= e);

	e = E::B;
	f = E::A;
	assert(!(e == f));
	assert(e != f);
	assert(e > f);
	assert(!(e < f));
	assert(!(e <= f));

	volatile E h = E::A;
	volatile E k = E::B;
	assert(h != k);
	k = h;
	assert(h == k);

	const E g = E::A;
	assert(E::A == g);
	assert(g != E::B);

	e = g;
	assert(e == g);
#endif
}
