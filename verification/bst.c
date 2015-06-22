// Copyright (c) 2014 K Team. All Rights Reserved.
/*
 * Binary search tree with find, insert and delete functions.
 */

#include <stdlib.h>

struct treeNode {
  int value;
  struct treeNode *left;
  struct treeNode *right;
};


struct treeNode* new_node(int v)
{
  struct treeNode *node;
  node = (struct treeNode *) malloc(sizeof(struct treeNode));
  node->value = v;
  node->left = NULL;
  node->right = NULL;
  return node;
}


int find(int v, struct treeNode *t)
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

struct treeNode* insert(int v, struct treeNode *t)
{
  if (t == NULL)
    return new_node(v);

  if (v < t->value)
    t->left = insert(v, t->left);
  else if (v > t->value) 
    t->right = insert(v, t->right);

  return t;
}


int find_min(struct treeNode *t)
{
  if (t->left == NULL)
    return t->value;
  else
    return find_min(t->left);
}

struct treeNode* delete(int v, struct treeNode *t)
{
  int min;

  if (t == NULL)
    return NULL;

  if (v == t->value) {
    if (t->left == NULL) {
      struct treeNode *temp;

      temp = t->right;
      free(t);

      return temp;
    }
    else if (t->right == NULL) {
      struct treeNode *temp;

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

  return t;
}


int main() {
  return 0;
}

