int f();

int main(void){
	int x = 5;
	int* p = &x;
	return f(p);
}

int f(const int * p){
	return *p;
}
