#include <stdio.h>
#include <string.h>

struct node {
      int x;
      char buf[12];
      struct node* next;
};

void init_node(struct node* n) {
      n->x = 0;
      n->next = NULL;
      memset(n->buf, 0x6A, sizeof(n->buf));
      char* bytes = (char*)(struct node*)&n->x;
      printf("%p\n", (void*)n->next);
      printf("%u\n", (unsigned int)(((char*)n)[8]));
      printf("%u\n", (unsigned int)bytes[8]);
}

struct node2 {
  char buf[20];
  struct node2* next;
};

void init_node2(struct node2* n) {
  n->next = NULL;
  char* base = n->buf;
  struct node2* parent = (struct node2*)base;
  memset(parent, 0x6A, sizeof(struct node2));

  char* parent2 = (char*)n;
  memset(parent2, 0x6A, sizeof(struct node2));
}

int main(void) {
      struct node n;
      init_node(&n);

      struct node2 n2;
      init_node2(&n2);
}

