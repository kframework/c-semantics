/*
 * Resulting type of relational operations should be bool
 * and thus should be comparable to bool.
 * This is essentially test for issue https://github.com/kframework/c-semantics/issues/267.
 */

int main()
{
	int x = 1;
	if (true == (x == 2))
		;
}
