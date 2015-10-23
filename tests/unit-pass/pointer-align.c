#include<stddef.h>
typedef struct ASN1_TEMPLATE_st ASN1_TEMPLATE;
struct ASN1_ITEM_st {
   char itype;

    long utype;
    const ASN1_TEMPLATE *templates;

    long tcount;
    const void *funcs;
    long size;

    const char *sname;


};
typedef struct ec_privatekey_st {
    long version;
    char *privateKey;
    char *parameters;
    char *publicKey;
} EC_PRIVATEKEY;
typedef struct ASN1_ITEM_st ASN1_ITEM;
const ASN1_ITEM LONG_it;
typedef const ASN1_ITEM ASN1_ITEM_EXP;
struct ASN1_TEMPLATE_st {
    unsigned long flags;
    long tag;
    unsigned long offset;

    const char *field_name;

    ASN1_ITEM_EXP *item;
};
static const ASN1_TEMPLATE EC_PRIVATEKEY_seq_tt[] = {
        { (0), (0), offsetof(EC_PRIVATEKEY, version), "version", (&(LONG_it)) },
} ; 
static const ASN1_ITEM EC_PRIVATEKEY_it = { 0x1, 16, EC_PRIVATEKEY_seq_tt, sizeof(EC_PRIVATEKEY_seq_tt) / sizeof(ASN1_TEMPLATE), ((void *)0), sizeof(EC_PRIVATEKEY), "EC_PRIVATEKEY" };

int main() {
  return 0;
}
