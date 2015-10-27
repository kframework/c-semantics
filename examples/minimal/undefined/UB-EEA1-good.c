union { int i; int c; } ic;
int main(void){ 
	ic.c = ic.i;
	return ic.c;
}
