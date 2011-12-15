// kcc-assert-error(00001)
int f(void) {
	return 0;
}
int main(void){
	f() + 0;
}
