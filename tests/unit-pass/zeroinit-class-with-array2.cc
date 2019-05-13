extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct WithArray {
	int a[4];
};

struct S {
	virtual void foo(){};
	WithArray w;
};

int main() {
	S s{};
	assert(s.w.a[0] == 0);
	assert(s.w.a[1] == 0);
	assert(s.w.a[2] == 0);
	assert(s.w.a[3] == 0);
}
