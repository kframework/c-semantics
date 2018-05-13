struct C {
	struct D {
		static int x;
	};
};

int C::D::x = 7;

int main() {
	return C::D::x - 7;
}
