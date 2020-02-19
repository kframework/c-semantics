union UN_1{
	int j;
};

union UN_ {
	int d1;
	union UN_1 d2;
};

union UN_ un_data;


union UN_ func(void){
	un_data.d1 = 0;
	un_data.d2.j = 20;
	
	return un_data; 
}

int main(void){
	union UN_ data;
	data = func();
	return 0;
}

