extern "C" void abort();
#define assert(x) if(!(x))abort()
int main() {
	constexpr int a = 5;
	constexpr int b = a + 1; 
	int const & r = b;
	assert(r == 6);
	int const * p = &b;
	assert(*p == 6);
}
