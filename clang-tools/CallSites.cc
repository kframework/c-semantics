#define _XOPEN_SOURCE 700

#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcomment"
#elif defined __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomment"
#endif

#include "clang/AST/ASTConsumer.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"

#ifdef __GNUC__
#pragma GCC diagnostic pop
#elif defined __clang__
#pragma clang diagnostic pop
#endif

#include <cstdio>
#include <string>

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

static cl::opt<std::string> CharSign("char", cl::cat(MyToolCategory));

const char *char_type;

class ProcessTypeVisitor
  : public RecursiveASTVisitor<ProcessTypeVisitor> {
public:
  explicit ProcessTypeVisitor(ASTContext *Context) { }

#define WALK_UP_HELPER(CALL_EXPR)                                             \
  do {                                                                        \
    if (!getDerived().CALL_EXPR)                                              \
      return true;                                                            \
    } while (0)


#define TYPE(CLASS, BASE)                                                     \
  bool WalkUpFrom##CLASS##Type(clang::CLASS##Type *T) {                       \
    WALK_UP_HELPER(Visit##CLASS##Type(T));                                    \
    WALK_UP_HELPER(WalkUpFrom##BASE(T));                                      \
    return true;                                                              \
  }
#include "clang/AST/TypeNodes.def"

  bool TraverseConstantArrayType(ConstantArrayType *T) {
    outs() << "p_";
    return true;
  }
  bool TraverseIncompleteArrayType(IncompleteArrayType *T) {
    outs() << "p_";
    return true;
  }
  bool TraverseVariableArrayType(VariableArrayType *T) {
    outs() << "p_";
    return true;
  }
  bool TraverseFunctionNoProtoType(FunctionNoProtoType *T) {
    outs() << "p_";
    return true;
  }
  bool TraverseFunctionProtoType(FunctionProtoType *T) {
    outs() << "p_";
    return true;
  }
  bool TraversePointerType(clang::PointerType *T) {
    outs() << "p_";
    return true;
  }

  bool TraverseDecayedType(DecayedType *T) {
    outs() << "p_";
    return true;
  }

  bool VisitBuiltinType(BuiltinType *T) {
    switch (T->getKind()) {
      case BuiltinType::Void:
        outs() << "v_";
        break;
      case BuiltinType::SChar:
        outs() << "sc_";
        break;
      case BuiltinType::Char_S:
      case BuiltinType::Char_U:
        outs() << char_type << "_";
        break;
      case BuiltinType::Bool:
        outs() << "b_";
        break;
      case BuiltinType::UChar:
        outs() << "uc_";
        break;
      case BuiltinType::UShort:
        outs() << "us_";
        break;
      case BuiltinType::UInt:
        outs() << "ui_";
        break;
      case BuiltinType::ULong:
        outs() << "ul_";
        break;
      case BuiltinType::ULongLong:
        outs() << "ull_";
        break;
      case BuiltinType::Short:
        outs() << "ss_";
        break;
      case BuiltinType::Int:
        outs() << "si_";
        break;
      case BuiltinType::Long:
        outs() << "sl_";
        break;
      case BuiltinType::LongLong:
        outs() << "ll_";
        break;
      case BuiltinType::Float:
        outs() << "f_";
        break;
      case BuiltinType::Double:
        outs() << "d_";
        break;
      case BuiltinType::LongDouble:
        outs() << "ld_";
        break;
      default:
        T->dump();
        throw std::logic_error("unimplemented: basic type");
    }
    return false;
  }

  bool TraverseComplexType(ComplexType *T) {
    outs() << "c";
    TraverseType(T->getElementType());
    return true;
  }

  bool TraverseAtomicType(AtomicType *T) {
    outs() << "a_";
    TraverseType(T->getValueType());
    return true;
  }

  bool TraverseEnumType(EnumType *T) {
    TraverseType(T->getDecl()->getPromotionType());
    return true;
  }

  bool TraverseElaboratedType(ElaboratedType *T) {
    TraverseType(T->desugar());
    return true;
  }

  bool TraverseTypedefType(TypedefType *T) {
    TraverseType(T->desugar());
    return true;
  }

  bool TraverseRecordType(RecordType *T) {
    processRecord(T->getDecl());
    return true;
  }

  void processRecord(RecordDecl *D) {
    if (D->isStruct()) {
      outs() << "s";
    } else if (D->isUnion()) {
      outs() << "u";
    } else {
      D->dump();
      throw std::logic_error("unimplemented: record type");
    }
    unsigned nfields = 0;
    for (const auto &F : D->fields()) {
      nfields++;
    }
    outs() << nfields << "_";
    for (const auto &F : D->fields()) {
      TraverseType(F->getType());
    }
  }

  bool VisitType(clang::Type *T) {
    T->dump();
    throw std::logic_error("unsupported type");
  }

};

void processType(QualType T, ASTContext *Context) {
  const clang::Type *type_ptr = T.getTypePtr();
  ProcessTypeVisitor Visitor = ProcessTypeVisitor(Context);
  Visitor.TraverseType(T);
}

class GetCallSitesVisitor
  : public RecursiveASTVisitor<GetCallSitesVisitor> {
public:
  explicit GetCallSitesVisitor(ASTContext *Context)
    : Context(Context), Mangle(Context->createMangleContext()) {
  }

  bool VisitCallExpr(CallExpr *E) {
    Expr *callee = E->getCallee();
    QualType callee_type = callee->getType();
    const clang::Type *callee_type_ptr = callee_type.getTypePtr();
    QualType pointee_type = callee_type_ptr->getPointeeType();
    const clang::Type *pointee_type_ptr = pointee_type.getTypePtr();
    const clang::FunctionType *function_type = pointee_type_ptr->getAs<clang::FunctionType>();
    processType(function_type->getReturnType(), Context);
    if (const FunctionProtoType *prototype = function_type->getAs<FunctionProtoType>()) {
      unsigned nparams = prototype->getNumParams();
      unsigned nargs = E->getNumArgs();
      for (unsigned i = 0; i < nargs; i++) {
        processType(E->getArg(i)->getType(), Context);
      }
      outs() << nparams << "_" << (prototype->isVariadic() ? "v\n" : "f\n");
    } else {
      unsigned nargs = E->getNumArgs();
      for (unsigned i = 0; i < nargs; i++) {
        processType(E->getArg(i)->getType(), Context);
      }
      outs() << nargs << "_f\n";
    }
    return true;
  }

  bool VisitDeclRefExpr(DeclRefExpr *E) {
    if (E->getDecl()->getFormalLinkage() == Linkage::ExternalLinkage) {
      outs() << "\t";
      E->getNameInfo().printName(outs());
      outs() << "\n";
    }
    return true;
  }

private:
  ASTContext *Context;
  MangleContext *Mangle;
};


class GetCallSitesConsumer : public clang::ASTConsumer {
public:
  explicit GetCallSitesConsumer(ASTContext *Context, llvm::StringRef InFile)
    : Visitor(Context) {}

  virtual void HandleTranslationUnit(clang::ASTContext &Context) {
    Visitor.TraverseDecl(Context.getTranslationUnitDecl());
  }
private:
  GetCallSitesVisitor Visitor;
};

class GetCallSitesAction : public clang::ASTFrontendAction {
public:
  virtual std::unique_ptr<clang::ASTConsumer> CreateASTConsumer(
    clang::CompilerInstance &Compiler, llvm::StringRef InFile) {
    Compiler.getDiagnostics().setClient(new IgnoringDiagConsumer());
    return std::unique_ptr<clang::ASTConsumer>(
        new GetCallSitesConsumer(&Compiler.getASTContext(), InFile));
  }
};



int main(int argc, const char **argv) {
  CommonOptionsParser OptionsParser(argc, argv, MyToolCategory);
  char_type = CharSign.getValue().c_str();
  ClangTool Tool(OptionsParser.getCompilations(),
                 OptionsParser.getSourcePathList());
  int ret = Tool.run(newFrontendActionFactory<GetCallSitesAction>().get());
  return ret;
}
