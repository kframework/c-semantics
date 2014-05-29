int f(p) 
int* p;
{
	return *p;
}
int main(void){
	int x = 0;
	return f(&x);
}

