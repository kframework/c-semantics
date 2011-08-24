struct s {
	int x;
};

int f(const struct s x){
	return x.x;
}

int main(void){
	struct s s0 = {0};
	return f(s0);
}
