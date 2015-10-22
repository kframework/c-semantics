struct S0
{
  const unsigned f0:((54 > 32) ? (54 % 32) : 54);
  unsigned f1:((53 > 32) ? (53 % 32) : 53);
  signed f2:((46 > 32) ? (46 % 32) : 46);
  unsigned f4:((62 > 32) ? (62 % 32) : 62);
  signed f5:((37 > 32) ? (37 % 32) : 37);
};
struct S0 g_39 = {
  0, 2, 3, 4, 5
};

int main(void){
	return g_39.f0;
}
