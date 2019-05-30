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
#include "llvm/Support/CommandLine.h"

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
        sprintf(buf, "\\x%02hhx", (unsigned char)c);
        *res += buf;
      }
    }
  }
  res->push_back('\"');
  return res->c_str();
}

[[ noreturn ]] void doThrow(const char *str) {
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

  bool shouldVisitTemplateInstantiations() { return true; }

// if we reach all the way to the top of a hierarchy, crash with an error
// because we don't support the node

  bool VisitDecl(Decl *D) {
    dup2(dupedFd, STDERR_FILENO);
    D->dump();
    throw std::logic_error("unimplemented decl");
  }

  bool VisitStmt(Stmt *S) {
    dup2(dupedFd, STDERR_FILENO);
    S->dump();
    throw std::logic_error("unimplemented stmt");
  }

  bool VisitType(clang::Type *T) {
    dup2(dupedFd, STDERR_FILENO);
    T->dump();
    printf("%s", T->getTypeClassName());
    throw std::logic_error("unimplemented type");
  }

  bool TraverseTypeLoc(TypeLoc TL) {
    return TraverseType(TL.getType());
  }

  bool TraverseStmt(Stmt *S) {
    if (!S)
      return RecursiveASTVisitor::TraverseStmt(S);

    if (Expr *E = dyn_cast<Expr>(S)) {
      AddKApplyNode("ExprLoc", 2);
      AddCabsLoc(E->getExprLoc());
    }
    return RecursiveASTVisitor::TraverseStmt(S);
  }

  // copied from RecursiveASTVisitor.h with a change made: D->isImplicit() -> excludedDecl(D)
  bool TraverseDecl(Decl *D) {
    if (!D)
      return true;

    if (excludedDecl(D))
      return true;

    AddKApplyNode("DeclLoc", 2);
    AddCabsLoc(D->getLocation());

    switch (D->getKind()) {
#define ABSTRACT_DECL(DECL)
#define DECL(CLASS, BASE)                                                      \
    case Decl::CLASS:                                                            \
      if (!getDerived().Traverse##CLASS##Decl(static_cast<CLASS##Decl *>(D)))    \
        return false;                                                            \
      break;
#include "clang/AST/DeclNodes.inc"
    }

    // Visit any attributes attached to this declaration.
    // for (auto *I : D->attrs()) {
    //   if (!getDerived().TraverseAttr(I))
    //     return false;
    // }
    return true;
  }

  void AddCabsLoc(SourceLocation loc) {
    SourceManager &mgr = Context->getSourceManager();
    PresumedLoc presumed = mgr.getPresumedLoc(loc);
    if (presumed.isValid()) {
      AddKApplyNode("CabsLoc", 5);
      AddKTokenNode(escape(presumed.getFilename(), strlen(presumed.getFilename())), "String");
      StringRef filename(presumed.getFilename());
      SmallString<64> vector(filename);
      llvm::sys::fs::make_absolute(vector);
      const char *absolute = vector.c_str();
      AddKTokenNode(escape(absolute, strlen(absolute)), "String");
      VisitUnsigned(presumed.getLine());
      VisitUnsigned(presumed.getColumn());
      VisitBool(mgr.isInSystemHeader(loc));
    } else {
      AddKApplyNode("UnknownCabsLoc_COMMON-SYNTAX", 0);
    }
  }

// modify the evaluation strategy so that we walk up from the base to the
// parent, stopping if any of the nodes are successfully visited (but
// continuing to the next node)

#define STMT(CLASS, PARENT)                                                   \
  bool WalkUpFrom##CLASS(CLASS *S) {                                          \
    WALK_UP_HELPER(Visit##CLASS(S));                                          \
    WALK_UP_HELPER(WalkUpFrom##PARENT(S));                                    \
    return true;                                                              \
  }
#include "clang/AST/StmtNodes.inc"

#define TYPE(CLASS, BASE)                                                     \
  bool WalkUpFrom##CLASS##Type(clang::CLASS##Type *T) {                       \
    WALK_UP_HELPER(Visit##CLASS##Type(T));                                    \
    WALK_UP_HELPER(WalkUpFrom##BASE(T));                                      \
    return true;                                                              \
  }
#include "clang/AST/TypeNodes.def"

#define DECL(CLASS, BASE)                                                     \
  bool WalkUpFrom##CLASS##Decl(CLASS##Decl *D) {                              \
    WALK_UP_HELPER(Visit##CLASS##Decl(D));                                    \
    WALK_UP_HELPER(WalkUpFrom##BASE(D));                                      \
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

  // backported from later version of clang into this binary because we need it
  // to check for anonymous unions
  template <typename T>
  inline T getTypeLocAsAdjusted(TypeLoc Cur) const {
    while (!Cur.getAs<T>()) {
      if (auto PTL = Cur.getAs<ParenTypeLoc>())
        Cur = PTL.getInnerLoc();
      else if (auto ATL = Cur.getAs<AttributedTypeLoc>())
        Cur = ATL.getModifiedLoc();
      else if (auto ETL = Cur.getAs<ElaboratedTypeLoc>())
        Cur = ETL.getNamedTypeLoc();
      else if (auto ATL = Cur.getAs<AdjustedTypeLoc>())
        Cur = ATL.getOriginalLoc();
      else
        break;
    }
    return Cur.getAs<T>();
  }

  bool isAnonymousUnionVarDecl(const clang::Decl *D) {
    if (const VarDecl *VD = dyn_cast<VarDecl>(D)) {
      TypeLoc TL = VD->getTypeSourceInfo()->getTypeLoc();
      if (RecordTypeLoc RTL = getTypeLocAsAdjusted<RecordTypeLoc>(TL)) {
        return RTL.getDecl()->isAnonymousStructOrUnion();
      }
    }
    return false;
  }

  bool excludedDecl(clang::Decl const *d) {
    return d->isImplicit() && d->isDefinedOutsideFunctionOrMethod();
  }

  void AddDeclContextNode(DeclContext *D) {
    int i = 0;
    for (DeclContext::decl_iterator iter = D->decls_begin(), end = D->decls_end(); iter != end; ++iter) {
      clang::Decl const *d = *iter;
      if (!excludedDecl(d)) {
        i++;
      }
    }
    AddKSequenceNode(i);
  }

  bool TraverseDeclContextNode(DeclContext *D) {
    for (DeclContext::decl_iterator iter = D->decls_begin(), end = D->decls_end(); iter != end; ++iter) {
      clang::Decl *d = *iter;
      if (!excludedDecl(d)) {
        TRY_TO(TraverseDecl(d));
      }
    }
    return true;
  }

  void AddStmtChildrenNode(Stmt *S) {
    int i = 0;
    for (Stmt::child_iterator iter = S->child_begin(), end = S->child_end(); iter != end; ++i, ++iter);
    AddKSequenceNode(i);
  }

  bool VisitTranslationUnitDecl(TranslationUnitDecl *D) {
    AddKApplyNode("TranslationUnit", 2);
    VisitStringRef(InFile);
    AddDeclContextNode(D);
    return false;
  }

  bool VisitTypedefDecl(TypedefDecl *D) {
    AddKApplyNode("TypedefDecl", 2);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }

  bool VisitTypeAliasDecl(TypeAliasDecl *D) {
    AddKApplyNode("TypeAliasDecl", 2);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }


  bool VisitLinkageSpecDecl(LinkageSpecDecl *D) {
    AddKApplyNode("LinkageSpec", 3);
    const char *s;
    if (D->getLanguage() == LinkageSpecDecl::lang_c) {
      s = "\"C\"";
    } else if (D->getLanguage() == LinkageSpecDecl::lang_cxx) {
      s = "\"C++\"";
    }
    AddKTokenNode(s, "String");
    VisitBool(D->hasBraces());
    AddDeclContextNode(D);
    return false;
  }

  void VisitBool(bool b) {
    AddKTokenNode(b ? "true" : "false", "Bool");
  }

  bool VisitNamespaceDecl(NamespaceDecl *D) {
    AddKApplyNode("NamespaceDecl", 3);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    VisitBool(D->isInline());
    AddDeclContextNode(D);
    return false;
  }

  bool VisitNamespaceAliasDecl(NamespaceAliasDecl *D) {
    AddKApplyNode("NamespaceAliasDecl", 3);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseDeclarationAsName(D->getNamespace()));
    TRY_TO(TraverseNestedNameSpecifier(D->getQualifier()));
    return false;
  }

  bool TraverseNestedNameSpecifierLoc(NestedNameSpecifierLoc NNS) {
    return TraverseNestedNameSpecifier(NNS.getNestedNameSpecifier());
  }

  bool TraverseNestedNameSpecifier(NestedNameSpecifier *NNS) {
    if (!NNS) {
      AddKApplyNode("NoNNS", 0);
      return true;
    }
    if (NNS->getPrefix()) {
      AddKApplyNode("NestedName", 2);
      TRY_TO(TraverseNestedNameSpecifier(NNS->getPrefix()));
    }
    switch (NNS->getKind()) {
    case NestedNameSpecifier::Identifier:
      AddKApplyNode("NNS", 1);
      TRY_TO(TraverseIdentifierInfo(NNS->getAsIdentifier()));
      break;
    case NestedNameSpecifier::Namespace:
      AddKApplyNode("NNS", 1);
      TRY_TO(TraverseDeclarationName(NNS->getAsNamespace()->getDeclName()));
      break;
    case NestedNameSpecifier::NamespaceAlias:
      AddKApplyNode("NNS", 1);
      TRY_TO(TraverseDeclarationName(NNS->getAsNamespaceAlias()->getDeclName()));
      break;
    case NestedNameSpecifier::TypeSpec:
      AddKApplyNode("NNS", 1);
      TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
      break;
    case NestedNameSpecifier::TypeSpecWithTemplate:
      AddKApplyNode("TemplateNNS", 1);
      TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
      break;
    case NestedNameSpecifier::Global:
      AddKApplyNode("GlobalNamespace", 0);
      break;
    default:
      doThrow("unimplemented: nns");
    }
    return true;
  }

  bool TraverseDeclarationNameInfo(DeclarationNameInfo NameInfo) {
    return TraverseDeclarationName(NameInfo.getName());
  }

  bool TraverseIdentifierInfo(const IdentifierInfo *info) {
    return TraverseIdentifierInfo(info, 0);
  }

  bool TraverseIdentifierInfo(const IdentifierInfo *info, uintptr_t decl) {
    if (!info) {
      if (decl == 0) {
        AddKApplyNode("#NoName_COMMON-SYNTAX", 0);
      } else {
        AddKApplyNode("unnamed", 2);
        VisitUnsigned((unsigned long long)decl);
        VisitStringRef(InFile);
      }
      return true;
    }
    AddKApplyNode("Identifier", 1);
    char *buf = new char[info->getLength() + 3];
    buf[0] = '\"';
    buf[info->getLength() + 1] = '\"';
    buf[info->getLength() + 2] = 0;
    memcpy(buf + 1, info->getNameStart(), info->getLength());
    AddKTokenNode(buf, "String");
    return true;
  }

  bool TraverseDeclarationAsName(NamedDecl *D) {
    return TraverseDeclarationName(D->getDeclName(), (uintptr_t)D);
  }

  bool TraverseDeclarationName(DeclarationName Name) {
    return TraverseDeclarationName(Name, 0);
  }

  bool TraverseDeclarationName(DeclarationName Name, uintptr_t decl) {
    switch(Name.getNameKind()) {
    case DeclarationName::Identifier:
      {
        IdentifierInfo *info = Name.getAsIdentifierInfo();
        return TraverseIdentifierInfo(info, decl);
      }
    case DeclarationName::CXXConversionFunctionName:
    case DeclarationName::CXXConstructorName:
      {
        AddKApplyNode("TypeId", 1);
        TRY_TO(TraverseType(Name.getCXXNameType()));
        return true;
      }
    case DeclarationName::CXXDestructorName:
      {
        AddKApplyNode("DestructorTypeId", 1);
        TRY_TO(TraverseType(Name.getCXXNameType()));
        return true;
      }
    case DeclarationName::CXXOperatorName:
      {
        VisitOperator(Name.getCXXOverloadedOperator());
        return true;
      }
    case DeclarationName::CXXLiteralOperatorName:
      {
        IdentifierInfo *info = Name.getCXXLiteralIdentifier();
        return TraverseIdentifierInfo(info, decl);
      }
    default:
      doThrow("unimplemented: nameinfo");
    }
  }

  void AddSpecifier(const char *str) {
    AddKApplyNode("Specifier", 2);
    AddKApplyNode(str, 0);
  }

  void AddSpecifier(const char *str, unsigned n) {
    AddKApplyNode("Specifier", 2);
    AddKApplyNode(str, 1);
    VisitUnsigned(n);
  }

  bool TraverseConstructorInitializer(CXXCtorInitializer *Init) {
    if (Init->isBaseInitializer()) {
      AddKApplyNode("ConstructorBase", 4);
      TRY_TO(TraverseTypeLoc(Init->getTypeSourceInfo()->getTypeLoc()));
      VisitBool(Init->isBaseVirtual());
      VisitBool(Init->isPackExpansion());
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isMemberInitializer()) {
      AddKApplyNode("ConstructorMember", 2);
      TRY_TO(TraverseDeclarationName(Init->getMember()->getDeclName()));
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isDelegatingInitializer()) {
      AddKApplyNode("ConstructorDelegating", 1);
      TRY_TO(TraverseStmt(Init->getInit()));
    } else {
      doThrow("unimplemented: ctor initializer");
    }
    return true;
  }

  bool TraverseFunctionHelper(FunctionDecl *D) {
    if (const FunctionTemplateSpecializationInfo *FTSI =
            D->getTemplateSpecializationInfo()) {
      if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitSpecialization) {
        if (const ASTTemplateArgumentListInfo *TALI =
                FTSI->TemplateArgumentsAsWritten) {
          AddKApplyNode("TemplateSpecialization", 2);
          AddKApplyNode("TemplateSpecializationType", 2);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          AddKSequenceNode(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          AddKApplyNode("TemplateSpecialization", 2);
          AddKApplyNode("TemplateSpecializationType", 1);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      } else if (FTSI->getTemplateSpecializationKind() != TSK_Undeclared &&
          FTSI->getTemplateSpecializationKind() != TSK_ImplicitInstantiation) {
        if (const ASTTemplateArgumentListInfo *TALI =
                FTSI->TemplateArgumentsAsWritten) {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             AddKApplyNode("TemplateInstantiationDefinition", 2);
          } else {
             AddKApplyNode("TemplateInstantiationDeclaration", 2);
          }
          AddKApplyNode("TemplateSpecializationType", 2);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          AddKSequenceNode(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             AddKApplyNode("TemplateInstantiationDefinition", 2);
          } else {
             AddKApplyNode("TemplateInstantiationDeclaration", 2);
          }
          AddKApplyNode("TemplateSpecializationType", 1);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      }
    }

    AddStorageClass(D->getStorageClass());
    if (D->isInlineSpecified()) {
      AddSpecifier("Inline");
    }
    if (D->isConstexpr()) {
      AddSpecifier("Constexpr");
    }

    if (D->isThisDeclarationADefinition() || D->isExplicitlyDefaulted()) {
      AddKApplyNode("FunctionDefinition", 6);
    } else {
      AddKApplyNode("FunctionDecl", 5);
    }

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(D->getNameInfo()));

    mangledIdentifier(D);

    if (TypeSourceInfo *TSI = D->getTypeSourceInfo()) {
      if (CXXMethodDecl *Method = dyn_cast<CXXMethodDecl>(D)) {
        if (Method->isInstance()) {
          switch(Method->getRefQualifier()) {
            case RQ_LValue:
            AddKApplyNode("RefQualifier",2);
            AddKApplyNode("RefLValue", 0);
            break;
            case RQ_RValue:
            AddKApplyNode("RefQualifier",2);
            AddKApplyNode("RefRValue", 0);
            break;
            case RQ_None: // do nothing
            break;
          }
          AddKApplyNode("MethodPrototype", 4);
          VisitBool(Method->isUserProvided());
          VisitBool(dyn_cast<CXXConstructorDecl>(D)); // converts to true if this is a constructor
          TRY_TO(TraverseType(Method->getThisType(*Context)));
          if (Method->isVirtual()) {
            AddKApplyNode("Virtual", 1);
          }
          if (Method->isPure()) {
            AddKApplyNode("Pure", 1);
          }

          if (CXXConversionDecl *Conv = dyn_cast<CXXConversionDecl>(D)) {
            if (Conv->isExplicitSpecified()) {
              AddKApplyNode("Explicit", 1);
            }
          }

          if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
            if (Ctor->isExplicitSpecified()) {
              AddKApplyNode("Explicit", 1);
            }
          }
        } else {
          AddKApplyNode("StaticMethodPrototype", 1);
        }
      }
      TRY_TO(TraverseType(D->getType()));
    } else {
      doThrow("something implicit in functions??");
    }

    AddKSequenceNode(D->parameters().size());
    for (unsigned i = 0; i < D->parameters().size(); i++) {
      TRY_TO(TraverseDecl(D->parameters()[i]));
    }

    if (D->isThisDeclarationADefinition()) {
      if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
        AddKApplyNode("Constructor", 2);
        int i = 0;
        for (auto *I : Ctor->inits()) {
          if(I->isWritten()) {
            i++;
          }
        }
        AddKSequenceNode(i);
        for (auto *I : Ctor->inits()) {
          if(I->isWritten()) {
            TRY_TO(TraverseConstructorInitializer(I));
          }
        }
      }
      TRY_TO(TraverseStmt(D->getBody()));
    }
    if (D->isExplicitlyDefaulted()) {
      AddKApplyNode("Defaulted", 0);
    } else if (D->isDeleted()) {
      AddKApplyNode("Deleted", 0);
    }
    return true;
  }

  bool TraverseFunctionDecl(FunctionDecl *D) {
    return TraverseFunctionHelper(D);
  }

  bool TraverseCXXMethodDecl(CXXMethodDecl *D) {
    return TraverseFunctionHelper(D);
  }

  bool TraverseCXXDestructorDecl(CXXDestructorDecl *D) {
    return TraverseFunctionHelper(D);
  }

  bool TraverseCXXConstructorDecl(CXXConstructorDecl *D) {
    return TraverseFunctionHelper(D);
  }

  bool TraverseCXXConversionDecl(CXXConversionDecl *D) {
    return TraverseFunctionHelper(D);
  }

  bool TraverseVarHelper(VarDecl *D) {
    AddStorageClass(D->getStorageClass());
    AddThreadStorageClass(D->getTSCSpec());
    if (D->isConstexpr()) {
      AddSpecifier("Constexpr");
    }
    if (unsigned align = D->getMaxAlignment()) {
      AddSpecifier("Alignas", align / 8);
    }
    AddKApplyNode("VarDecl", 6);

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));

    mangledIdentifier(D);

    TRY_TO(TraverseType(D->getType()));
    if (D->getInit()) {
      TRY_TO(TraverseStmt(D->getInit()));
    } else {
      AddKApplyNode("NoInit", 0);
    }
    VisitBool(D->isDirectInit());
    return true;
  }

  bool TraverseVarDecl(VarDecl *D) {
    return TraverseVarHelper(D);
  }

  bool TraverseFieldDecl(FieldDecl *D) {
    if (D->isMutable()) {
      AddSpecifier("Mutable");
    }
    if (D->isBitField()) {
      AddKApplyNode("BitFieldDecl", 4);
    } else {
      AddKApplyNode("FieldDecl", 4);
    }
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if (D->isBitField()) {
      TRY_TO(TraverseStmt(D->getBitWidth()));
    } else if (D->hasInClassInitializer()) {
      TRY_TO(TraverseStmt(D->getInClassInitializer()));
    } else {
      AddKApplyNode("NoInit", 0);
    }
    return true;
  }

  bool TraverseParmVarDecl(ParmVarDecl *D) {
    //TODO(other stuff)
    return TraverseVarHelper(D);
  }

  bool VisitFriendDecl(FriendDecl *D) {
    AddKApplyNode("FriendDecl", 1);
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
    case StorageClass::SC_Auto:
      spec = "Auto";
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

  void VisitAccessSpecifier(AccessSpecifier Spec) {
    const char *spec;
    switch(Spec) {
    case AS_public:
      spec = "Public";
      break;
    case AS_protected:
      spec = "Protected";
      break;
    case AS_private:
      spec = "Private";
      break;
    case AS_none:
      spec = "NoAccessSpec";
      break;
    }
    AddKApplyNode(spec, 0);
  }

  #define TRAVERSE_TEMPLATE_DECL(DeclKind) \
  bool Traverse##DeclKind##TemplateDecl(DeclKind##TemplateDecl *D) { \
    AddKApplyNode("TemplateWithInstantiations", 3); \
    TRY_TO(TraverseDecl(D->getTemplatedDecl())); \
    TemplateParameterList *TPL = D->getTemplateParameters(); \
    if (TPL) { \
      int i = 0; \
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++i, ++I); \
      AddKSequenceNode(i); \
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++I) { \
        TRY_TO(TraverseDecl(*I)); \
      } \
    } \
    TRY_TO(TraverseTemplateInstantiations(D)); \
    return true; \
  }
  TRAVERSE_TEMPLATE_DECL(Class)
  TRAVERSE_TEMPLATE_DECL(Function)
  TRAVERSE_TEMPLATE_DECL(TypeAlias)

  bool TraverseTemplateInstantiations(ClassTemplateDecl *D) {
    unsigned i = 0;
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        i++;
      default:
        break;
      }
    }
    AddKSequenceNode(i);
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        TRY_TO(TraverseDecl(FD));
      default:
        break;
      }
    }
    return true;
  }

  bool TraverseTemplateInstantiations(TypeAliasTemplateDecl *D) {
    AddKSequenceNode(0);
    return true;
  }

  bool TraverseTemplateInstantiations(VarTemplateDecl *D) {
    unsigned i = 0;
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        i++;
      default:
        break;
      }
    }
    AddKSequenceNode(i);
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        TRY_TO(TraverseDecl(FD));
      default:
        break;
      }
    }
    return true;
  }

  //TODO(dwightguth): we need to fix this so that clang actually
  // has an AST for function template instantiations, because
  // the point of instantiation can have an effect on whether
  // the instantiation is undefined or not.
  bool TraverseTemplateInstantiations(FunctionTemplateDecl *D) {
    unsigned i = 0;
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        i++;
      default:
        break;
      }
    }
    AddKSequenceNode(i);
    for (auto *FD : D->specializations()) {
      switch(FD->getTemplateSpecializationKind()) {
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDeclaration:
      case TSK_ExplicitInstantiationDefinition:
        TRY_TO(TraverseDecl(FD));
      default:
        break;
      }
    }
    return true;
  }

  bool TraverseTemplateTypeParmDecl(TemplateTypeParmDecl *D) {
    AddKApplyNode("TypeTemplateParam", 4);
    VisitBool(D->wasDeclaredWithTypename());
    VisitBool(D->isParameterPack());
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      AddKApplyNode("NoType", 0);
    }
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseType(D->getDefaultArgumentInfo()->getType()));
    } else {
      AddKApplyNode("NoType", 0);
    }
    return true;
  }

  bool TraverseNonTypeTemplateParmDecl(NonTypeTemplateParmDecl *D) {
    AddKApplyNode("ValueTemplateParam", 5);
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseStmt(D->getDefaultArgument()));
    } else {
      AddKApplyNode("NoExpression", 0);
    }
    return true;
  }

  bool TraverseTemplateTemplateParmDecl(TemplateTemplateParmDecl *D) {
    AddKApplyNode("TemplateTemplateParam", 4);
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseTemplateArgumentLoc(D->getDefaultArgument()));
    } else {
      AddKApplyNode("NoType", 0);
    }
    TemplateParameterList *TPL = D->getTemplateParameters();
    if (TPL) {
      int i = 0;
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++i, ++I);
      AddKSequenceNode(i);
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++I) {
        TRY_TO(TraverseDecl(*I));
      }
    }
    return true;

  }

  bool TraverseTemplateArgument(const TemplateArgument &Arg) {
    switch(Arg.getKind()) {
    case TemplateArgument::Type:
      AddKApplyNode("TypeArg", 1);
      return getDerived().TraverseType(Arg.getAsType());
    case TemplateArgument::Template:
      AddKApplyNode("TemplateArg", 1);
      return getDerived().TraverseTemplateName(Arg.getAsTemplate());
    case TemplateArgument::Expression:
      AddKApplyNode("ExprArg", 1);
      return getDerived().TraverseStmt(Arg.getAsExpr());
    case TemplateArgument::Integral:
      AddKApplyNode("ExprArg", 1);
      AddKApplyNode("IntegerLiteral", 2);
      VisitAPInt(Arg.getAsIntegral());
      return getDerived().TraverseType(Arg.getIntegralType());
    case TemplateArgument::Pack:
      AddKApplyNode("PackArg", 1);
      AddKSequenceNode(Arg.pack_size());
      for (const TemplateArgument arg : Arg.pack_elements()) {
        TRY_TO(TraverseTemplateArgument(arg));
      }
      return true;
    default:
      doThrow("unimplemented: template argument");
    }
  }

  bool TraverseTemplateName(TemplateName Name) {
    switch(Name.getKind()) {
    case TemplateName::Template:
      TRY_TO(TraverseDeclarationName(Name.getAsTemplateDecl()->getDeclName()));
      break;
    default:
      doThrow("unimplemented: template name");
    }
    return true;
  }



  bool TraverseTemplateArgumentLoc(const TemplateArgumentLoc &Arg) {
    return TraverseTemplateArgument(Arg.getArgument());
  }

  bool TraverseTemplateArgumentLocs(
      const TemplateArgumentLoc *TAL, unsigned Count) {
    for (unsigned I = 0; I < Count; ++I) {
      TRY_TO(TraverseTemplateArgumentLoc(TAL[I]));
    }
    return true;
  }

  void VisitTagKind(TagTypeKind T) {
    switch (T) {
    case TTK_Struct:
      AddKApplyNode("Struct", 0);
      break;
    case TTK_Union:
      AddKApplyNode("Union", 0);
      break;
    case TTK_Class:
      AddKApplyNode("Class", 0);
      break;
    case TTK_Enum:
      AddKApplyNode("Enum", 0);
      break;
    default:
      doThrow("unimplemented: tag kind");
    }
  }

  bool TraverseCXXRecordHelper(CXXRecordDecl *D) {
    if (D->isCompleteDefinition()) {
      AddKApplyNode("ClassDef", 6);
    } else {
      AddKApplyNode("TypeDecl", 1);
      AddKApplyNode("ElaboratedTypeSpecifier", 3);
    }
    VisitTagKind(D->getTagKind());
    TRY_TO(TraverseDeclarationAsName(D));
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    if (D->isCompleteDefinition()) {
      int i = 0;
      for (const auto &I : D->bases()) {
        i++;
      }
      AddKSequenceNode(i);
      for (const auto &I : D->bases()) {
        AddKApplyNode("BaseClass", 4);
        VisitBool(I.isVirtual());
        VisitBool(I.isPackExpansion());
        VisitAccessSpecifier(I.getAccessSpecifierAsWritten());
        TRY_TO(TraverseType(I.getType()));
      }
      AddDeclContextNode(D);
      TraverseDeclContextNode(D);
      VisitBool(D->isAnonymousStructOrUnion());
    }
    return true;
  }

  bool TraverseCXXRecordDecl(CXXRecordDecl *D) {
    TRY_TO(TraverseCXXRecordHelper(D));
    return true;
  }

  bool TraverseEnumDecl(EnumDecl *D) {
    if (!D->isCompleteDefinition()) {
      AddKApplyNode("OpaqueEnumDeclaration", 3);
      TRY_TO(TraverseDeclarationName(D->getDeclName()));
      VisitBool(D->isScoped());
      TraverseType(D->getIntegerType());
      return true;
    }

    AddKApplyNode("EnumDef", 6);
    TRY_TO(TraverseDeclarationAsName(D));
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    VisitBool(D->isScoped());
    VisitBool(D->isFixed());
    TraverseType(D->getIntegerType());

    AddDeclContextNode(D);
    TraverseDeclContextNode(D);
    return true;
  }

  bool VisitEnumConstantDecl(EnumConstantDecl *D) {
    AddKApplyNode("Enumerator", 2);
    TraverseDeclarationName(D->getDeclName());
    if (!D->getInitExpr()) {
      AddKApplyNode("NoExpression", 0);
    }
    return false;
  }

  bool TraverseClassTemplateSpecializationDecl(ClassTemplateSpecializationDecl *D) {
    switch(D->getSpecializationKind()) {
      case TSK_ExplicitSpecialization:
        AddKApplyNode("TemplateSpecialization", 2);
        break;
      case TSK_ExplicitInstantiationDeclaration:
        AddKApplyNode("TemplateInstantiationDeclaration", 2);
        break;
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDefinition:
        AddKApplyNode("TemplateInstantiationDefinition", 2);
        break;
      default:
        doThrow("unimplemented: implicit template instantiation");
    }
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      AddKApplyNode("NoType", 0);
    }
    TRY_TO(TraverseCXXRecordHelper(D));
    return true;
  }

  bool TraverseClassTemplatePartialSpecializationDecl(ClassTemplatePartialSpecializationDecl *D) {
    AddKApplyNode("PartialSpecialization", 3);
    /* The partial specialization. */
    int i = 0;
    TemplateParameterList *TPL = D->getTemplateParameters();
    for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end();
         I != E; ++I) {
      i++;
    }
    AddKSequenceNode(i);
    for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end();
         I != E; ++I) {
      TRY_TO(TraverseDecl(*I));
    }
    AddKSequenceNode(D->getTemplateArgsAsWritten()->NumTemplateArgs);
    /* The args that remains unspecialized. */
    TRY_TO(TraverseTemplateArgumentLocs(
        D->getTemplateArgsAsWritten()->getTemplateArgs(),
        D->getTemplateArgsAsWritten()->NumTemplateArgs));

    /* Don't need the *TemplatePartialSpecializationHelper, even
       though that's our parent class -- we already visit all the
       template args here. */
    TRY_TO(TraverseCXXRecordHelper(D));
    return true;
  }

  bool VisitAccessSpecDecl(AccessSpecDecl *D) {
    AddKApplyNode("AccessSpec", 1);
    VisitAccessSpecifier(D->getAccess());
    return false;
  }

  bool VisitStaticAssertDecl(StaticAssertDecl *D) {
    AddKApplyNode("StaticAssert", 2);
    return false;
  }

  bool VisitUsingDecl(UsingDecl *D) {
    AddKApplyNode("UsingDecl", 3);
    VisitBool(D->hasTypename());
    return false;
  }

  bool VisitUnresolvedUsingValueDecl(UnresolvedUsingValueDecl *D) {
    AddKApplyNode("UsingDecl", 3);
    VisitBool(false);
    return false;
  }

  bool VisitUsingDirectiveDecl(UsingDirectiveDecl *D) {
    AddKApplyNode("UsingDirective", 2);
    TRY_TO(TraverseDeclarationName(D->getNominatedNamespaceAsWritten()->getDeclName()));
    return false;
  }

  bool TraverseFunctionProtoType(FunctionProtoType *T) {
    AddKApplyNode("FunctionPrototype", 4);

    TRY_TO(TraverseType(T->getReturnType()));

    AddKApplyNode("list", 1);
    AddKSequenceNode(T->getNumParams());
    for(unsigned i = 0; i < T->getNumParams(); i++) {
      TRY_TO(TraverseType(T->getParamType(i)));
    }

    switch(T->getExceptionSpecType()) {
    case EST_None:
      AddKApplyNode("NoExceptionSpec", 0);
      break;
    case EST_BasicNoexcept:
      AddKApplyNode("NoexceptSpec", 1);
      AddKApplyNode("NoExpression", 0);
      break;
    case EST_ComputedNoexcept:
      AddKApplyNode("NoexceptSpec", 1);
      TRY_TO(TraverseStmt(T->getNoexceptExpr()));
      break;
    case EST_DynamicNone:
      AddKApplyNode("ThrowSpec", 1);
      AddKApplyNode("list", 1);
      AddKSequenceNode(0);
      break;
    case EST_Dynamic:
      AddKApplyNode("ThrowSpec", 1);
      AddKApplyNode("list", 1);
      AddKSequenceNode(T->getNumExceptions());
      for(unsigned i = 0; i < T->getNumExceptions(); i++) {
        TRY_TO(TraverseType(T->getExceptionType(i)));
      }
      break;
    default:
      doThrow("unimplemented: exception spec");
    }

    VisitBool(T->isVariadic());
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
      case BuiltinType::WChar_S:
      case BuiltinType::WChar_U:
        AddKApplyNode("WChar", 0);
        break;
      case BuiltinType::Char16:
        AddKApplyNode("Char16", 0);
        break;
      case BuiltinType::Char32:
        AddKApplyNode("Char32", 0);
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
        AddKApplyNode("OversizedInt", 0);
        break;
      case BuiltinType::UInt128:
        AddKApplyNode("OversizedUInt", 0);
        break;
      case BuiltinType::Dependent:
        AddKApplyNode("Dependent", 0);
        break;
      case BuiltinType::NullPtr:
        AddKApplyNode("NullPtr", 0);
        break;
      default:
        doThrow("unimplemented: basic type");
    }
    return false;
  }

  bool VisitPointerType(clang::PointerType *T) {
    AddKApplyNode("PointerType", 1);
    return false;
  }

  bool VisitMemberPointerType(MemberPointerType *T) {
    AddKApplyNode("MemberPointerType", 2);
    return false;
  }

  bool TraverseArrayHelper(clang::ArrayType *T) {
    if (T->getSizeModifier() != clang::ArrayType::Normal) {
      doThrow("unimplemented: static/* array");
    }
    AddKApplyNode("ArrayType", 2);
    TRY_TO(TraverseType(T->getElementType()));
    return true;
  }

  bool TraverseConstantArrayType(ConstantArrayType *T) {
    TRY_TO(TraverseArrayHelper(T));
    VisitAPInt(T->getSize());
    return true;
  }

  bool TraverseDependentSizedArrayType(DependentSizedArrayType *T) {
    TRY_TO(TraverseArrayHelper(T));
    TRY_TO(TraverseStmt(T->getSizeExpr()));
    return true;
  }

  bool TraverseVariableArrayType(VariableArrayType *T) {
    TRY_TO(TraverseArrayHelper(T));
    TRY_TO(TraverseStmt(T->getSizeExpr()));
    return true;
  }

  bool TraverseIncompleteArrayType(IncompleteArrayType *T) {
    TRY_TO(TraverseArrayHelper(T));
    AddKApplyNode("NoExpression", 0);
    return true;
  }

  bool VisitTypedefType(TypedefType *T) {
    AddKApplyNode("TypedefType", 1);
    TRY_TO(TraverseDeclarationName(T->getDecl()->getDeclName()));
    return false;
  }

  void VisitTypeKeyword(ElaboratedTypeKeyword Keyword) {
    switch(Keyword) {
    case ETK_Struct:
      AddKApplyNode("Struct", 0);
      break;
    case ETK_Union:
      AddKApplyNode("Union", 0);
      break;
    case ETK_Class:
      AddKApplyNode("Class", 0);
      break;
    case ETK_Enum:
      AddKApplyNode("Enum", 0);
      break;
    case ETK_Typename:
      AddKApplyNode("Typename", 0);
      break;
    case ETK_None:
      AddKApplyNode("NoTag", 0);
      break;
    default:
      doThrow("unimplemented: type keyword");
    }
  }

  bool VisitElaboratedType(ElaboratedType *T) {
    AddKApplyNode("QualifiedTypeName", 3);
    VisitTypeKeyword(T->getKeyword());
    if(!T->getQualifier()) {
      AddKApplyNode("NoNNS", 0);
    }
    return false;
  }

  bool VisitDecltypeType(DecltypeType *T) {
    AddKApplyNode("Decltype", 1);
    return false;
  }

  bool VisitTemplateTypeParmType(TemplateTypeParmType *T) {
    AddKApplyNode("TemplateParameterType", 1);
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool TraverseSubstTemplateTypeParmType(SubstTemplateTypeParmType *T) {
    TRY_TO(TraverseType(T->getReplacementType()));
    return true;
  }

  bool VisitTagType(TagType *T) {
    TagDecl *D = T->getDecl();
    AddKApplyNode("Name", 2);
    AddKApplyNode("NoNNS", 0);
    TRY_TO(TraverseDeclarationAsName(D));
    return false;
  }

  bool VisitLValueReferenceType(LValueReferenceType *T) {
    AddKApplyNode("LValRefType", 1);
    return false;
  }

  bool VisitRValueReferenceType(RValueReferenceType *T) {
    AddKApplyNode("RValRefType", 1);
    return false;
  }

  bool TraverseInjectedClassNameType(InjectedClassNameType *T) {
    TRY_TO(TraverseType(T->getInjectedSpecializationType()));
    return true;
  }

  bool TraverseDependentTemplateSpecializationType(DependentTemplateSpecializationType *T) {
    AddKApplyNode("TemplateSpecializationType", 2);
    AddKApplyNode("Name", 2);
    TRY_TO(TraverseNestedNameSpecifier(T->getQualifier()));
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    AddKSequenceNode(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool TraverseTemplateSpecializationType(const TemplateSpecializationType *T) {
    AddKApplyNode("TemplateSpecializationType", 2);
    TRY_TO(TraverseTemplateName(T->getTemplateName()));
    AddKSequenceNode(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool VisitDependentNameType(DependentNameType *T) {
    AddKApplyNode("ElaboratedTypeSpecifier", 3);
    VisitTypeKeyword(T->getKeyword());
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool VisitPackExpansionType(PackExpansionType *T) {
    AddKApplyNode("PackExpansionType", 1);
    return false;
  }

  bool TraverseAutoType(AutoType *T) {
    if (T->isDeduced()) {
      TRY_TO(TraverseType(T->getDeducedType()));
    } else {
      AddKApplyNode("AutoType", 1);
      VisitBool(T->isDecltypeAuto());
    }
    return true;
  }

  bool VisitParenType(ParenType *T) {
    return false; // no node created
  }

  bool VisitDecayedType(DecayedType *T) {
    return false; // no node created
  }

  bool VisitTypeOfExprType(TypeOfExprType *T) {
    AddKApplyNode("TypeofExpression", 1);
    return false;
  }

  bool VisitTypeOfType(TypeOfType *T) {
    AddKApplyNode("TypeofType", 1);
    return false;
  }

  bool VisitUnaryTransformType(UnaryTransformType *T) {
    if (T->isSugared()) {
      AddKApplyNode("GnuEnumUnderlyingType2", 2);
    } else {
      AddKApplyNode("GnuEnumUnderlyingType1", 1);
    }
    return false;
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
    return RecursiveASTVisitor::TraverseType(T);
  }

  bool VisitDeclStmt(DeclStmt *S) {
    AddKApplyNode("DeclStmt", 1);
    int i = 0;
    for (auto *I : S->decls()) {
      i++;
    }
    AddKSequenceNode(i);
    return false;
  }

  bool VisitBreakStmt(BreakStmt *S) {
    AddKApplyNode("TBreakStmt", 0);
    return false;
  }

  bool VisitContinueStmt(ContinueStmt *S) {
    AddKApplyNode("ContinueStmt", 0);
    return false;
  }

  bool VisitGotoStmt(GotoStmt *S) {
    AddKApplyNode("GotoStmt", 1);
    TRY_TO(TraverseDeclarationName(S->getLabel()->getDeclName()));
    return false;
  }

  bool VisitReturnStmt(ReturnStmt *S) {
    AddKApplyNode("ReturnStmt", 1);
    if (!S->getRetValue()) {
      AddKApplyNode("NoInit", 0);
    }
    return false;
  }

  bool VisitNullStmt(NullStmt *S) {
    AddKApplyNode("NullStmt", 0);
    return false;
  }

  bool VisitCompoundStmt(CompoundStmt *S) {
    AddKApplyNode("CompoundAStmt", 1);
    AddStmtChildrenNode(S);
    return false;
  }

  bool VisitLabelStmt(LabelStmt *S) {
    AddKApplyNode("LabelAStmt", 2);
    TRY_TO(TraverseDeclarationName(S->getDecl()->getDeclName()));
    AddStmtChildrenNode(S);
    return false;
  }

  bool TraverseForStmt(ForStmt *S) {
    AddKApplyNode("ForAStmt", 4);
    if (S->getInit()) {
      TRY_TO(TraverseStmt(S->getInit()));
    } else {
      AddKApplyNode("NoStatement", 0);
    }
    if (S->getCond()) {
      TRY_TO(TraverseStmt(S->getCond()));
    } else {
      AddKApplyNode("NoExpression", 0);
    }
    if (S->getInc()) {
      TRY_TO(TraverseStmt(S->getInc()));
    } else {
      AddKApplyNode("NoExpression", 0);
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseWhileStmt(WhileStmt *S) {
    AddKApplyNode("WhileAStmt", 2);
    if (S->getConditionVariable()) {
      TRY_TO(TraverseDecl(S->getConditionVariable()));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool VisitDoStmt(DoStmt *S) {
    AddKApplyNode("DoWhileAStmt", 2);
    return false;
  }

  bool TraverseIfStmt(IfStmt *S) {
    AddKApplyNode("IfAStmt", 3);
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getThen()));
    if(Stmt *Else = S->getElse()) {
      TRY_TO(TraverseStmt(Else));
    } else {
      AddKApplyNode("NoStatement", 0);
    }
    return true;
  }

  bool TraverseSwitchStmt(SwitchStmt *S) {
    AddKApplyNode("SwitchAStmt", 2);
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseCaseStmt(CaseStmt *S) {
    AddKApplyNode("CaseAStmt", 2);
    if (S->getRHS()) {
      doThrow("unimplemented: gnu case stmt extensions");
    }
    TRY_TO(TraverseStmt(S->getLHS()));
    TRY_TO(TraverseStmt(S->getSubStmt()));
    return true;
  }

  bool VisitDefaultStmt(DefaultStmt *S) {
    AddKApplyNode("DefaultAStmt", 1);
    return false;
  }

  bool TraverseCXXTryStmt(CXXTryStmt *S) {
    AddKApplyNode("TryAStmt", 2);
    TRY_TO(TraverseStmt(S->getTryBlock()));
    AddKSequenceNode(S->getNumHandlers());
    for (unsigned i = 0; i < S->getNumHandlers(); i++) {
      TRY_TO(TraverseStmt(S->getHandler(i)));
    }
    return true;
  }

  bool VisitCXXCatchStmt(CXXCatchStmt *S) {
    AddKApplyNode("CatchAStmt", 2);
    if (!S->getExceptionDecl()) {
      AddKApplyNode("Ellipsis", 0);
    }
    return false;
  }

  template<typename ExprType>
  bool TraverseMemberHelper(ExprType *E) {
    if (E->isImplicitAccess()) {
      AddKApplyNode("Name", 2);
      TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
      TRY_TO(TraverseDeclarationNameInfo(E->getMemberNameInfo()));
    } else {
      AddKApplyNode("MemberExpr", 4);
      VisitBool(E->isArrow());
      VisitBool(E->hasTemplateKeyword());
      AddKApplyNode("Name", 2);
      TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
      TRY_TO(TraverseDeclarationNameInfo(E->getMemberNameInfo()));
      TRY_TO(TraverseStmt(E->getBase()));
    }
    return true;
  }

  bool TraverseUnresolvedMemberExpr(UnresolvedMemberExpr *E) {
    return TraverseMemberHelper(E);
  }

  bool TraverseCXXDependentScopeMemberExpr(CXXDependentScopeMemberExpr *E) {
    return TraverseMemberHelper(E);
  }

  bool TraverseMemberExpr(MemberExpr *E) {
    return TraverseMemberHelper(E);
  }

  bool VisitArraySubscriptExpr(ArraySubscriptExpr *E) {
    AddKApplyNode("Subscript", 2);
    return false;
  }

  bool TraverseCXXMemberCallExpr(CXXMemberCallExpr *E) {
    return TraverseCallExpr(E);
  }

  bool TraverseCallExpr(CallExpr *E) {
    AddKApplyNode("CallExpr", 3);
    unsigned i = 0;
    for (Stmt *SubStmt : E->children()) {
      i++;
    }
    if (i-1 != E->getNumArgs()) {
      doThrow("unimplemented: pre_args???");
    }
    bool first = true;
    for (Stmt *SubStmt : E->children()) {
      TRY_TO(TraverseStmt(SubStmt));
      if (first) {
        AddKApplyNode("list", 1);
        AddKSequenceNode(i-1);
      }
      first = false;
    }
    AddKApplyNode("krlist", 1);
    AddKApplyNode(".List", 0);
    return true;
  }

  bool VisitImplicitCastExpr(ImplicitCastExpr *E) {
    return false; // no node created
  }

  bool VisitParenExpr(ParenExpr *E) {
    return false; // no node created
  }

  bool VisitExprWithCleanups(ExprWithCleanups *E) {
    return false; // no node created
  }

  bool VisitCXXBindTemporaryExpr(CXXBindTemporaryExpr *E) {
    return false; // no node created
  }

  bool VisitSubstNonTypeTemplateParmExpr(SubstNonTypeTemplateParmExpr *E) {
    return false; // no node created
  }

  bool VisitDeclRefExpr(DeclRefExpr *E) {
    AddKApplyNode("Name", 2);
    return false;
  }

  bool VisitDependentScopeDeclRefExpr(DependentScopeDeclRefExpr *E) {
    AddKApplyNode("Name", 2);
    return false;
  }

  bool TraverseUnresolvedLookupExpr(UnresolvedLookupExpr *E) {
    AddKApplyNode("Name", 2);
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(E->getNameInfo()));
    return true;
  }

  void VisitOperator(OverloadedOperatorKind Kind) {
    switch(Kind) {
    #define OVERLOADED_OPERATOR(Name,Spelling,Token,Unary,Binary,MemberOnly) \
    case OO_##Name:                                                          \
      AddKApplyNode("operator" Spelling "_CPP-SYNTAX", 0);                                 \
      break;
    #include "clang/Basic/OperatorKinds.def"
    default:
      doThrow("unsupported overloaded operator");
    }
  }

  void VisitOperator(UnaryOperatorKind Kind) {
    switch(Kind) {
    #define UNARY_OP(Name, Spelling)         \
    case UO_##Name:                          \
      AddKApplyNode("operator" Spelling "_CPP-SYNTAX", 0); \
      break;
    UNARY_OP(PostInc, "_++")
    UNARY_OP(PostDec, "_--")
    UNARY_OP(PreInc, "++_")
    UNARY_OP(PreDec, "--_")
    UNARY_OP(AddrOf, "&")
    UNARY_OP(Deref, "*")
    UNARY_OP(Plus, "+")
    UNARY_OP(Minus, "-")
    UNARY_OP(Not, "~")
    UNARY_OP(LNot, "!")
    case UO_Real:
      AddKApplyNode("RealOperator", 0);
      break;
    case UO_Imag:
      AddKApplyNode("ImagOperator", 0);
      break;
    case UO_Extension:
      AddKApplyNode("ExtensionOperator", 0);
      break;
    case UO_Coawait:
      AddKApplyNode("CoawaitOperator", 0);
      break;
    default:
      doThrow("unsupported unary operator");
    }
  }

  void VisitOperator(BinaryOperatorKind Kind) {
    switch(Kind) {
    #define BINARY_OP(Name, Spelling)        \
    case BO_##Name:                          \
      AddKApplyNode("operator" Spelling "_CPP-SYNTAX", 0); \
      break;
    BINARY_OP(PtrMemD, ".*")
    BINARY_OP(PtrMemI, "->*")
    BINARY_OP(Mul, "*")
    BINARY_OP(Div, "/")
    BINARY_OP(Rem, "%")
    BINARY_OP(Add, "+")
    BINARY_OP(Sub, "-")
    BINARY_OP(Shl, "<<")
    BINARY_OP(Shr, ">>")
    BINARY_OP(LT, "<")
    BINARY_OP(GT, ">")
    BINARY_OP(LE, "<=")
    BINARY_OP(GE, ">=")
    BINARY_OP(EQ, "==")
    BINARY_OP(NE, "!=")
    BINARY_OP(And, "&")
    BINARY_OP(Xor, "^")
    BINARY_OP(Or, "|")
    BINARY_OP(LAnd, "&&")
    BINARY_OP(LOr, "||")
    BINARY_OP(Assign, "=")
    BINARY_OP(MulAssign, "*=")
    BINARY_OP(DivAssign, "/=")
    BINARY_OP(RemAssign, "%=")
    BINARY_OP(AddAssign, "+=")
    BINARY_OP(SubAssign, "-=")
    BINARY_OP(ShlAssign, "<<=")
    BINARY_OP(ShrAssign, ">>=")
    BINARY_OP(AndAssign, "&=")
    BINARY_OP(XorAssign, "^=")
    BINARY_OP(OrAssign, "|=")
    BINARY_OP(Comma, ",")
    default:
      doThrow("unsupported binary operator");
    }
  }

  bool VisitUnaryOperator(UnaryOperator *E) {
    AddKApplyNode("UnaryOperator", 2);
    VisitOperator(E->getOpcode());
    return false;
  }


  bool VisitBinaryOperator(BinaryOperator *E) {
    AddKApplyNode("BinaryOperator", 3);
    VisitOperator(E->getOpcode());
    return false;
  }

  bool VisitConditionalOperator(ConditionalOperator *E) {
    AddKApplyNode("ConditionalOperator", 3);
    return false;
  }

  bool TraverseCXXOperatorCallExpr(CXXOperatorCallExpr *E) {
    switch(E->getOperator()) {
    case OO_Call:
        // TODO(chathhorn)
        AddKApplyNode("OverloadedCall", 0);
        break;
    case OO_New:
    case OO_Delete:
    case OO_Array_New:
    case OO_Array_Delete:
    case OO_Plus:
    case OO_Minus:
    case OO_Star:
    case OO_Amp:
      if (E->getNumArgs() == 2) {
        AddKApplyNode("BinaryOperator", 3);
        VisitOperator(E->getOperator());
        TRY_TO(TraverseStmt(E->getArg(0)));
        TRY_TO(TraverseStmt(E->getArg(1)));
        break;
      } else if (E->getNumArgs() == 1) {
        AddKApplyNode("UnaryOperator", 2);
        VisitOperator(E->getOperator());
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      } else {
        doThrow("unexpected number of arguments to operator");
      }
    case OO_PlusPlus:
      if (E->getNumArgs() == 2) {
        AddKApplyNode("UnaryOperator", 2);
        VisitOperator(UO_PostInc);
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      } else if (E->getNumArgs() == 1) {
        AddKApplyNode("UnaryOperator", 2);
        VisitOperator(UO_PreInc);
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      } else {
        doThrow("unexpected number of arguments to operator");
      }
    case OO_MinusMinus:
      if (E->getNumArgs() == 2) {
        AddKApplyNode("UnaryOperator", 2);
        VisitOperator(UO_PostDec);
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      } else if (E->getNumArgs() == 1) {
        AddKApplyNode("UnaryOperator", 2);
        VisitOperator(UO_PreDec);
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      } else {
        doThrow("unexpected number of arguments to operator");
      }
    case OO_Slash:
    case OO_Percent:
    case OO_Caret:
    case OO_Pipe:
    case OO_Equal:
    case OO_Less:
    case OO_Greater:
    case OO_PlusEqual:
    case OO_MinusEqual:
    case OO_StarEqual:
    case OO_SlashEqual:
    case OO_PercentEqual:
    case OO_CaretEqual:
    case OO_AmpEqual:
    case OO_PipeEqual:
    case OO_LessLess:
    case OO_GreaterGreater:
    case OO_LessLessEqual:
    case OO_GreaterGreaterEqual:
    case OO_EqualEqual:
    case OO_ExclaimEqual:
    case OO_LessEqual:
    case OO_GreaterEqual:
    case OO_AmpAmp:
    case OO_PipePipe:
    case OO_Comma:
    case OO_ArrowStar:
    case OO_Subscript:
      if (E->getNumArgs() != 2) {
        doThrow("unexpected number of arguments to operator");
      }
      AddKApplyNode("BinaryOperator", 3);
      VisitOperator(E->getOperator());
      TRY_TO(TraverseStmt(E->getArg(0)));
      TRY_TO(TraverseStmt(E->getArg(1)));
      break;
    case OO_Tilde:
    case OO_Exclaim:
    case OO_Coawait:
      if (E->getNumArgs() != 1) {
        doThrow("unexpected number of arguments to operator");
      }
      AddKApplyNode("UnaryOperator", 2);
      VisitOperator(E->getOperator());
      TRY_TO(TraverseStmt(E->getArg(0)));
      break;
    default:
      doThrow("unimplemented: overloaded operator");
    }
    return true;
  }

  bool VisitCStyleCastExpr(CStyleCastExpr *E) {
    AddKApplyNode("ParenthesizedCast", 2);
    return false;
  }

  bool VisitCXXReinterpretCastExpr(CXXReinterpretCastExpr *E) {
    AddKApplyNode("ReinterpretCast", 2);
    return false;
  }

  bool VisitCXXStaticCastExpr(CXXStaticCastExpr *E) {
    AddKApplyNode("StaticCast", 2);
    return false;
  }

  bool VisitCXXDynamicCastExpr(CXXDynamicCastExpr *E) {
    AddKApplyNode("DynamicCast", 2);
    return false;
  }

  bool VisitCXXConstCastExpr(CXXConstCastExpr *E) {
    AddKApplyNode("ConstCast", 2);
    return false;
  }

  bool TraverseCXXConstructHelper(QualType T, Expr **begin, Expr **end) {
    TRY_TO(TraverseType(T));
    int i = 0;
    for (Expr **iter = begin; iter != end; ++iter) {
      i++;
    }
    AddKSequenceNode(i);
    for (Expr **iter = begin; iter != end; ++iter) {
      TRY_TO(TraverseStmt(*iter));
    }
    return true;
  }

  bool TraverseCXXUnresolvedConstructExpr(CXXUnresolvedConstructExpr *E) {
    AddKApplyNode("UnresolvedConstructorCall", 2);
    return TraverseCXXConstructHelper(E->getTypeAsWritten(), E->arg_begin(), E->arg_end());
  }

  bool TraverseCXXFunctionalCastExpr(CXXFunctionalCastExpr *E) {
    Expr *arg = E->getSubExprAsWritten();
    AddKApplyNode("FunctionalCast", 2);
    return TraverseCXXConstructHelper(E->getTypeInfoAsWritten()->getType(), &arg, &arg+1);
  }

  bool TraverseCXXScalarValueInitExpr(CXXScalarValueInitExpr *E) {
    AddKApplyNode("FunctionalCast", 2);
    return TraverseCXXConstructHelper(E->getType(), 0, 0);
  }

  bool TraverseCXXConstructExpr(CXXConstructExpr *E) {
    AddKApplyNode("ConstructorCall", 3);
    VisitBool(E->requiresZeroInitialization());
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool TraverseCXXTemporaryObjectExpr(CXXTemporaryObjectExpr *E) {
    AddKApplyNode("TemporaryObjectExpr", 2);
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool VisitUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *E) {
    if (E->getKind() == UETT_SizeOf) {
      if (E->isArgumentType()) {
        AddKApplyNode("SizeofType", 1);
      } else {
        AddKApplyNode("SizeofExpr", 1);
      }
    } else if (E->getKind() == UETT_AlignOf) {
      if (E->isArgumentType()) {
        AddKApplyNode("AlignofType", 1);
      } else {
        AddKApplyNode("AlignofExpr", 1);
      }
    } else {
      doThrow("unimplemented: ??? expr or type trait");
    }
    return false;
  }

  bool VisitSizeOfPackExpr(SizeOfPackExpr *E) {
    AddKApplyNode("SizeofPack", 1);
    TRY_TO(TraverseDeclarationName(E->getPack()->getDeclName()));
    return false;
  }

  bool TraverseCXXPseudoDestructorExpr(CXXPseudoDestructorExpr *E) {
    AddKApplyNode("PseudoDestructor", 5);
    TRY_TO(TraverseStmt(E->getBase()));
    VisitBool(E->isArrow());
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    if (TypeSourceInfo *ScopeInfo = E->getScopeTypeInfo()) {
      TRY_TO(TraverseTypeLoc(ScopeInfo->getTypeLoc()));
    } else {
      AddKApplyNode("NoType", 0);
    }
    if (TypeSourceInfo *DestroyedTypeInfo = E->getDestroyedTypeInfo()) {
      TRY_TO(TraverseTypeLoc(DestroyedTypeInfo->getTypeLoc()));
    } else {
      AddKApplyNode("NoType", 0);
    }
    return true;
  }

  bool VisitCXXNoexceptExpr(CXXNoexceptExpr *E) {
    AddKApplyNode("Noexcept", 1);
    return false;
  }

  bool TraverseCXXNewExpr(CXXNewExpr *E) {
    AddKApplyNode("NewExpr", 5);
    VisitBool(E->isGlobalNew());
    TRY_TO(TraverseType(E->getAllocatedType()));
    if (E->isArray()) {
      TRY_TO(TraverseStmt(E->getArraySize()));
    } else {
      AddKApplyNode("NoExpression", 0);
    }
    if (E->hasInitializer()) {
      TRY_TO(TraverseStmt(E->getInitializer()));
    } else {
      AddKApplyNode("NoInit", 0);
    }
    AddKSequenceNode(E->getNumPlacementArgs());
    for (unsigned i = 0; i < E->getNumPlacementArgs(); i++) {
      TRY_TO(TraverseStmt(E->getPlacementArg(i)));
    }
    return true;
  }

  bool VisitCXXDeleteExpr(CXXDeleteExpr *E) {
    AddKApplyNode("DeleteExpr", 3);
    VisitBool(E->isGlobalDelete());
    VisitBool(E->isArrayFormAsWritten());
    return false;
  }

  bool VisitCXXThisExpr(CXXThisExpr *E) {
    AddKApplyNode("This", 0);
    return false;
  }

  bool VisitCXXThrowExpr(CXXThrowExpr *E) {
    AddKApplyNode("Throw", 1);
    if (!E->getSubExpr()) {
      AddKApplyNode("NoExpression", 0);
    }
    return false;
  }

  bool TraverseLambdaCapture(LambdaExpr *E, const LambdaCapture *C, Expr*) {
    AddKApplyNode("LambdaCapture", 2);
    switch(C->getCaptureKind()) {
    case LCK_This:
      AddKApplyNode("This", 0);
      break;
    case LCK_ByRef:
      AddKApplyNode("RefCapture", 1);
      // fall through
    case LCK_ByCopy:
      break;
    default:
      doThrow("unimplemented: capture kind");
    }
    if(C->capturesVariable()) {
      TRY_TO(TraverseDecl(C->getCapturedVar()));
    }
    VisitBool(C->isPackExpansion());
    return true;
  }

  bool TraverseLambdaExpr(LambdaExpr *E) {
    AddKApplyNode("Lambda", 4);
    switch(E->getCaptureDefault()) {
    case LCD_None:
      AddKApplyNode("NoCaptureDefault", 0);
      break;
    case LCD_ByCopy:
      AddKApplyNode("CopyCapture", 0);
      break;
    case LCD_ByRef:
      AddKApplyNode("RefCapture", 0);
      break;
    }
    int i = 0;
    for (LambdaExpr::capture_iterator C = E->explicit_capture_begin(),
                                      CEnd = E->explicit_capture_end();
         C != CEnd; ++C) {
      if(C->isExplicit()) {
        i++;
      }
    }
    AddKSequenceNode(i);
    for (unsigned I = 0, N = E->capture_size(); I != N; ++I) {
      const LambdaCapture *C = E->capture_begin() + I;
      if (C->isExplicit()) {
        TRY_TO(TraverseLambdaCapture(E, C, E->capture_init_begin()[I]));
      }
    }

    QualType T = E->getCallOperator()->getType();
    TRY_TO(TraverseType(T));
    TRY_TO(TraverseStmt(E->getBody()));

    return true;
  }

  bool VisitPackExpansionExpr(PackExpansionExpr *E) {
    AddKApplyNode("PackExpansionExpr", 1);
    return false;
  }

  void VisitStringRef(StringRef str) {
    const char *res = escape(str.begin(), (str.end() - str.begin()));
    AddKTokenNode(res, "String");
  }

  void VisitAPInt(llvm::APInt i) {
    std::string *name = new std::string(i.toString(10, false));
    AddKTokenNode(name->c_str(), "Int");
  }

  void VisitUnsigned(unsigned long long s) {
    char *name = new char[21];
    sprintf(name, "%llu", s);
    AddKTokenNode(name, "Int");
  }


  void VisitAPFloat(llvm::APFloat f) {
    if (!f.isFinite()) {
      doThrow("unimplemented: special floats");
    }
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
    AddKTokenNode(result, "Float");
  }

  bool VisitStringLiteral(StringLiteral *Constant) {
    AddKApplyNode("StringLiteral", 2);
    switch(Constant->getKind()) {
    case StringLiteral::Ascii:
      AddKApplyNode("Ascii", 0);
      break;
    case StringLiteral::Wide:
      AddKApplyNode("Wide", 0);
      break;
    case StringLiteral::UTF8:
      AddKApplyNode("UTF8", 0);
      break;
    case StringLiteral::UTF16:
      AddKApplyNode("UTF16", 0);
      break;
    case StringLiteral::UTF32:
      AddKApplyNode("UTF32", 0);
      break;
    }
    StringRef str = Constant->getBytes();
    VisitStringRef(str);
    return false;
  }

  bool VisitCharacterLiteral(CharacterLiteral *Constant) {
    AddKApplyNode("CharacterLiteral", 2);
    switch(Constant->getKind()) {
    case CharacterLiteral::Ascii:
      AddKApplyNode("Ascii", 0);
      break;
    case CharacterLiteral::Wide:
      AddKApplyNode("Wide", 0);
      break;
    case CharacterLiteral::UTF8:
      AddKApplyNode("UTF8", 0);
      break;
    case CharacterLiteral::UTF16:
      AddKApplyNode("UTF16", 0);
      break;
    case CharacterLiteral::UTF32:
      AddKApplyNode("UTF32", 0);
      break;
    }
    char *buf = new char[11];
    sprintf(buf, "%d", Constant->getValue());
    AddKTokenNode(buf, "Int");
    return false;
  }

  bool TraverseIntegerLiteral(IntegerLiteral *Constant) {
    AddKApplyNode("IntegerLiteral", 2);
    VisitAPInt(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool TraverseFloatingLiteral(FloatingLiteral *Constant) {
    AddKApplyNode("FloatingLiteral", 2);
    VisitAPFloat(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool VisitCXXNullPtrLiteralExpr(CXXNullPtrLiteralExpr *Constant) {
    AddKApplyNode("NullPointerLiteral", 0);
    return false;
  }

  bool VisitCXXBoolLiteralExpr(CXXBoolLiteralExpr *Constant) {
    AddKApplyNode("BoolLiteral", 1);
    VisitBool(Constant->getValue());
    return false;
  }

  bool TraverseInitListExpr(InitListExpr *E) {
    InitListExpr *Syntactic = E->isSemanticForm() ? E->getSyntacticForm() ? E->getSyntacticForm() : E : E;
    AddKApplyNode("BraceInit", 1);
    AddKSequenceNode(Syntactic->getNumInits());
    for (Stmt *SubStmt : Syntactic->children()) {
      TRY_TO(TraverseStmt(SubStmt));
    }
    return true;
  }

  bool VisitImplicitValueInitExpr(ImplicitValueInitExpr *E) {
    AddKApplyNode("ExpressionList", 1);
    AddKSequenceNode(0);
    return false;
  }

  bool VisitTypeTraitExpr(TypeTraitExpr *E) {
    AddKApplyNode("GnuTypeTrait", 2);
    switch(E->getTrait()) {
    #define TRAIT(Name, Str)                  \
    case Name:                                \
      AddKTokenNode("\"" Str "\"", "String"); \
      break;
    TRAIT(UTT_HasNothrowAssign, "HasNothrowAssign")
    TRAIT(UTT_HasNothrowMoveAssign, "HasNothrowMoveAssign")
    TRAIT(UTT_HasNothrowCopy, "HasNothrowCopy")
    TRAIT(UTT_HasNothrowConstructor, "HasNothrowConstructor")
    TRAIT(UTT_HasTrivialAssign, "HasTrivialAssign")
    TRAIT(UTT_HasTrivialMoveAssign, "HasTrivialMoveAssign")
    TRAIT(UTT_HasTrivialCopy, "HasTrivialCopy")
    TRAIT(UTT_HasTrivialDefaultConstructor, "HasTrivialDefaultConstructor")
    TRAIT(UTT_HasTrivialMoveConstructor, "HasTrivialMoveConstructor")
    TRAIT(UTT_HasTrivialDestructor, "HasTrivialDestructor")
    TRAIT(UTT_HasVirtualDestructor, "HasVirtualDestructor")
    TRAIT(UTT_IsAbstract, "IsAbstract")
    TRAIT(UTT_IsArithmetic, "IsArithmetic")
    TRAIT(UTT_IsArray, "IsArray")
    TRAIT(UTT_IsClass, "IsClass")
    TRAIT(UTT_IsCompleteType, "IsCompleteType")
    TRAIT(UTT_IsCompound, "IsCompound")
    TRAIT(UTT_IsConst, "IsConst")
    TRAIT(UTT_IsDestructible, "IsDestructible")
    TRAIT(UTT_IsEmpty, "IsEmpty")
    TRAIT(UTT_IsEnum, "IsEnum")
    TRAIT(UTT_IsFinal, "IsFinal")
    TRAIT(UTT_IsFloatingPoint, "IsFloatingPoint")
    TRAIT(UTT_IsFunction, "IsFunction")
    TRAIT(UTT_IsFundamental, "IsFundamental")
    TRAIT(UTT_IsIntegral, "IsIntegral")
    TRAIT(UTT_IsInterfaceClass, "IsInterfaceClass")
    TRAIT(UTT_IsLiteral, "IsLiteral")
    TRAIT(UTT_IsLvalueReference, "IsLvalueReference")
    TRAIT(UTT_IsMemberFunctionPointer, "IsMemberFunctionPointer")
    TRAIT(UTT_IsMemberObjectPointer, "IsMemberObjectPointer")
    TRAIT(UTT_IsMemberPointer, "IsMemberPointer")
    TRAIT(UTT_IsNothrowDestructible, "IsNothrowDestructible")
    TRAIT(UTT_IsObject, "IsObject")
    TRAIT(UTT_IsPOD, "IsPOD")
    TRAIT(UTT_IsPointer, "IsPointer")
    TRAIT(UTT_IsPolymorphic, "IsPolymorphic")
    TRAIT(UTT_IsReference, "IsReference")
    TRAIT(UTT_IsRvalueReference, "IsRvalueReference")
    TRAIT(UTT_IsScalar, "IsScalar")
    TRAIT(UTT_IsSealed, "IsSealed")
    TRAIT(UTT_IsSigned, "IsSigned")
    TRAIT(UTT_IsStandardLayout, "IsStandardLayout")
    TRAIT(UTT_IsTrivial, "IsTrivial")
    TRAIT(UTT_IsTriviallyCopyable, "IsTriviallyCopyable")
    TRAIT(UTT_IsUnion, "IsUnion")
    TRAIT(UTT_IsUnsigned, "IsUnsigned")
    TRAIT(UTT_IsVoid, "IsVoid")
    TRAIT(UTT_IsVolatile, "IsVolatile")
    TRAIT(BTT_IsBaseOf, "IsBaseOf")
    TRAIT(BTT_IsConvertible, "IsConvertible")
    TRAIT(BTT_IsConvertibleTo, "IsConvertibleTo")
    TRAIT(BTT_IsSame, "IsSame")
    TRAIT(BTT_TypeCompatible, "TypeCompatible")
    TRAIT(BTT_IsAssignable, "IsAssignable")
    TRAIT(BTT_IsNothrowAssignable, "IsNothrowAssignable")
    TRAIT(BTT_IsTriviallyAssignable, "IsTriviallyAssignable")
    TRAIT(TT_IsConstructible, "IsConstructible")
    TRAIT(TT_IsNothrowConstructible, "IsNothrowConstructible")
    TRAIT(TT_IsTriviallyConstructible, "IsTriviallyConstructible")
    }
    AddKSequenceNode(E->getNumArgs());
    return false;
  }

  bool VisitAtomicExpr(AtomicExpr *E) {
    AddKApplyNode("GnuAtomicExpr", 2);
    switch(E->getOp()) {
			#define ATOMIC_BUILTIN(Name, Spelling)           \
				case AtomicExpr::AO##Name:                     \
					AddKTokenNode("\"" Spelling "\"", "String"); \
					break;
      ATOMIC_BUILTIN(__c11_atomic_init, "__c11_atomic_init")
      ATOMIC_BUILTIN(__c11_atomic_load, "__c11_atomic_load")
      ATOMIC_BUILTIN(__c11_atomic_store, "__c11_atomic_store")
      ATOMIC_BUILTIN(__c11_atomic_exchange, "__c11_atomic_exchange")
      ATOMIC_BUILTIN(__c11_atomic_compare_exchange_strong, "__c11_atomic_compare_exchange_strong")
      ATOMIC_BUILTIN(__c11_atomic_compare_exchange_weak, "__c11_atomic_compare_exchange_weak")
      ATOMIC_BUILTIN(__c11_atomic_fetch_add, "__c11_atomic_fetch_add")
      ATOMIC_BUILTIN(__c11_atomic_fetch_sub, "__c11_atomic_fetch_sub")
      ATOMIC_BUILTIN(__c11_atomic_fetch_and, "__c11_atomic_fetch_and")
      ATOMIC_BUILTIN(__c11_atomic_fetch_or, "__c11_atomic_fetch_or")
      ATOMIC_BUILTIN(__c11_atomic_fetch_xor, "__c11_atomic_fetch_xor")
      ATOMIC_BUILTIN(__atomic_load, "__atomic_load")
      ATOMIC_BUILTIN(__atomic_load_n, "__atomic_load_n")
      ATOMIC_BUILTIN(__atomic_store, "__atomic_store")
      ATOMIC_BUILTIN(__atomic_store_n, "__atomic_store_n")
      ATOMIC_BUILTIN(__atomic_exchange, "__atomic_exchange")
      ATOMIC_BUILTIN(__atomic_exchange_n, "__atomic_exchange_n")
      ATOMIC_BUILTIN(__atomic_compare_exchange, "__atomic_compare_exchange")
      ATOMIC_BUILTIN(__atomic_compare_exchange_n, "__atomic_compare_exchange_n")
      ATOMIC_BUILTIN(__atomic_fetch_add, "__atomic_fetch_add")
      ATOMIC_BUILTIN(__atomic_fetch_sub, "__atomic_fetch_sub")
      ATOMIC_BUILTIN(__atomic_fetch_and, "__atomic_fetch_and")
      ATOMIC_BUILTIN(__atomic_fetch_or, "__atomic_fetch_or")
      ATOMIC_BUILTIN(__atomic_fetch_xor, "__atomic_fetch_xor")
      ATOMIC_BUILTIN(__atomic_fetch_nand, "__atomic_fetch_nand")
      ATOMIC_BUILTIN(__atomic_add_fetch, "__atomic_add_fetch")
      ATOMIC_BUILTIN(__atomic_sub_fetch, "__atomic_sub_fetch")
      ATOMIC_BUILTIN(__atomic_and_fetch, "__atomic_and_fetch")
      ATOMIC_BUILTIN(__atomic_or_fetch, "__atomic_or_fetch")
      ATOMIC_BUILTIN(__atomic_xor_fetch, "__atomic_xor_fetch")
      ATOMIC_BUILTIN(__atomic_nand_fetch, "__atomic_nand_fetch")
			#undef ATOMIC_BUILTIN
      default: break;
    }
    AddKSequenceNode(E->getNumSubExprs());
    return false;
  }

  bool VisitPredefinedExpr(PredefinedExpr *E) {
    return false;
  }


  // the rest of these are not part of the syntax of C but we keep them and transform them later
  // in order to avoid having to deal with messy syntax transformations within the parser
  bool VisitMaterializeTemporaryExpr(MaterializeTemporaryExpr *E) {
    AddKApplyNode("MaterializeTemporaryExpr", 1);
    return false;
  }

  bool VisitParenListExpr(ParenListExpr *E) {
    AddKApplyNode("ParenList", 1);
    AddKSequenceNode(E->getNumExprs());
    return false;
  }

  bool VisitCXXDefaultArgExpr(CXXDefaultArgExpr *E) {
    AddKApplyNode("DefaultArg", 0);
    return false;
  }


private:
  ASTContext *Context;
  llvm::StringRef InFile;

  void mangledIdentifier(NamedDecl* D) {
    AddKApplyNode("Identifier", 1);
    auto mangler = Context->createMangleContext();
    std::string mangledName;
    llvm::raw_string_ostream s(mangledName);
    if (D->hasLinkage()) {
		if (CXXConstructorDecl *CtorDecl = dyn_cast<CXXConstructorDecl>(D))
			mangler->mangleCXXCtor(CtorDecl, Ctor_Complete, s);
		else if (CXXDestructorDecl *DtorDecl = dyn_cast<CXXDestructorDecl>(D))
			mangler->mangleCXXDtor(DtorDecl, Dtor_Complete, s);
		else
			mangler->mangleName(D, s);
	}
    char *buf = new char[s.str().length() + 3];
    buf[0] = '\"';
    buf[s.str().length() + 1] = '\"';
    buf[s.str().length() + 2] = 0;
    memcpy(buf + 1, s.str().c_str(), s.str().length());
    AddKTokenNode(buf, "String");
  }
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
  if (!current) {
        doThrow("parse error");
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
  size_t n = 0;
  FILE *temp = fdopen(master, "r");
  do {
    if (buf) fprintf(stderr, "%s", buf);
    free(buf);
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

