// kcc-assert-error(00043)
struct S1 {
	int x;
} s1;
struct S2 {
	int x;
} s2;

int main(void){
	5 ? s1 : s2;
}
