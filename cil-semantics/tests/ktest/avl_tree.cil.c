/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

//#line 212 "/usr/lib/gcc/x86_64-linux-gnu/4.6/include/stddef.h"
typedef unsigned long size_t;

struct node {
   int value ;
   int height ;
   struct node *left ;
   struct node *right ;
};

//#line 471 "/usr/include/stdlib.h"
extern void * malloc(size_t __size);

//#line 488
extern void free(void *__ptr);

int max(int a , int b )
{ int tmp ;

  {
  if (a > b) {
    tmp = a;
  } else {
    tmp = b;
  }
  return (tmp);
}
}

int height(struct node *t )
{ int tmp ;

  {
  if (t) {
    tmp = t->height;
  } else {
    tmp = 0;
  }
  return (tmp);
}
}

void update_height(struct node *t )
{ int tmp ;
  int tmp___0 ;
  int tmp___1 ;

  {
  tmp = height(t->right);
  tmp___0 = height(t->left);
  tmp___1 = max(tmp___0, tmp);
  t->height = tmp___1 + 1;
  return;
}
}

struct node *left_rotate(struct node *x )
{ struct node *y ;

  {
  y = x->right;
  x->right = y->left;
  y->left = x;
  update_height(x);
  update_height(y);
  return (y);
}
}

struct node *right_rotate(struct node *x )
{ struct node *y ;

  {
  y = x->left;
  x->left = y->right;
  y->right = x;
  update_height(x);
  update_height(y);
  return (y);
}
}

struct node *balance(struct node *t )
{ int tmp ;
  int tmp___0 ;
  int tmp___1 ;
  int tmp___2 ;
  int tmp___3 ;
  int tmp___4 ;
  int tmp___5 ;
  int tmp___6 ;

  {
  tmp___5 = height(t->left);
  tmp___6 = height(t->right);
  if (tmp___5 - tmp___6 > 1) {
    tmp = height((t->left)->left);
    tmp___0 = height((t->left)->right);
    if (tmp < tmp___0) {
      t->left = left_rotate(t->left);
    }
    t = right_rotate(t);
  } else {
    tmp___3 = height(t->left);
    tmp___4 = height(t->right);
    if (tmp___3 - tmp___4 < -1) {
      tmp___1 = height((t->right)->left);
      tmp___2 = height((t->right)->right);
      if (tmp___1 > tmp___2) {
        t->right = right_rotate(t->right);
      }
      t = left_rotate(t);
    }
  }
  return (t);
}
}

int find_min(struct node *t )
{ int tmp ;

  {
  if (t->left == (void *) 0) {
    return (t->value);
  } else {
    tmp = find_min(t->left);
    return (tmp);
  }
}
}

struct node *delete(int v , struct node *t )
{ int min ;
  struct node *temp ;
  struct node *temp___0 ;

  {
  if (t == (void *) 0) {
    return ((struct node *)((void *)0));
  }
  if (v == t->value) {
    if (t->left == (void *) 0) {
      temp = t->right;
      free((void *)t);
      return (temp);
    } else {
      if (t->right == (void *) 0) {
        temp___0 = t->left;
        free((void *)t);
        return (temp___0);
      } else {
        min = find_min(t->right);
        t->right = delete(min, t->right);
        t->value = min;
      }
    }
  } else {
    if (v < t->value) {
      t->left = delete(v, t->left);
    } else {
      t->right = delete(v, t->right);
    }
  }
  update_height(t);
  t = balance(t);
  return (t);
}
}

struct node *new_node(int v )
{ struct node *node ;
  void *tmp ;

  {
  tmp = malloc(sizeof(struct node ));
  node = (struct node *)tmp;
  node->value = v;
  node->height = 1;
  node->left = (struct node *)((void *)0);
  node->right = (struct node *)((void *)0);
  return (node);
}
}

struct node *insert(int v , struct node *t )
{ struct node *tmp ;

  {
  if (t == (void *) 0) {
    tmp = new_node(v);
    return (tmp);
  }
  if (v < t->value) {
    t->left = insert(v, t->left);
  } else {
    if (v > t->value) {
      t->right = insert(v, t->right);
    } else {
      return (t);
    }
  }
  update_height(t);
  t = balance(t);
  return (t);
}
}

int find(int v , struct node *t )
{ int tmp ;
  int tmp___0 ;

  {
  if (t == (void *) 0) {
    return (0);
  } else {
    if (v == t->value) {
      return (1);
    } else {
      if (v < t->value) {
        tmp = find(v, t->left);
        return (tmp);
      } else {
        tmp___0 = find(v, t->right);
        return (tmp___0);
      }
    }
  }
}
}

int main(void)
{ struct node *t ;
  int v ;
  struct node *tmp ;
  int v___0 ;
  struct node *tmp___0 ;

  {
  t = (struct node *)((void *)0);
  v = 0;
  while (v < 5) {
    tmp = insert(v, (struct node *)t);
    t = (struct node *)tmp;
    v ++;
  }
  v___0 = 0;
  while (v___0 < 5) {
    tmp___0 = delete(v___0, (struct node *)t);
    t = (struct node *)tmp___0;
    v___0 ++;
  }
  return (t == (void *) 0);
}
}
