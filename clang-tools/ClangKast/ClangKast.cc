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

// *** Global variables ***

KastNodes kast;

// *** KastNodes::Node ***

void KastNodes::Node::printKLabel(const string & label) {
  if (Kore) {
    cout << "Lbl" << escapeKLabel(label) << "{}";
  } else {
    cout << "`" << label << "`";
  }
}

string KastNodes::Node::escapeKLabel(const string & label) {
  string res;
  for (auto i = label.cbegin(); i != label.cend(); i++) {
    const char * subst = NULL;
    switch (*i) {
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
      res.push_back(*i);
    }

  }
  return res;
}

// *** KastNodes::{KApply,List,KSequence,KToken}Node::print

void KastNodes::KApplyNode::print(function<void (void)> printChild) const {
   printKLabel(label);
   cout << "(";
   if (size == 0) {
     cout << ".KList";
   }
   for (int i = 0; i < size; i++) {
     printChild();
     if (i != size - 1) cout << ",";
   }
   cout << ")";
}

void KastNodes::ListNode::print(function<void (void)> printChild) const {
  cout << "kSeqToList(";
  if (size == 0) {
    printf(".K");
  }
  for (int i = 0; i < size; i++) {
    printChild();
    if (i != size - 1) printf("~>");
  }
  printf(")");
}

void KastNodes::KSequenceNode::print(function<void (void)> printChild) const {
  if (size == 0) {
    printf(".K");
  }
  for (int i = 0; i < size; i++) {
    printChild();
    if (i != size - 1) printf("~>");
  }
}

void KastNodes::KTokenNode::print(function<void (void)>) const {
  if (Kore) {
    cout << "\\dv{" << escape(sort) << "}(" << escape(value) << ")";
  } else {
    cout << "#token(" << escape(value) << "," << escape(sort) << ")";
  }
}

void KastNodes::KApply(const string & label, int size) {
  Nodes.push_back(new KApplyNode(label, size));
}

void KastNodes::List(int size) {
  Nodes.push_back(new ListNode(size));
}

void KastNodes::KSequence(int size) {
  Nodes.push_back(new KSequenceNode(size));
}

void KastNodes::KToken(const string & sort, const string & value) {
  Nodes.push_back(new KTokenNode(sort, value));
}

void KastNodes::KToken(const string & s) {
  KToken("String", escape(s));
}

void KastNodes::KToken(llvm::APInt i) {
  string *name = new string(i.toString(10, false));
  KToken("Int", name->c_str());
}

void KastNodes::KToken(unsigned i) {
  char *buf = new char[11];
  sprintf(buf, "%d", i);
  KToken("Int", buf);
}

void KastNodes::KToken(unsigned long long s) {
  char *name = new char[21];
  sprintf(name, "%llu", s);
  KToken("Int", name);
}

void KastNodes::KToken(llvm::APFloat f) {
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
  KToken("Float", result);
}

void KastNodes::KToken(bool b) {
  KToken("Bool", b ? "true" : "false");
}

void KastNodes::print() const { print(0); }

int KastNodes::print(int idx) const {
  Node *current = Nodes[idx++];

  if (!current) throw logic_error("parse error");

  current->print([&]() { idx = print(idx); });

  return idx;
}

string KastNodes::escape(const string & str) {
  string res("\"");
  for(auto ptr = str.cbegin(); ptr != str.cend(); ptr++) {
    switch (*ptr) {
      case '"':  res += "\\\""; break;
      case '\\': res += "\\\\"; break;
      case '\n': res += "\\n";  break;
      case '\t': res += "\\t";  break;
      case '\r': res += "\\r";  break;
      default:
        if (*ptr >= 32 && *ptr < 127) {
          res.push_back(*ptr);
        } else {
          char buf[5];
          sprintf(buf, "\\x%02hhx", (unsigned char)*ptr);
          res += buf;
        }
    }
  }
  res.push_back('\"');
  return res;
}

// *** GetKastConsumer ***

class GetKastConsumer : public clang::ASTConsumer {
public:
  explicit GetKastConsumer(ASTContext *Context, llvm::StringRef InFile)
    : Visitor(kast, Context, InFile) { }
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

  kast.print();
  printf("\n");
}