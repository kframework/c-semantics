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

using namespace clang;
using namespace clang::tooling;
namespace cl = llvm::cl;

// Apply a custom category to all command-line options so that they are the
// only ones displayed.
static cl::OptionCategory KastOptionCategory("K++ parser options");

// CommonOptionsParser declares HelpMessage with a description of the common
// command-line options related to the compilation database and input files.
// It's nice to have this help message in all tools.
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);

static cl::opt<bool> Kore("kore", cl::desc("Output kore instead of kast."), cl::cat(KastOptionCategory));

KastNodes kast;

enum KKind {
  KAPPLY, KSEQUENCE, LIST, KTOKEN
};

struct KastNodes::Node {
  const char *_1;
  const char *_2;
  int size;
  KKind kind;
};

void KastNodes::KApply(const char *label, int size) {
  Node *node = new Node();
  node->_1 = label;
  node->size = size;
  node->kind = KAPPLY;
  Nodes.push_back(node);
}

void KastNodes::List(int size) {
  Node *list = new Node();
  list->size = size;
  list->kind = LIST;
  Nodes.push_back(list);
}

void KastNodes::KSequence(int size) {
  Node *list = new Node();
  list->size = size;
  list->kind = KSEQUENCE;
  Nodes.push_back(list);
}

void KastNodes::KToken(const char *s, const char *sort) {
  Node *node = new Node();
  node->_1 = s;
  node->_2 = sort;
  node->kind = KTOKEN;
  Nodes.push_back(node);
}

void KastNodes::KToken(const char *s, int len) {
  KToken(escape(s, len), "String");
}

void KastNodes::KToken(const char *s) {
  KToken(escape(s, strlen(s)), "String");
}

void KastNodes::KToken(llvm::APInt i) {
  std::string *name = new std::string(i.toString(10, false));
  KToken(name->c_str(), "Int");
}

void KastNodes::KToken(unsigned i) {
  char *buf = new char[11];
  sprintf(buf, "%d", i);
  KToken(buf, "Int");
}

void KastNodes::KToken(unsigned long long s) {
  char *name = new char[21];
  sprintf(name, "%llu", s);
  KToken(name, "Int");
}

void KastNodes::KToken(llvm::APFloat f) {
  unsigned precision = f.semanticsPrecision(f.getSemantics());
  unsigned numBytes = 6 // max length of signed short
                    + 4 //-1.E
                    + 3 + 11 //p4294967295x16
                    + 1 // null byte
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
  KToken(result, "Float");
}

void KastNodes::KToken(bool b) {
  KToken(b ? "true" : "false", "Bool");
}

void KastNodes::print() const { print(0); }

int KastNodes::print(int idx) const {
  Node *current = Nodes[idx++];

  if (!current) {
    throw std::logic_error("parse error");
  }

  switch (current->kind) {

    case KAPPLY:
      printf("`%s`(", current->_1);
      if (current->size == 0) {
        printf(".KList");
      }
      for (int i = 0; i < current->size; i++) {
        idx = print(idx);
        if (i != current->size - 1) printf(",");
      }
      printf(")");
      break;

    case KSEQUENCE:
      if (current->size == 0) {
        printf(".K");
      }
      for (int i = 0; i < current->size; i++) {
        idx = print(idx);
        if (i != current->size - 1) printf("~>");
      }
      break;

    case LIST:
      printf("kSeqToList(");
      if (current->size == 0) {
        printf(".K");
      }
      for (int i = 0; i < current->size; i++) {
        idx = print(idx);
        if (i != current->size - 1) printf("~>");
      }
      printf(")");
      break;

    case KTOKEN:
      printf("#token(");
      printf("%s", escape(current->_1, strlen(current->_1)));
      printf(",");
      printf("%s", escape(current->_2, strlen(current->_2)));
      printf(")");
      break;

    default:
      throw std::logic_error("unexpected kind");
  }

  return idx;
}

const char * KastNodes::escape(const char *str, unsigned len) {
  std::string *res = new std::string("\"");
  unsigned i = 0;
  for(const char *ptr=str; i < len; ptr++, i++) {
    const char c = *ptr;
    switch(c) {
      case '"':
        *res += "\\\"";
        break;
      case '\\':
        *res += "\\\\";
        break;
      case '\n':
        *res += "\\n";
        break;
      case '\t':
        *res += "\\t";
        break;
      case '\r':
        *res += "\\r";
        break;
      default:
        if (c >= 32 && c < 127) {
          res->push_back(c);
        } else {
          char buf[5];
          sprintf(buf, "\\x%02hhx", (unsigned char)c);
          *res += buf;
        }
    }
  }
  res->push_back('\"');
  return res->c_str();
}

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

class GetKastAction : public clang::ASTFrontendAction {

public:

  virtual std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(
    clang::CompilerInstance &Compiler, llvm::StringRef InFile) {
    return std::unique_ptr<clang::ASTConsumer>(
      new GetKastConsumer(&Compiler.getASTContext(), InFile));
  }

};

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
