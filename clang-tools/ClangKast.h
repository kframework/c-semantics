#ifndef CLANGKAST_H_
#define CLANGKAST_H_

struct Node;

class Kast {
public:
  void AddKApplyNode(const char *label, int size);

  void AddListNode(int size);

  void AddKSequenceNode(int size);

  void AddKTokenNode(const char *s, const char *sort);

  int makeKast(int idx);

  static const char * escape(const char *str, unsigned len);

private:
  std::vector<Node *> nodes;
};

#endif
