int f(int (*x)[], int num){
	int sum = 0;
	for (int i = 0; i < num; i++){
		sum += (*x)[i];
	}
	return sum;
}

int main(void){
	int arr[3] = {1, 2, 3};
	int (*z)[] = &arr;
	if (f(z, 3) != 6){
		printf("Bug\n");
	}
	return 0;
}
