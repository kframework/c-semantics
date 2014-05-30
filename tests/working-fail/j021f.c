union U0 {
	int x;
};

void f (union U0 u){}

int main(void){
	union U0 u;
	f(u);
}
