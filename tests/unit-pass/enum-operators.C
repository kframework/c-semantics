extern "C" void abort();
#define assert(x) if(!(x)) abort()

enum class E { A = 7, B = 9 };

int main() {
	E e = E::A;
	e = E::B;
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
}
