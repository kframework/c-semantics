#include <stdlib.h>

struct node {
  unsigned value;
  unsigned height;
  struct node *left;
  struct node *right;
};

unsigned max(unsigned a, unsigned b)
{
  return a > b ? a : b;
}

unsigned height(struct node *t)
{
  return t ? t->height : 0;
}

void update_height(struct node *t)
{
  t->height = max(height(t->left), height(t->right)) + 1;
}

struct node* left_rotate(struct node *x)
{
  struct node *y;

  y = x->right;
  x->right = y->left;
  y->left = x;

  update_height(x);
  update_height(y);

  return y;
}

struct node* right_rotate(struct node *x)
{
  struct node *y;

  y = x->left;
  x->left = y->right;
  y->right = x;

  update_height(x);
  update_height(y);

  return y;
}

struct node* balance(struct node *t)
{
  if (height(t->left) > 1 + height(t->right)) {
    if (height(t->left->left) < height(t->left->right))
      t->left = left_rotate(t->left);
    t = right_rotate(t);
  }
  else if (height(t->left) + 1 < height(t->right)) {
    if (height(t->right->left) > height(t->right->right))
      t->right = right_rotate(t->right);
    t = left_rotate(t);
  }

  return t;
}

unsigned find_min(struct node *t)
{
  if (t->left == NULL)
    return t->value;
  else
    return find_min(t->left);
}

struct node* delete(unsigned v, struct node *t)
{
  unsigned min;

  if (t == NULL)
    return NULL;

  if (v == t->value) {
    if (t->left == NULL) {
      struct node *temp;

      temp = t->right;
      free(t);

      return temp;
    }
    else if (t->right == NULL) {
      struct node *temp;

      temp = t->left;
      free(t);

      return temp;
    }
    else {
      min = find_min(t->right);
      t->right = delete(min, t->right);
      t->value = min;
    }
  }
  else if (v < t->value)
    t->left = delete(v, t->left);
  else
    t->right = delete(v, t->right);

  update_height(t);
  t = balance(t);

  return t;
}

struct node* new_node(unsigned v)
{
  struct node *node;
  node = (struct node *) malloc(sizeof(struct node));

  node->value = v;
  node->height = 1;
  node->left = NULL;
  node->right = NULL;

  return node;
}

struct node* insert(unsigned v, struct node *t)
{
  if (t == NULL)
    return new_node(v);

  if (v < t->value)
    t->left = insert(v, t->left);
  else if (v > t->value)
    t->right = insert(v, t->right);
  else
    return t;

  update_height(t);
  t = balance(t);

  return t;
}

unsigned find(unsigned v, struct node *t)
{
  if (t == NULL)
    return 0;
  else if (v == t->value)
    return 1;
  else if (v < t->value)
    return find(v, t->left);
  else
    return find(v, t->right);
}

int main()
{
  struct node *t = NULL;
  unsigned v;
  for (v = 0; v < 5; v++) {
    t = insert(v, t);
  }
  for (v = 0; v < 5; v++) {
    t = delete(v, t);
  }

  return t == NULL;
}
