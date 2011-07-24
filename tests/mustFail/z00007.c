// kcc-assert-error(00007)
int main(void){
	int* p;
	{ int x; p = &x; }
	*p;
	return 0;
}
