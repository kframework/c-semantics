#include<float.h>
#include<limits.h>
#include<stdlib.h>
int main(void) {
  char c; 

  signed char sic;
  char signed csi;

  unsigned char uc;
  char unsigned  cu;

  short sh;
  signed short sish;
  short signed shsi;
  short int shi;
  int short ish;
  signed short int sishi;
  signed int short siish;
  short signed int shsii;
  short int signed shisi;
  int short signed ishsi;
  int signed short isish;

  unsigned short ush;
  short unsigned shu;
  unsigned short int ushi;
  unsigned int short uish;
  short unsigned int shui;
  short int unsigned shiu;
  int short unsigned ishu;
  int unsigned short iush;

  int i;
  signed si;
  signed int sii;
  int signed isi;

  unsigned u;
  unsigned int ui;
  int unsigned iu;

  long l;
  signed long sil;
  long signed lsi;
  long int li;
  int long il;
  signed long int sili;
  signed int long siil;
  long signed int lsii;
  long int signed lisi;
  int signed long isil;
  int long signed ilsi;

  unsigned long ul;
  long unsigned lu;
  unsigned long int uli;
  unsigned int long uil;
  long unsigned int lui;
  long int unsigned liu;
  int unsigned long iul;
  int long unsigned ilu;

  long long ll;
  signed long long sll;
  long signed long lsl;
  long long signed lls;
  long long int lli;
  long int long lil;
  int long long ill;
  signed long long int silli;
  signed long int long silil;
  signed int long long siill;
  long signed long int lsili;
  long signed int long lsiil;
  int signed long long isill;
  long long signed int llsii;
  long int signed long lisil;
  int long signed long ilsil;
  long long int signed llisi;
  long int long signed lilsi;
  int long long signed illsi;

  unsigned long long ull;
  long unsigned long lul;
  long long unsigned llu;
  unsigned long long int ulli;
  unsigned long int long ulil;
  unsigned int long long uill;
  long unsigned long int luli;
  long unsigned int long luil;
  int unsigned long long iull;
  long long unsigned int llui;
  long int unsigned long liul;
  int long unsigned long ilul;
  long long int unsigned lliu;
  long int long unsigned lilu;
  int long long unsigned illu;

  float f;

  double d;

  long double ld;
  double long dl;

  _Bool b;

  #define sign(x) x = -1;
  #define unsign(x, type) x = type##_MAX;
  #define size(x, i) if (sizeof(x) != i) abort();
  #define f1(x) sign(x) size(x, 1)
  f1(sic);
  f1(csi);

  #define f2(x) unsign(x, UCHAR) size(x, 1)
  f2(uc);
  f2(cu);

  #define f3(x) sign(x) size(x, 2)
  f3(sh);
  f3(sish);
  f3(shsi);
  f3(shi);
  f3(ish);
  f3(sishi);
  f3(siish);
  f3(shsii);
  f3(shisi);
  f3(ishsi);
  f3(isish);

  #define f4(x) unsign(x, USHRT) size(x, 2)
  f4(ush);
  f4(shu); 
  f4(ushi);
  f4(uish);
  f4(shui);
  f4(shiu);
  f4(ishu);
  f4(iush);

  #define f5(x) sign(x) size(x, 4)
  f5(i);
  f5(si); 
  f5(sii); 
  f5(isi);

  #define f6(x) unsign(x, UINT) size(x, 4)
  f6(u);
  f6(ui);
  f6(iu);

  #define f7(x) sign(x) size(x, sizeof(long))
  f7(l);
  f7(sil);
  f7(lsi);
  f7(li);
  f7(il);
  f7(sili);
  f7(siil);
  f7(lsii);
  f7(lisi);
  f7(isil);
  f7(ilsi);

  #define f8(x) unsign(x, ULONG) size(x, sizeof(unsigned long))
  f8(ul);
  f8(lu);
  f8(uli);
  f8(uil);
  f8(lui);
  f8(liu);
  f8(iul);
  f8(ilu);

  #define f9(x) sign(x) size(x, 8); 
  f9(ll);
  f9(sll);
  f9(lsl);
  f9(lls);
  f9(lli);
  f9(lil);
  f9(ill);
  f9(silli);
  f9(silil);
  f9(siill);
  f9(lsili);
  f9(lsiil);
  f9(isill);
  f9(llsii);
  f9(lisil);
  f9(ilsil);
  f9(llisi);
  f9(lilsi);
  f9(illsi);

  #define g1(x) unsign(x, LLONG) size(x, 8);
  g1(ull);
  g1(lul);
  g1(llu);
  g1(ulli);
  g1(ulil);
  g1(uill);
  g1(luli);
  g1(luil);
  g1(iull);
  g1(llui);
  g1(liul);
  g1(ilul);
  g1(lliu);
  g1(lilu);
  g1(illu);

  #define g2(x) x = 3.40282346638528859812e+38F; size(x, 4);
  g2(f);

  #define g3(x) unsign(x, DBL) size(x, 8);
  g3(d);
 
  #define g4(x) unsign(x, LDBL) size(x, 16)
  g4(ld);
  g4(dl);

  #define g5(x) size(x, 1)
  g5(b);
}
