#define _XOPEN_SOURCE 700

#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcomment"
#elif defined __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomment"
#endif

#include "clang/AST/ASTConsumer.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"

#include "GetKastVisitor.h"
#include "ClangKast.h"

#ifdef __GNUC__
#pragma GCC diagnostic pop
#elif defined __clang__
#pragma clang diagnostic pop
#endif

#include <cstdio>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

#include <iostream>

using namespace std;
using namespace clang;
using namespace clang::tooling;
namespace cl = llvm::cl;

// *** Command line setup ***

// Apply a custom category to all command-line options so that they are the
// only ones displayed.
static cl::OptionCategory KastOptionCategory("K++ parser options");

// CommonOptionsParser declares HelpMessage with a description of the common
// command-line options related to the compilation database and input files.
// It's nice to have this help message in all tools.
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);

static cl::opt<bool> Kore("kore", cl::desc("Output kore instead of kast."), cl::cat(KastOptionCategory));

// *** Kast::Nodes ***

vector<unique_ptr<const Kast::Node>> Kast::Nodes;

// *** Kast::Node ***

string Kast::Node::makeKLabel(const string & label) {
  if (Kore) {
    return "Lbl" + escapeKLabel(label) + "{}";
  } else {
    return "`" + label + "`";
  }
}

string Kast::Node::makeKSort(const string & sort) {
  if (Kore) {
    return "Sort" + sort + "{}";
  } else {
    return sort;
  }
}

string Kast::Node::escapeKLabel(const string & label) {
  string res;
  for (char c : label) {
    const char * subst = NULL;
    switch (c) {
      case ' ':  subst = "Spce'"; break;
      case '!':  subst = "Bang'"; break;
      case '"':  subst = "Quot'"; break;
      case '#':  subst = "Hash'"; break;
      case '$':  subst = "Dolr'"; break;
      case '%':  subst = "Perc'"; break;
      case '&':  subst = "And'" ; break;
      case '\'': subst = "Apos'"; break;
      case '(':  subst = "LPar'"; break;
      case ')':  subst = "RPar'"; break;
      case '*':  subst = "Star'"; break;
      case '+':  subst = "Plus'"; break;
      case ',':  subst = "Comm'"; break;
      case '.':  subst = "Stop'"; break;
      case '/':  subst = "Slsh'"; break;
      case ':':  subst = "Coln'"; break;
      case ';':  subst = "SCln'"; break;
      case '<':  subst = "-LT-'"; break;
      case '=':  subst = "Eqls'"; break;
      case '>':  subst = "-GT-'"; break;
      case '?':  subst = "Ques'"; break;
      case '@':  subst = "-AT-'"; break;
      case '[':  subst = "LSqB'"; break;
      case '\\': subst = "Bash'"; break;
      case ']':  subst = "RSqB'"; break;
      case '^':  subst = "Xor-'"; break;
      case '_':  subst = "Unds'"; break;
      case '`':  subst = "BQuo'"; break;
      case '{':  subst = "LBra'"; break;
      case '|':  subst = "Pipe'"; break;
      case '}':  subst = "RBra'"; break;
      case '~':  subst = "Tild'"; break;
    }

    if (subst) {
      if (res.length() > 0 && res.back() == '\'')
        res.pop_back();
      else res.push_back('\'');
      res += subst;
    } else {
      res.push_back(c);
    }

  }
  return res;
}

// *** Kast::KApply ***

template <size_t N>
void Kast::KApply<N>::print(function<void (void)> printChild) const {
  if (Kore && subsort != sort) {
      if (sort == Sort::K) {
        cout << "kseq{}(";
        if (subsort != Sort::KITEM) {
          // kseq [inj subsort KItem contents]
          cout << "inj{" << makeKSort("subsort") << ", " << makeKSort("sort") << "}(";
        }
      } else {
        // inj subsort sort contents
        cout << "inj{" << makeKSort("subsort") << ", " << makeKSort("sort") << "}(";
      }
  }

  size_t nchildren = N - 1;

  cout << makeKLabel(label) << "(";
  if (!Kore && nchildren == 0) {
    cout << ".KList";
  }
  for (size_t i = 0; i != nchildren; i++) {
    printChild();
    if (i != nchildren - 1) cout << ",";
  }
  cout << ")";

  if (Kore && subsort != sort) {
    if (sort == Sort::K) {
      if (subsort != Sort::KITEM) {
        cout << ")";
      }
      cout << ", dotk{}())";
    } else {
      cout << ")";
    }
  }
}

// *** Kast::KToken ***

string Kast::KToken::toKString(const string & s) {
  return string(Kore ? escape(s) : "\"" + escape(s) + "\"");
}

string Kast::KToken::toKString(bool b) {
  return string(b ? "true" : "false");
}

string Kast::KToken::toKString(llvm::APInt i) {
  return string(i.toString(10, false));
}

string Kast::KToken::toKString(unsigned i) {
  char *buf = new char[11];
  sprintf(buf, "%d", i);
  return string(buf);
}

string Kast::KToken::toKString(unsigned long long s) {
  char *name = new char[21];
  sprintf(name, "%llu", s);
  return string(name);
}

string Kast::KToken::toKString(llvm::APFloat f) {
  unsigned precision = f.semanticsPrecision(f.getSemantics());
  unsigned numBytes = 6      // max length of signed short
                    + 4      // -1.E
                    + 3 + 11 // p4294967295x16
                    + 1      // null byte
                    + precision;
  SmallVector<char, 80> buf;
  f.toString(buf, 0, 0);
  char *data = buf.data();
  data[buf.size()] = 0;
  char suffix[14];
  sprintf(suffix, "p%ux16", precision);
  char *result = new char[numBytes];
  strcpy(result, data);
  strcat(result, suffix);
  return string(result);
}

void Kast::KToken::print(function<void (void)>) const {
  if (Kore) {
    cout << "\\dv{" << makeKSort(sort) << "}(\"" << escape(value) << "\")";
  } else {
    cout << "#token(\"" << escape(value) << "\", \"" << makeKSort(sort) << "\")";
  }
}

string Kast::KToken::escape(const string & str) {
  string res;
  for(char c : str) {
    switch (c) {
      case '"':  res += "\\\""; break;
      case '\\': res += "\\\\"; break;
      case '\n': res += "\\n";  break;
      case '\t': res += "\\t";  break;
      case '\r': res += "\\r";  break;
      default:
        if (c >= 32 && c < 127) {
          res.push_back(c);
        } else {
          char buf[5];
          sprintf(buf, "\\x%02hhx", (unsigned char)c);
          res += buf;
        }
    }
  }
  return res;
}

// *** Kast::KSequence

void Kast::KSequence::print(function<void (void)> printChild) const {
  if (size == 0) {
    cout << (Kore ? "dotk{}()" : ".K");
  }
  for (int i = 0; i < size; i++) {
    printChild();
    if (i != size - 1) {
      cout << (Kore ? ", " : "~>");
    }
  }
}

// *** Kast::List ***

void Kast::List::print(function<void (void)> printChild) const {
  cout << makeKLabel("kSeqToList") << "(";
  KSequence::print(printChild);
  cout << ")";
}

// *** Kast:: ***

template <class T>
void Kast::add(const T & node) {
  static_assert(std::is_base_of<Kast::Node, T>::value, "type parameter must derive from Kast::Node");
  Kast::Nodes.push_back(make_unique<T>(node));
}

void Kast::print() { print(0); }

int Kast::print(int idx) {
  if (!Nodes[idx]) throw logic_error("parse error");

  Nodes[idx]->print([&]() { idx = print(idx + 1); });

  return idx;
}

// *** GetKastConsumer ***

class GetKastConsumer : public clang::ASTConsumer {
public:
  explicit GetKastConsumer(ASTContext *Context, llvm::StringRef InFile)
    : Visitor(Context, InFile) { }
  virtual void HandleTranslationUnit(clang::ASTContext &Context) {
    Visitor.TraverseDecl(Context.getTranslationUnitDecl());
  }

private:
  GetKastVisitor Visitor;
};

// *** GetKastAction ***

class GetKastAction : public clang::ASTFrontendAction {
public:
  virtual unique_ptr<clang::ASTConsumer> CreateASTConsumer(
    clang::CompilerInstance &Compiler, llvm::StringRef InFile) {
    return unique_ptr<clang::ASTConsumer>(
      new GetKastConsumer(&Compiler.getASTContext(), InFile));
  }
};

// *** main ***

int main(int argc, const char **argv) {
  CommonOptionsParser OptionsParser(argc, argv, KastOptionCategory);
  ClangTool Tool(OptionsParser.getCompilations(),
                 OptionsParser.getSourcePathList());

  if (int r = Tool.run(newFrontendActionFactory<GetKastAction>().get())) {
    return r;
  }

  Kast::print();
  cout << endl;
}
