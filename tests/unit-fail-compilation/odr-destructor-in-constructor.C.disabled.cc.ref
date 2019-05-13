/* In a non-delegating constructor,
 * the destructor for each potentially constructed subobject of class type is potentially invoked.
 */

struct A {
	~A();
};

struct B {
	A a;
	B(){}
};

int main(){}
