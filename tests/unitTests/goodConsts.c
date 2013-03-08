int main(void){
	int w = 3;
	const int x = 5;
	int const y = 6;
	const int a[2] = {7, 1};
	(const float []){1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6}[3];
	(const char []){"/tmp/fileXXXXXX"};
	
	const int* p = &x;
	p = &y;
	int* const q = &w;
	*q = 8;
	const int* const r = &a[0];
	return x + y + a[1] + *p + *q + *r;
}

