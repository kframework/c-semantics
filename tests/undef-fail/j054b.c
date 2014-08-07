struct big_type {
      int arr[32];
};
union u {
      struct s1 { char c; struct big_type bt1; } sub1;
      struct s2 { long long x; struct big_type bt2; } sub2;
} obj;

int main(void) {
      obj.sub2.bt2 = obj.sub1.bt1;

      return 0;
}
