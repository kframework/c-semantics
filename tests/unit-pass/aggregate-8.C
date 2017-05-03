struct Y { int x, y; };
struct X { int j = 6; Y k = {1, j}; };
int main () {
 X a{};
 return a.j - a.k.y;
}