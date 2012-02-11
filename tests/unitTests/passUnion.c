union U {
	unsigned char f0;
} u = {5};

unsigned char f (union U x) {
	return x.f0;
}

int main(void){
	return f(u);
}
