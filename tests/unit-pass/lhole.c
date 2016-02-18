int main() {
int x = 0;
int y = 1;
int z = 1;
x += (y -= (1));
x += (z--);
x = x  - 1;
return x;
}
