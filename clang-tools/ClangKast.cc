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
#include "globs.h"

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
static cl::OptionCategory MyToolCategory("K++ parser options");

// CommonOptionsParser declares HelpMessage with a description of the common
// command-line options related to the compilation database and input files.
// It's nice to have this help message in all tools.
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);

// A help message for this specific tool can be added afterwards.
static cl::extrahelp MoreHelp("");

const char *escape(const char *str, unsigned len) {
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

class GetKASTConsumer : public clang::ASTConsumer {
public:
  explicit GetKASTConsumer(ASTContext *Context, llvm::StringRef InFile)
    : Visitor(Context, InFile) {}

  virtual void HandleTranslationUnit(clang::ASTContext &Context) {
    Visitor.TraverseDecl(Context.getTranslationUnitDecl());
  }
private:
  GetKASTVisitor Visitor;
};

class GetKASTAction : public clang::ASTFrontendAction {
public:
  virtual std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(
    clang::CompilerInstance &Compiler, llvm::StringRef InFile) {
    return std::unique_ptr<clang::ASTConsumer>(
      new GetKASTConsumer(&Compiler.getASTContext(), InFile));
  }
};

void makeKast(int& idx) {
  Node *current = nodes[idx];
  if (!current) {
    throw std::logic_error("parse error");
  }
  switch(current->kind) {
    case KAPPLY:
      printf("`%s`(", current->_1);
      if (current->size == 0) {
        printf(".KList");
      }
      idx++;
      for (int i = 0; i < current->size; i++) {
        makeKast(idx);
        if (i != current->size - 1) printf(",");
      }
      printf(")");
      break;
    case KSEQUENCE:
      if (current->size == 0) {
        printf(".K");
      }
      idx++;
      for (int i = 0; i < current->size; i++) {
        makeKast(idx);
        if (i != current->size - 1) printf("~>");
      }
      break;
    case LIST:
      printf("kSeqToList(");
      if (current->size == 0) {
        printf(".K");
      }
      idx++;
      for (int i = 0; i < current->size; i++) {
        makeKast(idx);
        if (i != current->size - 1) printf("~>");
      }
      printf(")");
      break;
    case KTOKEN:
      idx++;
      printf("#token(");
      printf("%s", escape(current->_1, strlen(current->_1)));
      printf(",");
      printf("%s", escape(current->_2, strlen(current->_2)));
      printf(")");
      break;
    default:
      throw std::logic_error("unexpected kind");
  }
}

int main(int argc, const char **argv) {
  CommonOptionsParser OptionsParser(argc, argv, MyToolCategory);
  ClangTool Tool(OptionsParser.getCompilations(),
                 OptionsParser.getSourcePathList());

  int ret = Tool.run(newFrontendActionFactory<GetKASTAction>().get());
  if (ret) {
    return ret;
  }

  int idx = 0;
  makeKast(idx);
  printf("\n");
}

