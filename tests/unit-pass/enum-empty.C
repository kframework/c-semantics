extern "C" void abort();

enum E : int {};

E e;

int main() {
	E f = e;
	E * g = nullptr;

	if (sizeof(e) != sizeof(int))
		abort();
}
