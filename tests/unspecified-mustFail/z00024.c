// kcc-assert-error(00024)
int main(void){
	int x = 0;
	(int)(&x) & 7;
}

