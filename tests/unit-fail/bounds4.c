#include <string.h>
#include <stdio.h>

struct node {
  char buf[20];
  struct node* next;
};

void init_node(struct node* n) {
  n->next = NULL;
  memset(&n->buf, 0x6A, sizeof(struct node));
}

int main(void) {
  struct node n;
  init_node(&n);
  if (n.next == NULL) {
    return 0;
  } else {
    printf("Pointer not initialized to NULL\n");
    return 1;
  }
}
