int main()
{
  static const int &i = 42;
  if (i != 42)
	return 1;
}

