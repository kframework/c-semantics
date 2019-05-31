int ret = 1;

void foo(int &&) {
	ret--;
}

struct T{
	int a;
};


int main() {
	T t;
	//foo(t.a); // nope
	T && s = static_cast<T &&>(t);
	//foo(s.a); //nope
	
	foo(static_cast<T &&>(t).a);
	return ret;
}
