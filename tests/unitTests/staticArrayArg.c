int f(int a[static 3]){
	return a[0] + a[1] + a[2];
}

int main(void){
	int a[] = {1, 2, 3, 4, 5};
	return f(a);
}
