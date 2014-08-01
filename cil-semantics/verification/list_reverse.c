//#include <stdlib.h>

struct listNode {
  int val;
  struct listNode *next;
};


struct listNode* reverse(struct listNode *x)
/*@ rule <k> $ => return ?p; ...</k>
         <heap>... list(x)(A) => list(?p)(rev(A)) ...</heap> */
{
  struct listNode *p;

  p = NULL;
  //@ inv <heap>... list(p)(?B), list(x)(?C) ...</heap> /\ A = rev(?B) @ ?C
  while(x != NULL) {
    struct listNode *y;

    y = x->next;
    x->next = p;
    p = x;
    x = y;
  }

  return p;
}

int main() {
  struct listNode *x = NULL;
  int n = 5;
  while (n) {
    struct listNode *y = x;
    x = (struct listNode*) malloc(sizeof(struct listNode));
    x->val = n;
    x->next = y;
    n -= 1;
  }

  x = reverse(x);

  return 0;
}

