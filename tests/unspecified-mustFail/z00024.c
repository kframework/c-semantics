// kcc-assert-error(00024a)
int main(void){
	int x = 0;
	(int)(&x) & 7;
}

