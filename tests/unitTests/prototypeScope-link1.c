extern int f(void);

int blah (struct s {int a; int b;} c){
	return c.a;
}

int main(void) {
	return f();
}
