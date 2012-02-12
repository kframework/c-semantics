// kcc-assert-error(00003)
int main(void){
	int x = 0;
	int y = 0;
	x + (y = 1);
	return 0;
}
