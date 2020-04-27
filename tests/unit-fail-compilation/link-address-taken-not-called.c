extern void f(void);

void g() {}

typedef void(*func_adr)(void);

func_adr func_table[] = {f, g};

void target(int data){
	func_table[data - 1]();
}

int main(void){
	 target(2);
}
