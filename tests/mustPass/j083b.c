struct s {
	int x;
	int y;
};

int main(void){
	struct s t0 = {0, 1};
	struct s s0 = t0;
	return s0.x;
}
