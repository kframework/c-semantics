#ifndef CLANGKAST_H_
#define CLANGKAST_H_

class KastNodes {
public:
  void KApply(const std::string & label, int size);

  void List(int size);

  void KSequence(int size);

  void KToken(const std::string & str);

  void KToken(bool);

  void KToken(llvm::APInt);

  void KToken(unsigned);

  void KToken(unsigned long long);

  void KToken(llvm::APFloat);

  void print() const;

private:
  class Node {
  public:
    virtual void print(std::function<void (void)> printChild) const = 0;
    static void printKLabel(const std::string & label);
  private:
    static std::string escapeKLabel(const std::string & label);
  };

  class KApplyNode : public Node {
  public:
    explicit KApplyNode(const std::string & label, int size)
      : label(label), size(size) { }
    void print(std::function<void (void)> printChild) const;
  private:
    const std::string label;
    const int size;
  };

  class ListNode : public Node {
  public:
    explicit ListNode(int size) : size(size) { }
    void print(std::function<void (void)> printChild) const;
  private:
    const int size;
  };

  class KSequenceNode : public Node {
  public:
    explicit KSequenceNode(int size) : size(size) { }
    void print(std::function<void (void)> printChild) const;
  private:
    const int size;
  };

  class KTokenNode : public Node {
  public:
    explicit KTokenNode(const std::string & sort, const std::string & value)
      : sort(sort), value(value) { }
    void print(std::function<void (void)> printChild) const;
  private:
    const std::string sort;
    const std::string value;
  };

  std::vector<Node *> Nodes;

  static std::string escape(const std::string & str);

  void KToken(const std::string & sort, const std::string & value);

  int print(int idx) const;

};

#endif
