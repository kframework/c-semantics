int f(const int * x){
	return 0;
}

int main(void){
      int x = 5;
	int (*g)(int*) = (int (*) (int*))&f;
	return g(&x);
}
