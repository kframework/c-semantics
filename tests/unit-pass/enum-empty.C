extern "C" void abort();

enum E : int {};

E e;

namespace N { enum E : char{}; }

int main() {
	E f = e;
	E * g = nullptr;

	if (sizeof(e) != sizeof(int))
		abort();

	if (sizeof(enum N::E) != sizeof(char))
		abort();
}
