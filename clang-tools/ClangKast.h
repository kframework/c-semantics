#ifndef CLANGKAST_H_
#define CLANGKAST_H_

struct Node;

class Kast {
public:
  void AddKApplyNode(const char *label, int size);

  void AddListNode(int size);

  void AddKSequenceNode(int size);

  void AddKTokenNode(const char *s, int len);

  void AddKTokenNode(const char *);

  void AddKTokenNode(bool);

  void AddKTokenNode(llvm::APInt);

  void AddKTokenNode(unsigned);

  void AddKTokenNode(unsigned long long);

  void AddKTokenNode(llvm::APFloat);

  void AddSpecifier(const char *str);

  void AddSpecifier(const char *str, unsigned long long n);

  void print() const;

private:
  std::vector<Node *> nodes_;

  static const char * escape(const char *str, unsigned len);

  void AddKTokenNode(const char *s, const char *sort);

  int print(int idx) const;

};

#endif
