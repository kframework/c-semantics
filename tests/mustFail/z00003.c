// kcc-assert-error(00003)
int main(void){
	int x = 0;
	x + (x = 1);
	return 0;
}
