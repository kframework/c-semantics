// The two functions contains
// a local variable with different name
void same_local_variable_1() {
	constexpr int x = 3;
}
void same_local_variable_2() {
	constexpr int x = 4;
}

constexpr int foo0() {
	return 3;
}

constexpr int foo1() {
	int x = 4;
	int y = x;
	return y;
}

constexpr int foo2(int x) {
	return 2*x;
}

constexpr int foo3(int x) {
	return x >= 3 ? 3 : x;
}

constexpr int foo4(int x) {
	if (x >= 0)
		return x;
	else
		return -x;
}

int test_basic() {
	constexpr int c0 = foo0(); // 3
	enum class E0 {
		A = c0 // 3
	};

	constexpr int c1 = foo1(); // 4
	enum class E1 {
		A = c1 // 4
	};

	constexpr int c2 = foo2(3); // 6
	enum class E2 {
		A = c2 // 6
	};

	constexpr int c3_1 = foo3(1); // 1
	constexpr int c3_4 = foo3(4); // 3
	enum class E3 {
		A = c3_1, // 1
		B = c3_4 // 3
	};

	constexpr int c4_2 = foo4(2); // 2
	constexpr int c4_m2 = foo4(-2); // 2
	enum class E4 {
		A = c4_2, // 2
		B = c4_m2 // 2
	};

	return (1 + int(E0::A) - 3)
		* (1 + int(E1::A) - 4)
		* (1 + int(E2::A) - 6)
		* (1 + int(E3::A) - 1)
		* (1 + int(E3::B) - 3)
		* (1 + int(E4::A) - 2)
		* (1 + int(E4::B) - 2)
		- 1;
}

constexpr int fact(int n) {
	return n <= 1 ? 1 : n * fact(n - 1);
}

int test_fact() {
	constexpr int g_1 = fact(1);
	constexpr int g_4 = fact(4);

	enum class Facts {
		F_1 = g_1,
		F_2 = fact(2),
		F_3 = fact(3),
		F_4 = g_4,
		F_5 = fact(5)
	};
	return (1 + int(Facts::F_1) - 1)
		* (1 + int(Facts::F_2) - 2)
		* (1 + int(Facts::F_3) - 6)
		* (1 + int(Facts::F_4) - 24)
		* (1 + int(Facts::F_5) - 120)
		- 1;
}

constexpr int fact2(int n) {
	int f = 1;
	while (n > 0) {
		f = f * n;
		n = n - 1;
		// TODO:
		// n -= 1;
	}
	return f;
}


int test_fact2() {
	constexpr int f_1 = fact2(1);
	constexpr int f_4 = fact2(4);

	enum class Facts {
		F_1 = f_1,
		F_2 = fact2(2),
		F_3 = fact2(3),
		F_4 = f_4,
		F_5 = fact2(5)
	};
	return (1 + int(Facts::F_1) - 1)
		* (1 + int(Facts::F_2) - 2)
		* (1 + int(Facts::F_3) - 6)
		* (1 + int(Facts::F_4) - 24)
		* (1 + int(Facts::F_5) - 120)
		- 1;
}

int main() {
	return (1 + test_basic())
		* (1 + test_fact())
		* (1 + test_fact2())
		- 1;
}

