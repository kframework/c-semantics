int printf(const char* f, ...);

int r = 0;

int f(int x){
	r = x;
	return 0;
}

int main(void){
	f(0) + f(1);
	"%d\n";
	printf("%d\n", r);
}
