#include <stdlib.h>

struct listNode {
  int val;
  struct listNode *next;
};

struct listNode* bubble_sort(struct listNode* x)
/*@ rule <k> $ => return ?x; ...</k>
         <heap>... list(x)(A) => list(?x)(?A) ...</heap>
    if isSorted(?A) /\ seq2mset(A) = seq2mset(?A) */
{
  int change;

  if (x == NULL || x->next == NULL)
    return x;

  change = 1 ;
  /*@ inv <heap>... list(x)(?A) ...</heap>
          /\ ~(x = 0) /\ seq2mset(A) = seq2mset(?A)
          /\ (isSorted(?A) \/ ~(change = 0)) */
  while (change) {
    struct listNode* y;

    change = 0;
    y = x;
    /*@ inv <heap>... lseg(x, y)(?B), y |-> [?v, ?n], list(?n)(?C) ...</heap>
            /\ ~(x = 0) /\ seq2mset(A) = seq2mset(?B @ [?v] @ ?C)
            /\ (isSorted(?B @ [?v]) \/ ~(change = 0)) */
    while (y->next != NULL) {
      if (y->val > y->next->val) {
        int temp;

        change = 1;
        temp = y->val;
        y->val = y->next->val;
        y->next->val = temp;
      }
      y = y->next;
    }
  }

  return x;
}

struct listNode* insertion_sort(struct listNode* x)
/*@ rule <k> $ => return ?x; ...</k>
         <heap>... list(x)(A) => list(?x)(?A) ...</heap>
    if isSorted(?A) /\ seq2mset(A) = seq2mset(?A) */
{
  struct listNode* y;

  y = NULL;
  /*@ inv <heap>... list(y)(?B), list(x)(?C) ...</heap>
          /\ isSorted(?B) /\ seq2mset(A) = seq2mset(?B) U seq2mset(?C) */
  while (x != NULL) {
    struct listNode* n;

    n = x;
    x = x->next;
    n->next = NULL;
    if (y != NULL) {
      if (y->val < n->val) {
        struct listNode* z;

        z = y;
        /*@ inv <heap>... lseg(y,z)(?B), z |-> [?v,?n],
                          list(?n)(?C), n |-> [nval,0] ...</heap>
                /\ D = ?B @ [?v] @ ?C /\ ?v < nval */
        while (z->next != NULL && z->next->val < n->val) {
          z = z->next;
        }

        n->next = z->next;
        z->next = n;
      }
      else {
        n->next = y;
        y = n;
      }
    }
    else {
      y = n;
    }              
  }

  return y;
}

struct listNode* merge_sort(struct listNode* x)
/*@ rule <k> $ => return ?x; ...</k>
         <heap>... list(x)(A) => list(?x)(?A) ...</heap>
    if isSorted(?A) /\ seq2mset(A) = seq2mset(?A) */
{
  struct listNode* p;
  struct listNode* y;
  struct listNode* z;

  if (x == NULL || x->next == NULL)
    return x;

  y = NULL;
  z = NULL;
  /*@ inv <heap>... list(x)(?A), list(y)(?B), list(z)(?C) ...</heap>
          /\ seq2mset(A) = seq2mset(?A) U seq2mset(?B) U seq2mset(?C)
          /\ (len(?B) = len(?C) \/ len(?B) = len(?C) + 1 /\ x = 0) */
  while (x != NULL) {
    struct listNode* t;

    t = x;
    x = x->next;
    t->next = y;
    y = t;

    if (x != NULL) {
      t = x;
      x = x->next;
      t->next = z;
      z = t;
    }
  }

  y = merge_sort(y);
  z = merge_sort(z);

  if (y->val < z->val) {
    x = y;
    p = y;
    y = y->next;
  }
  else {
    x = z;
    p = z;
    z = z->next;
  }
  /*@ inv <heap>...lseg(x,p)(?A1),p|->[?v,?n],list(y)(?B),list(z)(?C) ...</heap>
          /\ seq2mset(A) = seq2mset(?A1 @ [?v]) U seq2mset(?B) U seq2mset(?C)
          /\ leq(seq2mset(?A1 @ [?v]), seq2mset(?B))
          /\ leq(seq2mset(?A1 @ [?v]), seq2mset(?C))
          /\ isSorted(?A1 @ [?v]) /\ isSorted(?B) /\ isSorted(?C) */
  while (y != NULL && z != NULL) {
    if (y->val < z->val) {
      p->next = y;
      y = y->next;
    }
    else {
      p->next = z;
      z = z->next;
    }

    p = p->next;
  }

  if (y != NULL)
    p->next = y;
  else
    p->next = z;

  return x;
}

struct listNode* append(struct listNode *x, struct listNode *y)
/*@ rule <k> $ => return ?x; ...</k>
         <heap>... list(x)(A), list(y)(B) => list(?x)(A @ B) ...</heap> */
{
  struct listNode *p;
  if (x == NULL)
    return y;

  p = x;
  /*@ inv <heap>... lseg(x, p)(?A1), list(p)(?A2) ...</heap> 
          /\ A = ?A1 @ ?A2 /\ ~(p = 0) */
  while (p->next != NULL) {
    p = p->next;
  }
  p->next = y;

  return x;
}

struct listNode* quicksort(struct listNode* x)
/*@ rule <k> $ => return ?x; ...</k>
         <heap>... list(x)(A) => list(?x)(?A) ...</heap>
    if isSorted(?A) /\ seq2mset(A) = seq2mset(?A) */
{
  struct listNode* p;
  struct listNode* y;
  struct listNode* z;

  if (x == NULL || x->next == NULL)
    return x;

  p = x;
  x = x->next;
  p->next = NULL;
  y = NULL;
  z = NULL;
  /*@ inv <heap>... p|->[v,0], list(x)(?A), list(y)(?B), list(z)(?C) ...</heap>
          /\ seq2mset(A) = {v} U seq2mset(?A) U seq2mset(?B) U seq2mset(?C)
          /\ leq(seq2mset(?B), {v}) /\ leq({v}, seq2mset(?C)) */
  while(x != NULL) {
    struct listNode* t;

    t = x;
    x = x->next;
    if (t->val < p->val) {
      t->next = y;
      y = t;
    }
    else {
      t->next = z;
      z = t;
    }
  }

  y = quicksort(y);
  z = quicksort(z);
  x = append(y, append(p, z));

  return x;
}
