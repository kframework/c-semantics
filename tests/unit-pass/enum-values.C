/*
 * Tests enum values. Only values inside the range are tested,
 * and lines which should cause runtime error are commented out.
 */

// b_max >= max(-1, 1) = 1
// b_max = 1
// b_min = 0
enum E {
	E_0, E_1
};

// b_max >= max(-1, 4) = 4
// b_max = 7
// b_min = 0
enum F {
	F_4 = 4, F_0 = 0
};

// b_max >= max(0, 1) = 1
// b_max = 1
// b_min = -(1 + 1) = -2
enum G {
	G_1 = -1
};

// b_max >= max(1, 2) = 2
// b_max = 3
// b_min = -(3 + 1) = -4
enum H {
	H_2 = -2
};

void test_E(int value)
{
	E e = (E)value;
}

void test_F(int value)
{
	F f = (F)value;
}

void test_G(int value)
{
	G g = (G)value;
}

void test_H(int value)
{
	H h = (H)value;
}

int main()
{
	test_E(0);
	test_E(1);
	//test_E(2); // fails, out of range
	//test_E(-1); // similarly

	test_F(0);
	test_F(1);
	test_F(2);
	test_F(3);
	test_F(4);
	test_F(5);
	test_F(6);
	test_F(7);
	//test_F(8);
	//test_F(-1);
	
	test_G(-2);
	test_G(-1);
	test_G(0);
	test_G(1);
	//test_G(-3);
	//test_G(2);
	
	for (int i = -4; i <= 3; i++)
		test_H(i);

	//test_H(-5);
	//test_H(4);
}
