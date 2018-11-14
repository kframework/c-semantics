/* 
 * n4778 9.3.1/8
 * The destructor for each element of class type is potentially invoked
 * from the context where the aggregate initialization occurs.
 */

struct A {
	A(int){}
	~A();
};

// An aggregate
struct B {
	A a;
};

int main(){
	// An aggregate initialization
	B b{{1}};
}
