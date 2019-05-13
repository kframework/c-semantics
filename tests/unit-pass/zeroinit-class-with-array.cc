extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct WithArray {
	virtual void foo(){};
	int a[4];
};

int main() {
	WithArray w{};
	assert(w.a[0] == 0);
	assert(w.a[1] == 0);
	assert(w.a[2] == 0);
	assert(w.a[3] == 0);
}
