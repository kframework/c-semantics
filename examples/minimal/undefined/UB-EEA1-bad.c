union { int i; char c; } ic;
int main(void){ 
	ic.c = ic.i;
	return ic.c;
}
