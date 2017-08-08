//  8.5.1:2
struct Y { int x, y; };
struct X { int i, j; Y k = {7, 8}; };
X a[] = { 1, 2, 3, 4, 5, 6, 1, 2 };
int main () {
 return a[1].j - 3*a[1].k.y;
}