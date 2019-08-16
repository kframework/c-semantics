struct S{
	S(){}
	S(int, float){}
	S(int) {}
};

int main() {
	S s1 = S(1);
	S s2 = S{2};
	S s3 = S(3,4);
	S s4 = S();	
}
