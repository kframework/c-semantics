// kcc-assert-error(00035)
int main(void){
	int x = 5;
	int y = 0;
	const int* p = &x;
	*p = &y;
	return *p;
}
