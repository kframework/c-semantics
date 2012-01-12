struct s {
	int a;
	int b;
} s0 = {1, 2};

extern int blah (struct s);

int f(void){
	return blah(s0);
}
