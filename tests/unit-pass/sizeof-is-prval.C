// Tests that sizeof(_) can be used in initialization
// (and thus it has a value category).
int main()
{
	int x = sizeof(int);
	int y = sizeof(5);
}
