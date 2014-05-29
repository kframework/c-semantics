int main(void){
	int* p;
	{ int x; p = &x; }
	*p;
	return 0;
}
