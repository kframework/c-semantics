extern "C" int puts(char const *);

struct E {
	int x = 0;
	E(){puts("E()");}
	~E(){puts("~E()");}
	E(E const &){puts("E(E const &)");}
};

int main() {
	try {
		throw E();
	} catch(E const &e) {}
	puts("---");
}
