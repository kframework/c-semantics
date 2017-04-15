extern "C" void abort();
#define assert(x) if(!(x)) abort()

/* Opaque enum declaration before full */
enum class E1 : int;
enum class E1 : int;

E1 e1 = (E1)5;

void test_1() {
	assert((int)e1 == 5);
}

enum class E1 : int { A = 5 };

void test_2() {
	assert((int)e1 == (int)E1::A);
}

/* opaque enum declaration after full */

enum class E1 : int;

int main() {
	test_1();
	test_2();
}

