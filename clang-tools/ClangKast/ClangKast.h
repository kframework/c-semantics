#ifndef CLANGKAST_H_
#define CLANGKAST_H_

enum class Sort { K, KITEM };

class Kast {
public:

  // Add a Kast::Node to the KAST. The next nodes added should be the children (bredth-first).
  template <class T>
  static void add(const T & node);

  // Print the KAST.
  static void print();

  class Node {
  public:
    virtual void print(std::function<void (void)> printChild) const = 0;
    static std::string makeKLabel(const std::string & label);
    static std::string makeKSort(const std::string & label);
  private:
    static std::string escapeKLabel(const std::string & label);
  };

  template <size_t N>
  class KApply : public Node {
  public:
    explicit KApply(const std::string & label, const Sort (&sig)[N])
      : label(label), sig(sig) { }

    void print(std::function<void (void)> printChild) const;
  private:
    const std::string label;
    const Sort subsort = Sort::KITEM;
    const Sort sort = Sort::KITEM;

    const Sort (&sig)[N];
  };

  class KToken : public Node {
  public:
    explicit KToken(const std::string & str)
      : sort("String"), value(toKString(str)) { }
    explicit KToken(bool b)
      : sort("Bool"), value(toKString(b)) { }
    explicit KToken(llvm::APInt i)
      : sort("Int"), value(toKString(i)) { }
    explicit KToken(unsigned i)
      : sort("Int"), value(toKString(i)) { }
    explicit KToken(unsigned long long i)
      : sort("Int"), value(toKString(i)) { }
    explicit KToken(llvm::APFloat f)
      : sort("Float"), value(toKString(f)) { }
    void print(std::function<void (void)> printChild) const;
  private:
    static std::string toKString(const std::string & str);
    static std::string toKString(bool);
    static std::string toKString(llvm::APInt);
    static std::string toKString(unsigned);
    static std::string toKString(unsigned long long);
    static std::string toKString(llvm::APFloat);
    static std::string escape(const std::string & str);
    const std::string sort;
    const std::string value;
  };

  class KSequence : public Node {
  public:
    explicit KSequence(int size) : size(size) { }
    virtual void print(std::function<void (void)> printChild) const;
  private:
    const int size;
  };

  class List : public KSequence {
  public:
    explicit List(int size) : KSequence(size) { }
    void print(std::function<void (void)> printChild) const;
  };

private:
  static std::vector<std::unique_ptr<const Node>> Nodes;
  static int print(int idx);

};

#endif
