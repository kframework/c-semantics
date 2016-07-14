#include "clang/AST/ASTConsumer.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"
#include <cstdio>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

using namespace clang;
using namespace clang::tooling;
using namespace llvm;

// Apply a custom category to all command-line options so that they are the
// only ones displayed.
static cl::OptionCategory MyToolCategory("my-tool options");

// CommonOptionsParser declares HelpMessage with a description of the common
// command-line options related to the compilation database and input files.
// It's nice to have this help message in all tools.
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);

// A help message for this specific tool can be added afterwards.
static cl::extrahelp MoreHelp("\nMore help text...");

enum KKind {
  KAPPLY, KSEQUENCE, KTOKEN
};

struct Node {
  const char *_1;
  const char *_2;
  int size;
  KKind kind;
};

std::vector<Node *> nodes;

int dupedFd;

#define TRY_TO(CALL_EXPR)                                                     \
  do {                                                                        \
    if (!getDerived().CALL_EXPR)                                              \
      return false;                                                           \
    } while (0)

#define WALK_UP_HELPER(CALL_EXPR)                                             \
  do {                                                                        \
    if (!getDerived().CALL_EXPR)                                              \
      return true;                                                            \
    } while (0)

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
        sprintf(buf, "\\x%02x", c);
        *res += buf;
      }
    }
  }
  res->push_back('\"');
  return res->c_str();
}

void doThrow(const char *str) {
  dup2(dupedFd, STDERR_FILENO);
  throw std::logic_error(str);
}

class GetKASTVisitor
  : public RecursiveASTVisitor<GetKASTVisitor> {
public:
  explicit GetKASTVisitor(ASTContext *Context, llvm::StringRef InFile)
    : Context(Context) {
    this->InFile = InFile;
  }

// if we reach all the way to the top of a hierarchy, crash with an error
// because we don't support the node

  bool VisitDecl(Decl *Declaration) {
    dup2(dupedFd, STDERR_FILENO);
    Declaration->dump();
    throw std::logic_error("unimplemented decl");
  }

  bool VisitStmt(Stmt *Statement) {
    dup2(dupedFd, STDERR_FILENO);
    Statement->dump();
    throw std::logic_error("unimplemented stmt");
  }

  bool VisitType(Type *T) {
    dup2(dupedFd, STDERR_FILENO);
    T->dump();
    printf("%s", T->getTypeClassName());
    throw std::logic_error("unimplemented type");
  }

// modify the evaluation strategy so that we walk up from the base to the
// parent, stopping if any of the nodes are successfully visited (but
// continuing to the next node)

#define STMT(CLASS, PARENT)                                                   \
  bool WalkUpFrom##CLASS(CLASS *S) {                                          \
    WALK_UP_HELPER(Visit##CLASS(S));                                                  \
    WALK_UP_HELPER(WalkUpFrom##PARENT(S));                                            \
    return true;                                                              \
  }
#include "clang/AST/StmtNodes.inc"

#define TYPE(CLASS, BASE)                                                     \
  bool WalkUpFrom##CLASS##Type(CLASS##Type *T) {                              \
    WALK_UP_HELPER(Visit##CLASS##Type(T));                                            \
    WALK_UP_HELPER(WalkUpFrom##BASE(T));                                              \
    return true;                                                              \
  }
#include "clang/AST/TypeNodes.def"

#define DECL(CLASS, BASE)                                                     \
  bool WalkUpFrom##CLASS##Decl(CLASS##Decl *D) {                              \
    WALK_UP_HELPER(Visit##CLASS##Decl(D));                                            \
    WALK_UP_HELPER(WalkUpFrom##BASE(D));                                              \
    return true;                                                              \
  }
#include "clang/AST/DeclNodes.inc"

  void AddKApplyNode(const char *label, int size) {
    Node *node = new Node();
    node->_1 = label;
    node->size = size;
    node->kind = KAPPLY;
    nodes.push_back(node);
  }

  void AddKSequenceNode(int size) {
    Node *list = new Node();
    list->size = size;
    list->kind = KSEQUENCE;
    nodes.push_back(list);
  }

  void AddKTokenNode(const char *s, const char *sort) {
    Node *node = new Node();
    node->_1 = s;
    node->_2 = sort;
    node->kind = KTOKEN;
    nodes.push_back(node);
  }

  void AddDeclContextNode(DeclContext *Declaration) {
    int i = 0;
    for (DeclContext::decl_iterator iter = Declaration->decls_begin(), end = Declaration->decls_end(); iter != end; ++iter) {
      clang::Decl const *d = *iter;
      if (!d->isImplicit()) {
        i++;
      }
    }
    AddKSequenceNode(i);
  }

  void AddStmtChildrenNode(Stmt *Statement) {
    int i = 0;
    for (Stmt::child_iterator iter = Statement->child_begin(), end = Statement->child_end(); iter != end; ++i, ++iter);
    AddKSequenceNode(i);
  }
    

  bool VisitTranslationUnitDecl(TranslationUnitDecl *Declaration) {
    AddKApplyNode("TranslationUnit", 2);
    AddKTokenNode(VisitStringRef(InFile), "String");
    AddDeclContextNode(Declaration);
    return false;
  }

  bool TraverseTypedefDecl(TypedefDecl *Declaration) {
    AddKApplyNode("TypedefDecl", 2);
    TRY_TO(TraverseDeclarationName(Declaration->getDeclName()));
    TRY_TO(TraverseType(Declaration->getUnderlyingType()));
    return true;
  }

  bool VisitLinkageSpecDecl(LinkageSpecDecl *Declaration) {
    AddKApplyNode("LinkageSpec", 2);
    const char *s;
    if (Declaration->getLanguage() == LinkageSpecDecl::lang_c) {
      s = "\"C\"";
    } else if (Declaration->getLanguage() == LinkageSpecDecl::lang_cxx) {
      s = "\"C++\"";
    }
    AddKTokenNode(s, "String");
    AddDeclContextNode(Declaration);
    return false;
  }

  bool VisitCXXMethodDecl(CXXMethodDecl *Declaration) {
    doThrow("unimplemented: methods");
  }

  bool TraverseNestedNameSpecifierLoc(NestedNameSpecifierLoc NNS) {
    if (!NNS) {
      AddKApplyNode("NoNamespace", 0);
      return true;
    }
    doThrow("unimplemented: nns");
  }

  bool TraverseDeclarationNameInfo(DeclarationNameInfo NameInfo) {
    return TraverseDeclarationName(NameInfo.getName());
  }

  bool TraverseIdentifierInfo(const IdentifierInfo *info) {
    AddKApplyNode("Identifier", 1);
    char *buf = new char[info->getLength() + 3];
    buf[0] = '\"';
    buf[info->getLength() + 1] = '\"';
    buf[info->getLength() + 2] = 0;
    memcpy(buf + 1, info->getNameStart(), info->getLength());
    AddKTokenNode(buf, "String");
  }
 
  
  bool TraverseDeclarationName(DeclarationName Name) {
    switch(Name.getNameKind()) {
    case DeclarationName::Identifier:
      {
        IdentifierInfo *info = Name.getAsIdentifierInfo();
        TraverseIdentifierInfo(info);
      }
      return true;
    default:
      doThrow("unimplemented: nameinfo");
    }
  }

  bool TraverseTemplateArgumentLoc(const TemplateArgumentLoc &ArgLoc) {
    doThrow("unimplemented: templates");
  }

  void AddSpecifier(const char *str) {
    AddKApplyNode("Specifier", 2);
    AddKApplyNode(str, 0);
  }

  bool VisitFunctionDecl(FunctionDecl *Declaration) {
    if (Declaration->isInlineSpecified()) {
      AddSpecifier("Inline");
    }
    if (Declaration->isConstexpr()) {
      AddSpecifier("Constexpr");
    }
    if (Declaration->getDescribedFunctionTemplate() || 
        Declaration->getTemplateSpecializationInfo()) {
      doThrow("unimplemented: function templates");
    }
    if(!Declaration->getTypeSourceInfo()) {
      doThrow("unimplemented: something implicit???");
    }
    if (Declaration->isThisDeclarationADefinition()) {
      AddKApplyNode("FunctionDefinition", 4);
    } else {
      AddKApplyNode("FunctionDecl", 3);
    }
    return false;
  }

  void AddStorageClass(StorageClass sc) {
    const char *spec;
    switch(sc) {
    case StorageClass::SC_None:
      return;
    case StorageClass::SC_Extern:
      spec = "Extern";
      break;
    case StorageClass::SC_Static:
      spec = "Static";
      break;
    case StorageClass::SC_Register:
      spec = "Register";
      break;
    default:
      doThrow("unimplemented: storage class");
    }
    AddSpecifier(spec);
  }

  void AddThreadStorageClass(ThreadStorageClassSpecifier sc) {
    const char *spec;
    switch(sc) {
    case ThreadStorageClassSpecifier::TSCS_unspecified:
      return;
    case ThreadStorageClassSpecifier::TSCS_thread_local:
      spec = "ThreadLocal";
      break;
    default:
      doThrow("unimplemented: thread storage class");
    }
    AddSpecifier(spec);
  }

  bool TraverseVarDecl(VarDecl *Declaration) {
    AddStorageClass(Declaration->getStorageClass());
    AddThreadStorageClass(Declaration->getTSCSpec());
    if (Declaration->isConstexpr()) {
      AddSpecifier("Constexpr");
    }
    AddKApplyNode("VarDecl", 4);

    TRY_TO(TraverseNestedNameSpecifierLoc(Declaration->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(Declaration->getDeclName()));
    TRY_TO(TraverseType(Declaration->getType()));
    TRY_TO(TraverseStmt(Declaration->getInit()));
    return true;
  }

  bool TraverseFunctionProtoType(FunctionProtoType *T) {
    AddKApplyNode("FunctionPrototype", 5);

    TRY_TO(TraverseType(T->getReturnType()));

    AddKSequenceNode(T->getNumParams());
    for(int i = 0; i < T->getNumParams(); i++) {
      TRY_TO(TraverseType(T->getParamType(i)));
    }

    AddKSequenceNode(T->getNumExceptions());
    for(int i = 0; i < T->getNumExceptions(); i++) {
      TRY_TO(TraverseType(T->getExceptionType(i)));
    }

    if (Stmt *NE = T->getNoexceptExpr()) {
      TRY_TO(TraverseStmt(NE));
    } else {
      AddKApplyNode("NoExpression", 0);
    }

    AddKTokenNode(T->isVariadic() ? "true" : "false", "Bool");
    return true;
  }

  bool VisitBuiltinType(BuiltinType *T) {
    AddKApplyNode("BuiltinType", 1);
    switch(T->getKind()) {
      case BuiltinType::Void:
        AddKApplyNode("Void", 0);
        break;
      case BuiltinType::Char_S:
      case BuiltinType::Char_U:
        AddKApplyNode("Char", 0);
        break;
      case BuiltinType::Bool:
        AddKApplyNode("Bool", 0);
        break;
      case BuiltinType::UChar:
        AddKApplyNode("UChar", 0);
        break;
      case BuiltinType::UShort:
        AddKApplyNode("UShort", 0);
        break;
      case BuiltinType::UInt:
        AddKApplyNode("UInt", 0);
        break;
      case BuiltinType::ULong:
        AddKApplyNode("ULong", 0);
        break;
      case BuiltinType::ULongLong:
        AddKApplyNode("ULongLong", 0);
        break;
      case BuiltinType::SChar:
        AddKApplyNode("SChar", 0);
        break;
      case BuiltinType::Short:
        AddKApplyNode("Short", 0);
        break;
      case BuiltinType::Int:
        AddKApplyNode("Int", 0);
        break;
      case BuiltinType::Long:
        AddKApplyNode("Long", 0);
        break;
      case BuiltinType::LongLong:
        AddKApplyNode("LongLong", 0);
        break;
      case BuiltinType::Float:
        AddKApplyNode("Float", 0);
        break;
      case BuiltinType::Double:
        AddKApplyNode("Double", 0);
        break;
      case BuiltinType::LongDouble:
        AddKApplyNode("LongDouble", 0);
        break;
      case BuiltinType::Int128:
        AddKApplyNode("Int128", 0);
        break;
      case BuiltinType::UInt128:
        AddKApplyNode("UInt128", 0);
        break;
      default:
        doThrow("unimplemented: basic type");
    }
    return false;
  }

  bool VisitPointerType(PointerType *T) {
    AddKApplyNode("PointerType", 1);
    return false;
  }

  bool VisitConstantArrayType(ConstantArrayType *T) {
    switch (T->getSizeModifier()) {
      case ArrayType::Normal: 
        {
          AddKApplyNode("ArrayType", 2);
          std::string *name = new std::string(T->getSize().toString(10, false));
          AddKTokenNode(name->c_str(), "Int");
        }
        break;
      default:
        doThrow("unimplemented: non normal arrays");
    }
    return false;
  }

  bool VisitTypedefType(TypedefType *T) {
    AddKApplyNode("TypedefType", 1);
    TraverseDeclarationName(T->getDecl()->getDeclName());
    return false;
  }

  //TODO(dwightguth): fix location stuff
  bool TraverseTypeLoc(TypeLoc Loc) {
    return TraverseType(Loc.getType());
  }

  void AddQualifiers(QualType T) {
    if (T.isLocalConstQualified()) {
      AddKApplyNode("Qualifier", 2);
      AddKApplyNode("Const", 0);
    }
    if (T.isLocalVolatileQualified()) {
      AddKApplyNode("Qualifier", 2);
      AddKApplyNode("Volatile", 0);
    }
    if (T.isLocalRestrictQualified()) {
      AddKApplyNode("Qualifier", 2);
      AddKApplyNode("Restrict", 0);
    }
  }

  bool TraverseType(QualType T) {
    AddQualifiers(T);
    RecursiveASTVisitor::TraverseType(T);
  }

  bool VisitCompoundStmt(CompoundStmt *Statement) {
    AddKApplyNode("CompoundAStmt", 1);
    AddStmtChildrenNode(Statement);
    return false;
  }

  bool VisitLabelStmt(LabelStmt *Statement) {
    AddKApplyNode("LabelAStmt", 2);
    TRY_TO(TraverseDeclarationName(Statement->getDecl()->getDeclName()));
    AddStmtChildrenNode(Statement);
    return false;
  }

  bool VisitGotoStmt(GotoStmt *Statement) {
    AddKApplyNode("GotoStmt", 1);
    TRY_TO(TraverseDeclarationName(Statement->getLabel()->getDeclName()));
    return false;
  }

  bool VisitDeclStmt(DeclStmt *Statement) {
    AddKApplyNode("DeclStmt", 1);
    int i = 0;
    for (auto *I : Statement->decls()) {
      i++;
    }
    AddKSequenceNode(i);
    return false;
  }

  bool TraverseCallExpr(CallExpr *Expression) {
    AddKApplyNode("CallExpr", 2);
    int i = 0;
    for (Stmt *SubStmt : Expression->children()) {
      i++;
    }
    if (i-1 != Expression->getNumArgs()) {
      doThrow("unimplemented: pre_args???");
    }
    bool first = true;
    for (Stmt *SubStmt : Expression->children()) {
      TRY_TO(TraverseStmt(SubStmt));
      if (first) {
        AddKApplyNode("list", 1);
        AddKSequenceNode(i-1);
      }
      first = false;
    }
    return true;
  }

  bool VisitImplicitCastExpr(ImplicitCastExpr *Expression) {
    return false; // no node created
  }

  bool VisitDeclRefExpr(DeclRefExpr *Expression) {
    AddKApplyNode("Name", 2);
    return false;
  }

  const char *VisitStringRef(StringRef str) {
    return escape(str.begin(), (str.end() - str.begin()));
  }

  bool VisitStringLiteral(StringLiteral *Constant) {
    AddKApplyNode("StringLiteral", 1);
    StringRef str = Constant->getString();
    AddKTokenNode(VisitStringRef(str), "String");
    return false;
  }

private:
  ASTContext *Context;
  llvm::StringRef InFile;
};

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
    doThrow("unexpected kind");
  }
}

int main(int argc, const char **argv) {
  CommonOptionsParser OptionsParser(argc, argv, MyToolCategory);
  ClangTool Tool(OptionsParser.getCompilations(),
                 OptionsParser.getSourcePathList());

  // nasty hacky garbage in order to gain access to the output sent to stderr
  // so we can filter it
  dupedFd = dup(STDERR_FILENO);
  int master = posix_openpt(O_RDWR | O_NOCTTY);
  grantpt(master);
  unlockpt(master);
  int slave = open(ptsname(master), O_RDWR | O_NOCTTY);
  dup2(slave, STDERR_FILENO);
  int ret = Tool.run(newFrontendActionFactory<GetKASTAction>().get());
  dup2(dupedFd, STDERR_FILENO);
  close(dupedFd);
  close(slave);
  char *buf = NULL;
  char *buf2 = NULL;
  size_t n = 0;
  FILE *temp = fdopen(master, "r");
  do {
    if (buf2) fprintf(stderr, "%s", buf2);
    free(buf2);
    buf2 = buf;
    buf = NULL;
    n = 0;
  } while (getline(&buf, &n, temp) != -1);
  close(master);
  if (ret != 0) {
    return ret;
  }
  int idx = 0;
  makeKast(idx);
  printf("\n");
}

