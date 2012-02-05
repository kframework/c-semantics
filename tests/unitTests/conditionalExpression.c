struct S {
	int x;
	int y;
};

union U {
	int x;
	int y;
};

int main(void){
	struct S s1 = {0};
	struct S s2 = {0};
	union U u1 = {0};
	union U u2 = {0};
	
	int foo = 5;
	int a = 5;
	const int b = 6;
	
	// both operands have arithmetic type;
	foo ? (int)5 : (char)6;
	foo ? (float)5 : (char)6;
	
	// both operands have the same structure or union type;
	foo ? s1 : s2;
	foo ? u1 : u2;
	
	// both operands have void type;
	foo ? (void)5 : (void)6;
	
	// both operands are pointers to qualified or unqualified versions of compatible types;
	foo ? &a : &b;
	foo ? (int*)&a : (int*)&b;

	// one operand is a pointer and the other is a null pointer constant; or
	foo ? &a : 0;
	foo ? 0 : &a;
	
	// one operand is a pointer to an object type and the other is a pointer to a qualified or unqualified version of void.
	foo ? (int*)&a : (void*)&b;
	foo ? (int*)&a : (const void*)&b;
	foo ? (void*)&a : (int*)&b;
	
}
