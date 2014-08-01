#include <stdlib.h>

struct treeNode {
  int val;
  struct treeNode *left;
  struct treeNode *right;
};

int find_min(struct treeNode *t);

struct treeNode* delete(int v, struct treeNode *t)
/*@ rule <k> $ => return ?t; ...</k>
         <heap>... tree(t)(T) => tree(?t)(?T) ...</heap>
    if isBst(T) /\ isBst(?T) /\ tree2mset(?T) = diff(tree2mset(T), {v}) */
{
  int min;

  if (t == NULL)
    return NULL;

  if (v == t->val) {
    if (t->left == NULL) {
      struct treeNode *tmp;

      tmp = t->right;
      free(t);

      return tmp;
    }
    else if (t->right == NULL) {
      struct treeNode *tmp;

      tmp = t->left;
      free(t);

      return tmp;
    }
    else {
      min = find_min(t->right);
      t->right = delete(min, t->right);
      t->val = min;
    }
  }
  else if (v < t->val)
    t->left = delete(v, t->left);
  else
    t->right = delete(v, t->right);

  return t;
}

int find(int v, struct treeNode *t)
/*@ rule <k> $ => return r; ...</k> <heap>... tree(t)(T) ...</heap>
    if isBst(T) /\ (~(r = 0) <==> in(v, tree2mset(T))) */
{
  if (t == NULL) return 0;
  if (v == t->val) return 1;
  if (v < t->val) return find(v, t->left);
  return find(v, t->right);
}

struct treeNode* insert(int v, struct treeNode *t)
/*@ rule <k> $ => return ?t; ...</k>
         <heap>... tree(t)(T) => tree(?t)(?T) ...</heap>
    if isBst(T) /\ isBst(?T) /\ tree2mset(?T) = tree2mset(T) U {v} */
{
  if (t == NULL)
    return new_node(v);

  if (v < t->val)
    t->left = insert(v, t->left);
  else
    t->right = insert(v, t->right);

  return t;
}

int find_min(struct treeNode *t)
/*@ rule <k> $ => return m; ...</k> <heap>... tree(t)(T) ...</heap>
    if ~(t = 0) /\ isBst(T) /\ in(m, tree2mset(T)) /\ leq({m}, tree2mset(T)) */
{
  if (t->left == NULL) return t->val;
  return find_min(t->left);
}

int main() { return 0; }

