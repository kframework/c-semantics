/**
 * Tests enumerator values and types.
 */

#include <limits.h>

extern "C" void abort();
#define assert(x) if(!(x)) abort()

enum Empty{};
enum WithZero { Zero = 0 };

void check_1()
{
	// Consequence of 7.2:7
	assert(sizeof(Empty) == sizeof(WithZero));
}

enum class E1 {
	A=3,       // 3
	B=E1::A-1,  // 2
	C=4*B-A    // 5
};

void check_2()
{
	assert(((int)E1::A) == 3);
	assert((int)E1::B == 2);
	assert((int)E1::C == 5);
}

enum E2
{
	E2_A = UINT_MAX, // type: unsigned
	E2_B, // type: > unsigned (e.g. long) due to 7.2:5.3
	sizeof_E2_A = sizeof(E2_A),
	sizeof_E2_B = sizeof(E2_B)
};

void check_3()
{
	assert((int)sizeof_E2_A < (int)sizeof_E2_B);
}

enum class E3 {
	D=sizeof(E3) // sizeof(int), which is the implicit underlying type
};

enum E4 : int {
	E=sizeof(E4) // sizeof(int)
};

void check_4()
{
	assert((int)E3::D == sizeof(int));
	assert((int)E4::E == sizeof(int));
}

enum E5 {
	// F=sizeof(E5) // should not pass, this is an incomplete type
	G = 'a',
	H = sizeof(G), // 1, because here the type of G is the type of 'a'
	J,K,
	_last_E5 = 65535
};

void check_5()
{
	// Here the type of E5::G is E5
	assert(sizeof(E5::G) >= 2);
	assert(sizeof(E5::G) == sizeof(E5));
	assert((int)E5::H == sizeof(char));
	assert((int)E5::J == 2);
	assert((int)E5::K == 3);
}

enum E6
{
	// The type is 'char'
	E6_A = 'a',
	// The type is 'char' again (7.2:5.3)
	E6_B,

	sizeof_E6_A = sizeof(E6_B),
	sizeof_E6_B = sizeof(E6_B)
};

void check_6()
{
	assert((int)sizeof_E6_A == (int)sizeof_E6_B);
}

enum E7
{
	E7_A = 0ull,
	E7_B = sizeof(E7_A)
};

void check_7()
{
	// Type of E7_A inside the enumeration
	// should be 'unsigned long long'
	assert((int)E7_B == sizeof(unsigned long long));
}

enum E8 : int
{
	E8_A = 10
};

enum E9
{
	// Type of E9_A here should be
	// the underlying type of E8, which is 'int'
	E9_A = E8_A,
	E9_B = sizeof(E9_A)
};

void check_8()
{
	assert((int)E9_B == sizeof(int));
}

int main()
{

	check_1();
	check_2();
	check_3();
	check_4();
	check_5();
	check_6();
	check_7();
	check_8();

	return 0;
}

