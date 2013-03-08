int main(void) {
	int count = 0;
	label: ;
	int x;
	int y = 1;
	static int z;
	if (count < 1){
		count++;
		goto label;
	}
	return 0;
}
