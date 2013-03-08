struct s {
	int x;
	int y;
};

struct t {
	char x;
	int y;
};

int main(void){
	struct t t0 = {0, 1};
	struct s s0 = t0;
	return s0.x;
}
