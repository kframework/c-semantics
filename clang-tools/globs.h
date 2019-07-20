#ifndef GLOBS_H_
#define GLOBS_H_

enum KKind {
  KAPPLY, KSEQUENCE, LIST, KTOKEN
};

struct Node {
  const char *_1;
  const char *_2;
  int size;
  KKind kind;
};

std::vector<Node *> nodes;

const char *escape(const char *str, unsigned len);

#endif
