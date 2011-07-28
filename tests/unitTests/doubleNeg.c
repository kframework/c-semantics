int main() {
	return ((unsigned int)(~((unsigned int)~0)) != 0);
}

// 0000 (int, 0)
// 1111 (int, -8)
// 1111 (unsigned int, 15)
// 0000
