struct s {
	int y;
	struct {
		int x;
	};
} z;

int main(void){
	return z.y + z.x;
}


