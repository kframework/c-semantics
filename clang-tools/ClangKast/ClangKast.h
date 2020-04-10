#ifndef CLANGKAST_H_
#define CLANGKAST_H_

enum class Sort {
  ACCESSSPECIFIER,
  AEXPR,
  ASTMT,
  ATYPE,
  ATYPERESULT,
  AUTOSPECIFIER,
  BASESPECIFIER,
  BOOL,
  BRACEINIT,
  CABSLOC,
  CAPTURE,
  CAPTUREDEFAULT,
  CAPTUREKIND,
  CATCHDECL,
  CHARKIND,
  CID,
  CLASSKEY,
  CTORINIT,
  DECL,
  DECLARATOR,
  DESTRUCTORID,
  ENUMERATOR,
  EXCEPTIONSPEC,
  EXPR,
  EXPRESSIONLIST,
  EXPRLOC,
  FLOAT,
  FUNCTIONSPECIFIER,
  INIT,
  INT,
  K,
  KITEM,
  LIST,
  NAME,
  NAMESPACE,
  NNS,
  NNSSPECIFIER,
  NOINIT,
  NONAME,
  OPID,
  QUALIFIER,
  REFQUALIFIER,
  RESOLVEDEXPR,
  SPECIFIER,
  STMT,
  STORAGECLASSSPECIFIER,
  STRICTLIST,
  STRICTLISTRESULT,
  STRING,
  TAG,
  TEMPLATEARGUMENT,
  TEMPLATEPARAMETER,
  THIS,
  TYPEID,
  TYPESPECIFIER,
  UNNAMEDCID,
};

std::ostream& operator<<(std::ostream & os, const Sort & sort);

class Kast {
public:

  // Add a Kast::Node to the KAST. The next nodes added should be the children (breadth-first).
  template <class T>
  static void add(const T & node);

  // Print the KAST.
  static void print();

  class Node {
  public:
    explicit Node(Sort sort) : sort(sort) { }
    virtual ~Node() { }
    virtual void print(Sort parentSort, std::function<void (Sort)> printChild) const = 0;
    static std::string makeKLabel(const std::string & label);
  protected:
    const Sort sort;
  private:
    static std::string escapeKLabel(const std::string & label);
  };

  class KApply : public Node {
  public:
    explicit KApply(const std::string & label, Sort sort)
      : Node(sort), label(label) { }
    explicit KApply(const std::string & label, Sort sort, std::initializer_list<Sort> sig)
      : Node(sort), label(label), sig(sig) { }

    void print(Sort parentSort, std::function<void (Sort)> printChild) const;
  private:
    const std::string label;

    const std::vector<Sort> sig;
  };

  class KToken : public Node {
  public:
    explicit KToken(const std::string & str)
      : Node(Sort::STRING), value(toKString(str)) { }
    explicit KToken(bool b)
      : Node(Sort::BOOL), value(toKString(b)) { }
    explicit KToken(llvm::APInt i)
      : Node(Sort::INT), value(toKString(i)) { }
    explicit KToken(unsigned i)
      : Node(Sort::INT), value(toKString(i)) { }
    explicit KToken(unsigned long long i)
      : Node(Sort::INT), value(toKString(i)) { }
    explicit KToken(llvm::APFloat f)
      : Node(Sort::FLOAT), value(toKString(f)) { }
    void print(Sort parentSort, std::function<void (Sort)> printChild) const;
  private:
    static std::string toKString(const std::string & str);
    static std::string toKString(bool);
    static std::string toKString(llvm::APInt);
    static std::string toKString(unsigned);
    static std::string toKString(unsigned long long);
    static std::string toKString(llvm::APFloat);
    static std::string escape(const std::string & str);
    const std::string value;
  };

  class KSequence : public Node {
  public:
    explicit KSequence(int size) : Node(Sort::K), size(size) { }
    virtual void print(Sort parentSort, std::function<void (Sort)> printChild) const;
  private:
    const int size;
  };

private:
  static std::vector<std::unique_ptr<const Node>> Nodes;
  static int print(Sort sort, int idx);

};

#endif
