//  8.5.1:2
struct X { int i, j, k = 42; };
X a[] = { 1, 2, 3, 4, 5 };
X b[2] = { { 1, 2, 3 }, { 4, 5, 6 } };
int main () {
 return a[1].k - 7*b[1].k;
}