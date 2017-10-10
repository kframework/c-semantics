extern "C" void abort();
#define assert(x) if(!(x)) abort();

struct Def {
	int x;
	int y = 7;
	int z;
	int t = 5;
};

int main() {
	Def def;
	assert(def.y == 7);
	assert(def.t == 5);
}
