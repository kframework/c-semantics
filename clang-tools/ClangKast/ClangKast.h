#ifndef CLANGKAST_H_
#define CLANGKAST_H_

class KastNodes {
public:
  void KApply(const char *label, int size);

  void List(int size);

  void KSequence(int size);

  void KToken(const char *s, int len);

  void KToken(const char *);

  void KToken(bool);

  void KToken(llvm::APInt);

  void KToken(unsigned);

  void KToken(unsigned long long);

  void KToken(llvm::APFloat);

  void print() const;

private:
  class Node;
  class KApplyNode;
  class ListNode;
  class KSequenceNode;
  class KTokenNode;

  std::vector<Node *> Nodes;

  static const char * escape(const char *str, unsigned len);
  static const char * escapeKLabel(const char *str, unsigned len);

  void KToken(const char *sort, const char *value);

  int print(int idx) const;

};

#endif
