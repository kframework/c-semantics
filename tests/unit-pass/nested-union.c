union UN_1{
	int j;
};

union UN_ {
	int d1;
	union UN_1 d2;
};

union UN_ un_data;

int main(void){
	un_data.d2.j = 20;
	return 0;
}

