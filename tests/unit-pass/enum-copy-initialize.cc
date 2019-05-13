enum class E { Val = 7 };
enum F { F_Val = 8 };

int main() {
	E e1 = E::Val;
	E e2 = e1;

	F f1 = F_Val;
	F f2 = f1;
}
