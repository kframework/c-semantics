struct E {
	E(){}
	~E(){}
	E(E const &){}
	int x;
};

E foo() { 
	return E();
	//return {};
}

int main() {
	foo();
	//E(E());
	E e = E();
	try { throw E(); } catch(...){}
}
