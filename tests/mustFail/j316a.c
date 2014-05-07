// kcc-assert-error(00003)
int main(void){
	int x = 0;
	(x = 1) + x;
	return 0;
}
