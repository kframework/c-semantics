int main() {
	enum E{A=3};
	enum class F{B = A};
	return int(F::B) - 3;
}
