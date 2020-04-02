#ifndef GETKASTVISITOR_H_
#define GETKASTVISITOR_H_

#include <unistd.h>

#include "clang/AST/ASTContext.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/RecursiveASTVisitor.h"

#include "ClangKast.h"

using namespace clang;
using namespace clang::tooling;

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

class GetKastVisitor
  : public RecursiveASTVisitor<GetKastVisitor> {

public:

  explicit GetKastVisitor(ASTContext *Context, const llvm::StringRef InFile)
    : Context(Context), InFile(InFile.str()) { }

  bool shouldVisitTemplateInstantiations() { return true; }

// if we reach all the way to the top of a hierarchy, crash with an error
// because we don't support the node

  bool VisitDecl(Decl *D) {
    D->dump();
    throw std::logic_error("unimplemented decl");
  }

  bool VisitStmt(Stmt *S) {
    S->dump();
    throw std::logic_error("unimplemented stmt");
  }

  bool VisitType(clang::Type *T) {
    T->dump();
    throw std::logic_error("unimplemented type");
  }

  bool TraverseTypeLoc(TypeLoc TL) {
    return TraverseType(TL.getType());
  }

  bool TraverseStmt(Stmt *S) {
    if (!S)
      return RecursiveASTVisitor::TraverseStmt(S);

    if (Expr *E = dyn_cast<Expr>(S)) {
      if (!dyn_cast<CXXDefaultArgExpr>(S)) {
        Kast::add(Kast::KApply("ExprLoc", Sort::EXPRLOC, {Sort::CABSLOC, Sort::KITEM}));
        CabsLoc(E->getExprLoc());
      }
    }
    return RecursiveASTVisitor::TraverseStmt(S);
  }

  // copied from RecursiveASTVisitor.h with a change made: D->isImplicit() -> excludedDecl(D)
  bool TraverseDecl(Decl *D) {
    if (!D)
      return true;

    if (excludedDecl(D))
      return true;

    Kast::add(Kast::KApply("DeclLoc", Sort::DECL, {Sort::CABSLOC, Sort::DECL}));
    CabsLoc(D->getLocation());

    switch (D->getKind()) {
#define ABSTRACT_DECL(DECL)
#define DECL(CLASS, BASE)                                                      \
      case Decl::CLASS:                                                            \
        if (!getDerived().Traverse##CLASS##Decl(static_cast<CLASS##Decl *>(D)))    \
          return false;                                                            \
        break;
#include "clang/AST/DeclNodes.inc"
    }

    return true;
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

  bool TraverseDeclContextNode(DeclContext *D) {
    for (clang::Decl * d : D->decls()) {
      if (!excludedDecl(d)) TRY_TO(TraverseDecl(d));
    }
    return true;
  }

  bool VisitTranslationUnitDecl(TranslationUnitDecl *D) {
    Kast::add(Kast::KApply("TranslationUnit", Sort::DECL, {Sort::STRING, Sort::LIST}));
    Kast::add(Kast::KToken(InFile));
    DeclContext(D);
    return false;
  }

  bool VisitTypedefDecl(TypedefDecl *D) {
    Kast::add(Kast::KApply("TypedefDecl", Sort::DECL, {Sort::CID, Sort::ATYPE}));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }

  bool VisitTypeAliasDecl(TypeAliasDecl *D) {
    Kast::add(Kast::KApply("TypeAliasDecl", Sort::DECL, {Sort::CID, Sort::ATYPE}));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }


  bool VisitLinkageSpecDecl(LinkageSpecDecl *D) {
    Kast::add(Kast::KApply("LinkageSpec", Sort::DECL, {Sort::STRING, Sort::BOOL, Sort::LIST}));
    std::string s;
    if (D->getLanguage() == LinkageSpecDecl::lang_c) {
      s = "C";
    } else if (D->getLanguage() == LinkageSpecDecl::lang_cxx) {
      s = "C++";
    }
    Kast::add(Kast::KToken(s));
    VisitBool(D->hasBraces());
    DeclContext(D);
    return false;
  }

  void VisitBool(bool b) {
    Kast::add(Kast::KToken(b));
  }

  bool VisitNamespaceDecl(NamespaceDecl *D) {
    Kast::add(Kast::KApply("NamespaceDecl", Sort::DECL, {Sort::CID, Sort::BOOL, Sort::LIST}));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    VisitBool(D->isInline());
    DeclContext(D);
    return false;
  }

  bool VisitNamespaceAliasDecl(NamespaceAliasDecl *D) {
    Kast::add(Kast::KApply("NamespaceAliasDecl", Sort::DECL, {Sort::CID, Sort::CID, Sort::NNS}));
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
      NoNNS();
      return true;
    }
    if (NNS->getPrefix()) {
      Kast::add(Kast::KApply("NestedName", Sort::NNS, {Sort::NNS, Sort::NNSSPECIFIER}));
      TRY_TO(TraverseNestedNameSpecifier(NNS->getPrefix()));
    }
    auto nns = Kast::KApply("NNS", Sort::NNSSPECIFIER, {Sort::CID});
    switch (NNS->getKind()) {
      case NestedNameSpecifier::Identifier:
        Kast::add(nns);
        TRY_TO(TraverseIdentifierInfo(NNS->getAsIdentifier()));
        break;
      case NestedNameSpecifier::Namespace:
        Kast::add(nns);
        TRY_TO(TraverseDeclarationName(NNS->getAsNamespace()->getDeclName()));
        break;
      case NestedNameSpecifier::NamespaceAlias:
        Kast::add(nns);
        TRY_TO(TraverseDeclarationName(NNS->getAsNamespaceAlias()->getDeclName()));
        break;
      case NestedNameSpecifier::TypeSpec:
        Kast::add(nns);
        TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
        break;
      case NestedNameSpecifier::TypeSpecWithTemplate:
        Kast::add(Kast::KApply("TemplateNNS", Sort::NNSSPECIFIER, {Sort::CID}));
        TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
        break;
      case NestedNameSpecifier::Global:
        Kast::add(Kast::KApply("GlobalNamespace", Sort::NAMESPACE));
        break;
      default:
        throw std::logic_error("unimplemented: nns");
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
        Kast::add(Kast::KApply("#NoName_COMMON-SYNTAX_NoName", Sort::NONAME));
      } else {
        Kast::add(Kast::KApply("unnamed", Sort::UNNAMEDCID, {Sort::INT, Sort::STRING}));
        VisitUnsigned((unsigned long long)decl);
        Kast::add(Kast::KToken(InFile));
      }
      return true;
    }
    Identifier(info->getName().str());
    return true;
  }

  bool TraverseDeclarationAsName(NamedDecl *D) {
    return TraverseDeclarationName(D->getDeclName(), (uintptr_t)D);
  }

  bool TraverseDeclarationName(DeclarationName Name) {
    return TraverseDeclarationName(Name, 0);
  }

  bool TraverseDeclarationName(DeclarationName Name, uintptr_t decl) {
    switch (Name.getNameKind()) {
      case DeclarationName::Identifier:
        {
          IdentifierInfo *info = Name.getAsIdentifierInfo();
          return TraverseIdentifierInfo(info, decl);
        }
      case DeclarationName::CXXConversionFunctionName:
      case DeclarationName::CXXConstructorName:
        {
          Kast::add(Kast::KApply("TypeId", Sort::TYPEID, {Sort::ATYPE}));
          TRY_TO(TraverseType(Name.getCXXNameType()));
          return true;
        }
      case DeclarationName::CXXDestructorName:
        {
          Kast::add(Kast::KApply("DestructorTypeId", Sort::DESTRUCTORID, {Sort::ATYPE}));
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
        throw std::logic_error("unimplemented: nameinfo");
    }
  }

  bool TraverseConstructorInitializer(CXXCtorInitializer *Init) {
    if (Init->isBaseInitializer()) {
      Kast::add(Kast::KApply("ConstructorBase", Sort::CTORINIT, {Sort::ATYPE, Sort::BOOL, Sort::BOOL, Sort::INIT}));
      TRY_TO(TraverseTypeLoc(Init->getTypeSourceInfo()->getTypeLoc()));
      VisitBool(Init->isBaseVirtual());
      VisitBool(Init->isPackExpansion());
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isMemberInitializer()) {
      Kast::add(Kast::KApply("ConstructorMember", Sort::CTORINIT, {Sort::CID, Sort::INIT}));
      TRY_TO(TraverseDeclarationName(Init->getMember()->getDeclName()));
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isDelegatingInitializer()) {
      Kast::add(Kast::KApply("ConstructorDelegating", Sort::CTORINIT, {Sort::INIT}));
      TRY_TO(TraverseStmt(Init->getInit()));
    } else {
      throw std::logic_error("unimplemented: ctor initializer");
    }
    return true;
  }

  bool TraverseFunctionHelper(FunctionDecl *D) {
    if (const FunctionTemplateSpecializationInfo *FTSI =
            D->getTemplateSpecializationInfo()) {
      if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitSpecialization) {
        if (const ASTTemplateArgumentListInfo *TALI =
                FTSI->TemplateArgumentsAsWritten) {
          Kast::add(Kast::KApply("TemplateSpecialization", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          Kast::add(Kast::KApply("TemplateSpecializationType", Sort::ATYPE, {Sort::CID, Sort::LIST}));
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          KSeqList(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          Kast::add(Kast::KApply("TemplateSpecialization", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          Kast::add(Kast::KApply("TemplateSpecializationType2", Sort::ATYPE, {Sort::CID}));
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      } else if (FTSI->getTemplateSpecializationKind() != TSK_Undeclared &&
          FTSI->getTemplateSpecializationKind() != TSK_ImplicitInstantiation) {
        if (const ASTTemplateArgumentListInfo *TALI =
                FTSI->TemplateArgumentsAsWritten) {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             Kast::add(Kast::KApply("TemplateInstantiationDefinition", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          } else {
             Kast::add(Kast::KApply("TemplateInstantiationDeclaration", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          }
          Kast::add(Kast::KApply("TemplateSpecializationType", Sort::ATYPE, {Sort::CID, Sort::LIST}));
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          KSeqList(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             Kast::add(Kast::KApply("TemplateInstantiationDefinition", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          } else {
             Kast::add(Kast::KApply("TemplateInstantiationDeclaration", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
          }
          Kast::add(Kast::KApply("TemplateSpecializationType2", Sort::ATYPE, {Sort::CID}));
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      }
    }

    StorageClass(D->getStorageClass());
    if (D->isInlineSpecified()) {
      Specifier("Inline", Sort::FUNCTIONSPECIFIER);
    }
    if (D->isConstexpr()) {
      Specifier("Constexpr", Sort::SPECIFIER);
    }

    if (D->isThisDeclarationADefinition() || D->isExplicitlyDefaulted()) {
      Kast::add(Kast::KApply("FunctionDefinition", Sort::DECLARATOR, {Sort::NNS, Sort::CID, Sort::CID, Sort::ATYPE, Sort::LIST, Sort::ASTMT}));
    } else {
      Kast::add(Kast::KApply("FunctionDecl", Sort::DECLARATOR, {Sort::NNS, Sort::CID, Sort::CID, Sort::ATYPE, Sort::LIST}));
    }

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(D->getNameInfo()));

    mangledIdentifier(D);

    if (TypeSourceInfo *TSI = D->getTypeSourceInfo()) {
      if (CXXMethodDecl *Method = dyn_cast<CXXMethodDecl>(D)) {
        if (Method->isInstance()) {
          switch (Method->getRefQualifier()) {
            case RQ_LValue:
              Kast::add(Kast::KApply("RefQualifier", Sort::ATYPE, {Sort::REFQUALIFIER, Sort::ATYPE}));
              Kast::add(Kast::KApply("RefLValue", Sort::REFQUALIFIER));
              break;
            case RQ_RValue:
              Kast::add(Kast::KApply("RefQualifier", Sort::ATYPE, {Sort::REFQUALIFIER, Sort::ATYPE}));
              Kast::add(Kast::KApply("RefRValue", Sort::REFQUALIFIER));
              break;
            case RQ_None: // do nothing
              break;
          }
          Kast::add(Kast::KApply("MethodPrototype", Sort::ATYPE, {Sort::BOOL, Sort::BOOL, Sort::ATYPE, Sort::ATYPE}));
          VisitBool(Method->isUserProvided());
          VisitBool(dyn_cast<CXXConstructorDecl>(D)); // converts to true if this is a constructor
          TRY_TO(TraverseType(Method->getThisType(*Context)));
          if (Method->isVirtual()) {
            Kast::add(Kast::KApply("Virtual", Sort::ATYPE, {Sort::ATYPE}));
          }
          if (Method->isPure()) {
            Kast::add(Kast::KApply("Pure", Sort::ATYPE, {Sort::ATYPE}));
          }

          if (CXXConversionDecl *Conv = dyn_cast<CXXConversionDecl>(D)) {
            if (Conv->isExplicitSpecified()) {
              Kast::add(Kast::KApply("Explicit", Sort::ATYPE, {Sort::ATYPE}));
            }
          }

          if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
            if (Ctor->isExplicitSpecified()) {
              Kast::add(Kast::KApply("Explicit", Sort::ATYPE, {Sort::ATYPE}));
            }
          }
        } else {
          Kast::add(Kast::KApply("StaticMethodPrototype", Sort::ATYPE, {Sort::ATYPE}));
        }
      }
      TRY_TO(TraverseType(D->getType()));
    } else {
      throw std::logic_error("something implicit in functions??");
    }

    KSeqList(D->parameters().size());
    for (auto p : D->parameters()) {
      TRY_TO(TraverseDecl(p));
    }

    if (D->isThisDeclarationADefinition()) {
      if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
        Kast::add(Kast::KApply("Constructor", Sort::STMT, {Sort::LIST, Sort::STMT}));
        int i = 0;
        for (auto *I : Ctor->inits()) {
          if (I->isWritten()) i++;
        }
        KSeqList(i);
        for (auto *I : Ctor->inits()) {
          if (I->isWritten()) {
            TRY_TO(TraverseConstructorInitializer(I));
          }
        }
      }
      TRY_TO(TraverseStmt(D->getBody()));
    }
    if (D->isExplicitlyDefaulted()) {
      Kast::add(Kast::KApply("Defaulted", Sort::STMT));
    } else if (D->isDeleted()) {
      Kast::add(Kast::KApply("Deleted", Sort::STMT));
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
    StorageClass(D->getStorageClass());
    ThreadStorageClass(D->getTSCSpec());
    if (D->isConstexpr()) {
      Specifier("Constexpr", Sort::SPECIFIER);
    }
    if (unsigned align = D->getMaxAlignment()) {
      AlignasSpecifier(align / 8);
    }
    Kast::add(Kast::KApply("VarDecl", Sort::DECLARATOR, {Sort::NNS, Sort::CID, Sort::CID, Sort::ATYPE, Sort::INIT, Sort::BOOL}));

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));

    mangledIdentifier(D);

    TRY_TO(TraverseType(D->getType()));
    if (D->getInit()) {
      TRY_TO(TraverseStmt(D->getInit()));
    } else {
      Kast::add(Kast::KApply("NoInit", Sort::INIT));
    }
    VisitBool(D->isDirectInit());
    return true;
  }

  bool TraverseVarDecl(VarDecl *D) {
    return TraverseVarHelper(D);
  }

  bool TraverseFieldDecl(FieldDecl *D) {
    if (D->isMutable()) {
      Specifier("Mutable", Sort::STORAGECLASSSPECIFIER);
    }
    if (D->isBitField()) {
      Kast::add(Kast::KApply("BitFieldDecl", Sort::DECLARATOR, {Sort::NNS, Sort::CID, Sort::ATYPE, Sort::EXPR}));
    } else {
      Kast::add(Kast::KApply("FieldDecl", Sort::DECLARATOR, {Sort::NNS, Sort::CID, Sort::ATYPE, Sort::INIT}));
    }
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if (D->isBitField()) {
      TRY_TO(TraverseStmt(D->getBitWidth()));
    } else if (D->hasInClassInitializer()) {
      TRY_TO(TraverseStmt(D->getInClassInitializer()));
    } else {
      Kast::add(Kast::KApply("NoInit", Sort::INIT));
    }
    return true;
  }

  bool TraverseParmVarDecl(ParmVarDecl *D) {
    //TODO(other stuff)
    return TraverseVarHelper(D);
  }

  bool VisitFriendDecl(FriendDecl *D) {
    Kast::add(Kast::KApply("FriendDecl", Sort::DECL, {Sort::DECL}));
    return false;
  }

  void VisitAccessSpecifier(AccessSpecifier Spec) {
    const char *spec;
    switch (Spec) {
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
    Kast::add(Kast::KApply(spec, Sort::ACCESSSPECIFIER));
  }

  #define TRAVERSE_TEMPLATE_DECL(DeclKind) \
  bool Traverse##DeclKind##TemplateDecl(DeclKind##TemplateDecl *D) { \
    Kast::add(Kast::KApply("TemplateWithInstantiations", Sort::DECL, {Sort::DECL, Sort::LIST, Sort::LIST})); \
    TRY_TO(TraverseDecl(D->getTemplatedDecl())); \
    TemplateParameterList *TPL = D->getTemplateParameters(); \
    if (TPL) { \
      KSeqList(TPL->size()); \
      for (auto p : *TPL) { \
        TRY_TO(TraverseDecl(p)); \
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
      switch (FD->getTemplateSpecializationKind()) {
        case TSK_ImplicitInstantiation:
        case TSK_ExplicitInstantiationDeclaration:
        case TSK_ExplicitInstantiationDefinition:
          i++;
        default:
          break;
      }
    }
    KSeqList(i);
    for (auto *FD : D->specializations()) {
      switch (FD->getTemplateSpecializationKind()) {
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
    KSeqList(0);
    return true;
  }

  bool TraverseTemplateInstantiations(VarTemplateDecl *D) {
    unsigned i = 0;
    for (auto *FD : D->specializations()) {
      switch (FD->getTemplateSpecializationKind()) {
        case TSK_ImplicitInstantiation:
        case TSK_ExplicitInstantiationDeclaration:
        case TSK_ExplicitInstantiationDefinition:
          i++;
        default:
          break;
      }
    }
    KSeqList(i);
    for (auto *FD : D->specializations()) {
      switch (FD->getTemplateSpecializationKind()) {
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
      switch (FD->getTemplateSpecializationKind()) {
        case TSK_ImplicitInstantiation:
        case TSK_ExplicitInstantiationDeclaration:
        case TSK_ExplicitInstantiationDefinition:
          i++;
        default:
          break;
      }
    }
    KSeqList(i);
    for (auto *FD : D->specializations()) {
      switch (FD->getTemplateSpecializationKind()) {
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
    Kast::add(Kast::KApply("TypeTemplateParam", Sort::TEMPLATEPARAMETER, {Sort::BOOL, Sort::BOOL, Sort::ATYPE, Sort::ATYPE}));
    VisitBool(D->wasDeclaredWithTypename());
    VisitBool(D->isParameterPack());
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      NoType();
    }
    if (D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseType(D->getDefaultArgumentInfo()->getType()));
    } else {
      NoType();
    }
    return true;
  }

  bool TraverseNonTypeTemplateParmDecl(NonTypeTemplateParmDecl *D) {
    Kast::add(Kast::KApply("ValueTemplateParam", Sort::TEMPLATEPARAMETER, {Sort::BOOL, Sort::NNS, Sort::CID, Sort::ATYPE, Sort::AEXPR}));
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if (D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseStmt(D->getDefaultArgument()));
    } else {
      NoExpression();
    }
    return true;
  }

  bool TraverseTemplateTemplateParmDecl(TemplateTemplateParmDecl *D) {
    Kast::add(Kast::KApply("TemplateTemplateParam", Sort::TEMPLATEPARAMETER, {Sort::BOOL, Sort::CID, Sort::ATYPE, Sort::LIST}));
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    if (D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseTemplateArgumentLoc(D->getDefaultArgument()));
    } else {
      NoType();
    }
    TemplateParameterList *TPL = D->getTemplateParameters();
    if (TPL) {
      KSeqList(TPL->size());
      for (auto p : *TPL) TRY_TO(TraverseDecl(p));
    }
    return true;
  }

  bool TraverseTemplateArgument(const TemplateArgument &Arg) {
    switch (Arg.getKind()) {
      case TemplateArgument::Type:
        Kast::add(Kast::KApply("TypeArg", Sort::TEMPLATEARGUMENT, {Sort::ATYPE}));
        return getDerived().TraverseType(Arg.getAsType());
      case TemplateArgument::Template:
        Kast::add(Kast::KApply("TemplateArg", Sort::TEMPLATEARGUMENT, {Sort::CID}));
        return getDerived().TraverseTemplateName(Arg.getAsTemplate());
      case TemplateArgument::Expression:
        Kast::add(Kast::KApply("ExprArg", Sort::TEMPLATEARGUMENT, {Sort::EXPR}));
        return getDerived().TraverseStmt(Arg.getAsExpr());
      case TemplateArgument::Integral:
        Kast::add(Kast::KApply("ExprArg", Sort::TEMPLATEARGUMENT, {Sort::EXPR}));
        Kast::add(Kast::KApply("IntegerLiteral", Sort::EXPR, {Sort::INT, Sort::ATYPE}));
        VisitAPInt(Arg.getAsIntegral());
        return getDerived().TraverseType(Arg.getIntegralType());
      case TemplateArgument::Pack:
        Kast::add(Kast::KApply("PackArg", Sort::TEMPLATEARGUMENT, {Sort::LIST}));
        KSeqList(Arg.pack_size());
        for (const TemplateArgument arg : Arg.pack_elements()) {
          TRY_TO(TraverseTemplateArgument(arg));
        }
        return true;
      default:
        throw std::logic_error("unimplemented: template argument");
    }
  }

  bool TraverseTemplateName(TemplateName Name) {
    switch (Name.getKind()) {
      case TemplateName::Template:
        TRY_TO(TraverseDeclarationName(Name.getAsTemplateDecl()->getDeclName()));
        break;
      default:
        throw std::logic_error("unimplemented: template name");
    }
    return true;
  }

  bool TraverseTemplateArgumentLoc(const TemplateArgumentLoc &Arg) {
    return TraverseTemplateArgument(Arg.getArgument());
  }

  bool TraverseTemplateArgumentLocs(
      const TemplateArgumentLoc *TAL, unsigned Count) {
    for (unsigned i = 0; i < Count; ++i) {
      TRY_TO(TraverseTemplateArgumentLoc(TAL[i]));
    }
    return true;
  }

  void VisitTagKind(TagTypeKind T) {
    switch (T) {
      case TTK_Struct:
        Kast::add(Kast::KApply("Struct", Sort::CLASSKEY));
        break;
      case TTK_Union:
        Kast::add(Kast::KApply("Union", Sort::CLASSKEY));
        break;
      case TTK_Class:
        Kast::add(Kast::KApply("Class", Sort::CLASSKEY));
        break;
      case TTK_Enum:
        Kast::add(Kast::KApply("Enum", Sort::TAG));
        break;
      default:
        throw std::logic_error("unimplemented: tag kind");
    }
  }

  bool TraverseCXXRecordHelper(CXXRecordDecl *D) {
    if (D->isCompleteDefinition()) {
      Kast::add(Kast::KApply("ClassDef", Sort::DECL, {Sort::TAG, Sort::CID, Sort::NNS, Sort::LIST, Sort::LIST, Sort::BOOL}));
    } else {
      Kast::add(Kast::KApply("TypeDecl", Sort::DECL, {Sort::ATYPE}));
      Kast::add(Kast::KApply("ElaboratedTypeSpecifier", Sort::ATYPE, {Sort::TAG, Sort::CID, Sort::NNS}));
    }
    VisitTagKind(D->getTagKind());
    TRY_TO(TraverseDeclarationAsName(D));
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    if (D->isCompleteDefinition()) {
      KSeqList(D->getNumBases());
      for (const auto &I : D->bases()) {
        Kast::add(Kast::KApply("BaseClass", Sort::BASESPECIFIER, {Sort::BOOL, Sort::BOOL, Sort::ACCESSSPECIFIER, Sort::ATYPE}));
        VisitBool(I.isVirtual());
        VisitBool(I.isPackExpansion());
        VisitAccessSpecifier(I.getAccessSpecifierAsWritten());
        TRY_TO(TraverseType(I.getType()));
      }
      DeclContext(D);
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
      Kast::add(Kast::KApply("OpaqueEnumDeclaration", Sort::DECL, {Sort::CID, Sort::BOOL, Sort::ATYPE}));
      TRY_TO(TraverseDeclarationName(D->getDeclName()));
      VisitBool(D->isScoped());
      TraverseType(D->getIntegerType());
      return true;
    }

    Kast::add(Kast::KApply("EnumDef", Sort::DECL, {Sort::CID, Sort::NNS, Sort::BOOL, Sort::BOOL, Sort::ATYPE, Sort::LIST}));
    TRY_TO(TraverseDeclarationAsName(D));
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    VisitBool(D->isScoped());
    VisitBool(D->isFixed());
    TraverseType(D->getIntegerType());

    DeclContext(D);
    TraverseDeclContextNode(D);
    return true;
  }

  bool VisitEnumConstantDecl(EnumConstantDecl *D) {
    Kast::add(Kast::KApply("Enumerator", Sort::ENUMERATOR, {Sort::CID, Sort::AEXPR}));
    TraverseDeclarationName(D->getDeclName());
    if (!D->getInitExpr()) {
      NoExpression();
    }
    return false;
  }

  bool TraverseClassTemplateSpecializationDecl(ClassTemplateSpecializationDecl *D) {
    switch (D->getSpecializationKind()) {
      case TSK_ExplicitSpecialization:
        Kast::add(Kast::KApply("TemplateSpecialization", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
        break;
      case TSK_ExplicitInstantiationDeclaration:
        Kast::add(Kast::KApply("TemplateInstantiationDeclaration", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
        break;
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDefinition:
        Kast::add(Kast::KApply("TemplateInstantiationDefinition", Sort::DECL, {Sort::ATYPE, Sort::DECL}));
        break;
      default:
        throw std::logic_error("unimplemented: implicit template instantiation");
    }
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      NoType();
    }
    TRY_TO(TraverseCXXRecordHelper(D));
    return true;
  }

  bool TraverseClassTemplatePartialSpecializationDecl(ClassTemplatePartialSpecializationDecl *D) {
    Kast::add(Kast::KApply("PartialSpecialization", Sort::DECL, {Sort::LIST, Sort::LIST, Sort::DECL}));
    /* The partial specialization. */
    TemplateParameterList *TPL = D->getTemplateParameters();
    KSeqList(TPL->size());
    for (auto p : *TPL) TRY_TO(TraverseDecl(p));
    KSeqList(D->getTemplateArgsAsWritten()->NumTemplateArgs);
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
    Kast::add(Kast::KApply("AccessSpec", Sort::DECL, {Sort::ACCESSSPECIFIER}));
    VisitAccessSpecifier(D->getAccess());
    return false;
  }

  bool VisitStaticAssertDecl(StaticAssertDecl *D) {
    Kast::add(Kast::KApply("StaticAssert", Sort::DECL, {Sort::EXPR, Sort::EXPR}));
    return false;
  }

  bool VisitUsingDecl(UsingDecl *D) {
    Kast::add(Kast::KApply("UsingDecl", Sort::DECL, {Sort::BOOL, Sort::NNS, Sort::CID}));
    VisitBool(D->hasTypename());
    return false;
  }

  bool VisitUnresolvedUsingValueDecl(UnresolvedUsingValueDecl *D) {
    Kast::add(Kast::KApply("UsingDecl", Sort::DECL, {Sort::BOOL, Sort::NNS, Sort::CID}));
    VisitBool(false);
    return false;
  }

  bool VisitUsingDirectiveDecl(UsingDirectiveDecl *D) {
    Kast::add(Kast::KApply("UsingDirective", Sort::DECL, {Sort::CID, Sort::NNS}));
    TRY_TO(TraverseDeclarationName(D->getNominatedNamespaceAsWritten()->getDeclName()));
    return false;
  }

  bool TraverseFunctionProtoType(FunctionProtoType *T) {
    Kast::add(Kast::KApply("FunctionPrototype", Sort::ATYPE, {Sort::ATYPE, Sort::STRICTLIST, Sort::EXCEPTIONSPEC, Sort::BOOL}));

    TRY_TO(TraverseType(T->getReturnType()));

    List(T->getNumParams());
    for (unsigned i = 0; i < T->getNumParams(); i++) {
      TRY_TO(TraverseType(T->getParamType(i)));
    }

    switch (T->getExceptionSpecType()) {
      case EST_None:
        Kast::add(Kast::KApply("NoExceptionSpec", Sort::EXCEPTIONSPEC));
        break;
      case EST_BasicNoexcept:
        Kast::add(Kast::KApply("NoexceptSpec", Sort::EXCEPTIONSPEC, {Sort::AEXPR}));
        NoExpression();
        break;
      case EST_ComputedNoexcept:
        Kast::add(Kast::KApply("NoexceptSpec", Sort::EXCEPTIONSPEC, {Sort::AEXPR}));
        TRY_TO(TraverseStmt(T->getNoexceptExpr()));
        break;
      case EST_DynamicNone:
        Kast::add(Kast::KApply("ThrowSpec", Sort::EXCEPTIONSPEC, {Sort::STRICTLIST}));
        List(0);
        break;
      case EST_Dynamic:
        Kast::add(Kast::KApply("ThrowSpec", Sort::EXCEPTIONSPEC, {Sort::STRICTLIST}));
        List(T->getNumExceptions());
        for (unsigned i = 0; i < T->getNumExceptions(); i++) {
          TRY_TO(TraverseType(T->getExceptionType(i)));
        }
        break;
      default:
        throw std::logic_error("unimplemented: exception spec");
    }

    VisitBool(T->isVariadic());
    return true;
  }

  bool VisitBuiltinType(BuiltinType *T) {
    Kast::add(Kast::KApply("BuiltinType", Sort::ATYPE, {Sort::TYPESPECIFIER}));
    switch (T->getKind()) {
      case BuiltinType::Void:
        Kast::add(Kast::KApply("Void", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Char_S:
      case BuiltinType::Char_U:
        Kast::add(Kast::KApply("Char", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::WChar_S:
      case BuiltinType::WChar_U:
        Kast::add(Kast::KApply("WChar", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Char16:
        Kast::add(Kast::KApply("Char16", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Char32:
        Kast::add(Kast::KApply("Char32", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Bool:
        Kast::add(Kast::KApply("Bool", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::UChar:
        Kast::add(Kast::KApply("UChar", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::UShort:
        Kast::add(Kast::KApply("UShort", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::UInt:
        Kast::add(Kast::KApply("UInt", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::ULong:
        Kast::add(Kast::KApply("ULong", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::ULongLong:
        Kast::add(Kast::KApply("ULongLong", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::SChar:
        Kast::add(Kast::KApply("SChar", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Short:
        Kast::add(Kast::KApply("Short", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Int:
        Kast::add(Kast::KApply("Int", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Long:
        Kast::add(Kast::KApply("Long", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::LongLong:
        Kast::add(Kast::KApply("LongLong", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Float:
        Kast::add(Kast::KApply("Float", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Double:
        Kast::add(Kast::KApply("Double", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::LongDouble:
        Kast::add(Kast::KApply("LongDouble", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Int128:
        Kast::add(Kast::KApply("OversizedInt", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::UInt128:
        Kast::add(Kast::KApply("OversizedUInt", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::Dependent:
        Kast::add(Kast::KApply("Dependent", Sort::TYPESPECIFIER));
        break;
      case BuiltinType::NullPtr:
        Kast::add(Kast::KApply("NullPtr", Sort::TYPESPECIFIER));
        break;
      default:
        throw std::logic_error("unimplemented: basic type");
    }
    return false;
  }

  bool VisitPointerType(clang::PointerType *T) {
    Kast::add(Kast::KApply("PointerType", Sort::ATYPE, {Sort::ATYPE}));
    return false;
  }

  bool VisitMemberPointerType(MemberPointerType *T) {
    Kast::add(Kast::KApply("MemberPointerType", Sort::ATYPE, {Sort::ATYPE, Sort::ATYPE}));
    return false;
  }

  bool TraverseArrayHelper(clang::ArrayType *T, Sort sort) {
    if (T->getSizeModifier() != clang::ArrayType::Normal) {
      throw std::logic_error("unimplemented: static/* array");
    }
    std::string arr;
    if (sort == Sort::AEXPR) {
       arr = "ArrayTypeAExpr";
    } else {
       arr = "ArrayType";
    }
    Kast::add(Kast::KApply(arr, Sort::ATYPE, {Sort::ATYPE, sort}));
    TRY_TO(TraverseType(T->getElementType()));
    return true;
  }

  bool TraverseConstantArrayType(ConstantArrayType *T) {
    TRY_TO(TraverseArrayHelper(T, Sort::INT));
    VisitAPInt(T->getSize());
    return true;
  }

  bool TraverseDependentSizedArrayType(DependentSizedArrayType *T) {
    TRY_TO(TraverseArrayHelper(T, Sort::AEXPR));
    TRY_TO(TraverseStmt(T->getSizeExpr()));
    return true;
  }

  bool TraverseVariableArrayType(VariableArrayType *T) {
    TRY_TO(TraverseArrayHelper(T, Sort::AEXPR));
    TRY_TO(TraverseStmt(T->getSizeExpr()));
    return true;
  }

  bool TraverseIncompleteArrayType(IncompleteArrayType *T) {
    TRY_TO(TraverseArrayHelper(T, Sort::AEXPR));
    NoExpression();
    return true;
  }

  bool VisitTypedefType(TypedefType *T) {
    Kast::add(Kast::KApply("TypedefType", Sort::ATYPE, {Sort::CID}));
    TRY_TO(TraverseDeclarationName(T->getDecl()->getDeclName()));
    return false;
  }

  void VisitTypeKeyword(ElaboratedTypeKeyword Keyword) {
    switch (Keyword) {
      case ETK_Struct:
        Kast::add(Kast::KApply("Struct", Sort::CLASSKEY));
        break;
      case ETK_Union:
        Kast::add(Kast::KApply("Union", Sort::CLASSKEY));
        break;
      case ETK_Class:
        Kast::add(Kast::KApply("Class", Sort::CLASSKEY));
        break;
      case ETK_Enum:
        Kast::add(Kast::KApply("Enum", Sort::TAG));
        break;
      case ETK_Typename:
        Kast::add(Kast::KApply("Typename", Sort::TAG));
        break;
      case ETK_None:
        Kast::add(Kast::KApply("NoTag", Sort::TAG));
        break;
      default:
        throw std::logic_error("unimplemented: type keyword");
    }
  }

  bool VisitElaboratedType(ElaboratedType *T) {
    Kast::add(Kast::KApply("QualifiedTypeName", Sort::ATYPE, {Sort::TAG, Sort::NNS, Sort::ATYPE}));
    VisitTypeKeyword(T->getKeyword());
    if (!T->getQualifier()) NoNNS();
    return false;
  }

  bool VisitDecltypeType(DecltypeType *T) {
    Kast::add(Kast::KApply("Decltype", Sort::ATYPE, {Sort::EXPR}));
    return false;
  }

  bool VisitTemplateTypeParmType(TemplateTypeParmType *T) {
    Kast::add(Kast::KApply("TemplateParameterType", Sort::ATYPE, {Sort::CID}));
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool TraverseSubstTemplateTypeParmType(SubstTemplateTypeParmType *T) {
    TRY_TO(TraverseType(T->getReplacementType()));
    return true;
  }

  bool VisitTagType(TagType *T) {
    TagDecl *D = T->getDecl();
    Name();
    NoNNS();
    TRY_TO(TraverseDeclarationAsName(D));
    return false;
  }

  bool VisitLValueReferenceType(LValueReferenceType *T) {
    Kast::add(Kast::KApply("LValRefType", Sort::ATYPE, {Sort::ATYPE}));
    return false;
  }

  bool VisitRValueReferenceType(RValueReferenceType *T) {
    Kast::add(Kast::KApply("RValRefType", Sort::ATYPE, {Sort::ATYPE}));
    return false;
  }

  bool TraverseInjectedClassNameType(InjectedClassNameType *T) {
    TRY_TO(TraverseType(T->getInjectedSpecializationType()));
    return true;
  }

  bool TraverseDependentTemplateSpecializationType(DependentTemplateSpecializationType *T) {
    Kast::add(Kast::KApply("TemplateSpecializationType", Sort::ATYPE, {Sort::CID, Sort::LIST}));
    Name();
    TRY_TO(TraverseNestedNameSpecifier(T->getQualifier()));
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    KSeqList(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool TraverseTemplateSpecializationType(const TemplateSpecializationType *T) {
    Kast::add(Kast::KApply("TemplateSpecializationType", Sort::ATYPE, {Sort::CID, Sort::LIST}));
    TRY_TO(TraverseTemplateName(T->getTemplateName()));
    KSeqList(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool VisitDependentNameType(DependentNameType *T) {
    Kast::add(Kast::KApply("ElaboratedTypeSpecifier", Sort::ATYPE, {Sort::TAG, Sort::CID, Sort::NNS}));
    VisitTypeKeyword(T->getKeyword());
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool VisitPackExpansionType(PackExpansionType *T) {
    Kast::add(Kast::KApply("PackExpansionType", Sort::ATYPE, {Sort::ATYPE}));
    return false;
  }

  bool TraverseAutoType(AutoType *T) {
    if (T->isDeduced()) {
      TRY_TO(TraverseType(T->getDeducedType()));
    } else {
      Kast::add(Kast::KApply("AutoType", Sort::ATYPE, {Sort::BOOL}));
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
    Kast::add(Kast::KApply("TypeofExpression", Sort::ATYPE, {Sort::EXPR}));
    return false;
  }

  bool VisitTypeOfType(TypeOfType *T) {
    Kast::add(Kast::KApply("TypeofType", Sort::ATYPE, {Sort::ATYPE}));
    return false;
  }

  bool VisitUnaryTransformType(UnaryTransformType *T) {
    if (T->isSugared()) {
      Kast::add(Kast::KApply("GnuEnumUnderlyingType2", Sort::ATYPE, {Sort::ATYPE, Sort::ATYPE}));
    } else {
      Kast::add(Kast::KApply("GnuEnumUnderlyingType1", Sort::ATYPE, {Sort::ATYPE}));
    }
    return false;
  }

  bool TraverseType(QualType T) {
    Qualifiers(T);
    return RecursiveASTVisitor::TraverseType(T);
  }

  bool VisitDeclStmt(DeclStmt *S) {
    Kast::add(Kast::KApply("DeclStmt", Sort::STMT, {Sort::LIST}));
    int i = 0;
    for (auto *I : S->decls()) {
      i++;
    }
    KSeqList(i);
    return false;
  }

  bool VisitBreakStmt(BreakStmt *S) {
    Kast::add(Kast::KApply("TBreakStmt", Sort::STMT));
    return false;
  }

  bool VisitContinueStmt(ContinueStmt *S) {
    Kast::add(Kast::KApply("ContinueStmt", Sort::STMT));
    return false;
  }

  bool VisitGotoStmt(GotoStmt *S) {
    Kast::add(Kast::KApply("GotoStmt", Sort::STMT, {Sort::CID}));
    TRY_TO(TraverseDeclarationName(S->getLabel()->getDeclName()));
    return false;
  }

  bool VisitReturnStmt(ReturnStmt *S) {
    Kast::add(Kast::KApply("ReturnStmt", Sort::STMT, {Sort::INIT}));
    if (!S->getRetValue()) {
      Kast::add(Kast::KApply("NoInit", Sort::INIT));
    }
    return false;
  }

  bool VisitNullStmt(NullStmt *S) {
    Kast::add(Kast::KApply("NullStmt", Sort::STMT));
    return false;
  }

  bool VisitCompoundStmt(CompoundStmt *S) {
    Kast::add(Kast::KApply("CompoundAStmt", Sort::ASTMT, {Sort::LIST}));
    StmtChildren(S);
    return false;
  }

  bool VisitLabelStmt(LabelStmt *S) {
    Kast::add(Kast::KApply("LabelAStmt", Sort::ASTMT, {Sort::CID, Sort::LIST}));
    TRY_TO(TraverseDeclarationName(S->getDecl()->getDeclName()));
    StmtChildren(S);
    return false;
  }

  bool TraverseForStmt(ForStmt *S) {
    Kast::add(Kast::KApply("ForAStmt", Sort::ASTMT, {Sort::ASTMT, Sort::AEXPR, Sort::AEXPR, Sort::ASTMT}));
    if (S->getInit()) {
      TRY_TO(TraverseStmt(S->getInit()));
    } else {
      NoStatement();
    }
    if (S->getCond()) {
      TRY_TO(TraverseStmt(S->getCond()));
    } else {
      NoExpression();
    }
    if (S->getInc()) {
      TRY_TO(TraverseStmt(S->getInc()));
    } else {
      NoExpression();
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseWhileStmt(WhileStmt *S) {
    Kast::add(Kast::KApply("WhileAStmt", Sort::ASTMT, {Sort::EXPR, Sort::ASTMT}));
    if (S->getConditionVariable()) {
      TRY_TO(TraverseDecl(S->getConditionVariable()));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool VisitDoStmt(DoStmt *S) {
    Kast::add(Kast::KApply("DoWhileAStmt", Sort::ASTMT, {Sort::ASTMT, Sort::EXPR}));
    return false;
  }

  bool TraverseIfStmt(IfStmt *S) {
    Kast::add(Kast::KApply("IfAStmt", Sort::ASTMT, {Sort::DECL, Sort::ASTMT, Sort::ASTMT}));
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getThen()));
    if (Stmt *Else = S->getElse()) {
      TRY_TO(TraverseStmt(Else));
    } else {
      NoStatement();
    }
    return true;
  }

  bool TraverseSwitchStmt(SwitchStmt *S) {
    Kast::add(Kast::KApply("SwitchAStmt", Sort::ASTMT, {Sort::DECL, Sort::ASTMT}));
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseCaseStmt(CaseStmt *S) {
    Kast::add(Kast::KApply("CaseAStmt", Sort::ASTMT, {Sort::EXPR, Sort::ASTMT}));
    if (S->getRHS()) {
      throw std::logic_error("unimplemented: gnu case stmt extensions");
    }
    TRY_TO(TraverseStmt(S->getLHS()));
    TRY_TO(TraverseStmt(S->getSubStmt()));
    return true;
  }

  bool VisitDefaultStmt(DefaultStmt *S) {
    Kast::add(Kast::KApply("DefaultAStmt", Sort::ASTMT, {Sort::ASTMT}));
    return false;
  }

  bool TraverseCXXTryStmt(CXXTryStmt *S) {
    Kast::add(Kast::KApply("TryAStmt", Sort::ASTMT, {Sort::ASTMT, Sort::LIST}));
    TRY_TO(TraverseStmt(S->getTryBlock()));
    KSeqList(S->getNumHandlers());
    for (unsigned i = 0; i < S->getNumHandlers(); i++) {
      TRY_TO(TraverseStmt(S->getHandler(i)));
    }
    return true;
  }

  bool VisitCXXCatchStmt(CXXCatchStmt *S) {
    Kast::add(Kast::KApply("CatchAStmt", Sort::ASTMT, {Sort::CATCHDECL, Sort::ASTMT}));
    if (!S->getExceptionDecl()) {
      Kast::add(Kast::KApply("Ellipsis", Sort::CATCHDECL));
    }
    return false;
  }

  template<typename ExprType>
  bool TraverseMemberHelper(ExprType *E) {
    if (E->isImplicitAccess()) {
      Name();
      TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
      TRY_TO(TraverseDeclarationNameInfo(E->getMemberNameInfo()));
    } else {
      Kast::add(Kast::KApply("MemberExpr", Sort::EXPR, {Sort::BOOL, Sort::BOOL, Sort::NAME, Sort::EXPR}));
      VisitBool(E->isArrow());
      VisitBool(E->hasTemplateKeyword());
      Name();
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
    Kast::add(Kast::KApply("Subscript", Sort::EXPR, {Sort::EXPR, Sort::EXPR}));
    return false;
  }

  bool TraverseCXXMemberCallExpr(CXXMemberCallExpr *E) {
    return TraverseCallExpr(E);
  }

  bool TraverseCallExpr(CallExpr *E) {
    Kast::add(Kast::KApply("CallExpr", Sort::RESOLVEDEXPR, {Sort::EXPR, Sort::STRICTLIST, Sort::STRICTLISTRESULT}));
    unsigned i = 0;
    for (Stmt *SubStmt : E->children()) {
      i++;
    }
    if (i-1 != E->getNumArgs()) {
      throw std::logic_error("unimplemented: pre_args???");
    }
    bool first = true;
    for (Stmt *SubStmt : E->children()) {
      TRY_TO(TraverseStmt(SubStmt));
      if (first) List(i-1);
      first = false;
    }
    Kast::add(Kast::KApply("krlist", Sort::STRICTLISTRESULT, {Sort::LIST}));
    Kast::add(Kast::KApply(".List", Sort::LIST));
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
    Name();
    return false;
  }

  bool VisitDependentScopeDeclRefExpr(DependentScopeDeclRefExpr *E) {
    Name();
    return false;
  }

  bool TraverseUnresolvedLookupExpr(UnresolvedLookupExpr *E) {
    Name();
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(E->getNameInfo()));
    return true;
  }

  void VisitOperator(OverloadedOperatorKind Kind) {
    switch (Kind) {
      #define OVERLOADED_OPERATOR(Name,Spelling,Token,Unary,Binary,MemberOnly) \
      case OO_##Name:                                                          \
        Kast::add(Kast::KApply("operator" Spelling "_CPP-SYNTAX", Sort::OPID));                                 \
        break;
      #include "clang/Basic/OperatorKinds.def"
      default:
        throw std::logic_error("unsupported overloaded operator");
    }
  }

  void VisitOperator(UnaryOperatorKind Kind) {
    switch (Kind) {
      #define UNARY_OP(Name, Spelling)         \
      case UO_##Name:                          \
        Kast::add(Kast::KApply("operator" Spelling "_CPP-SYNTAX", Sort::OPID)); \
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
        Kast::add(Kast::KApply("RealOperator", Sort::OPID));
        break;
      case UO_Imag:
        Kast::add(Kast::KApply("ImagOperator", Sort::OPID));
        break;
      case UO_Extension:
        Kast::add(Kast::KApply("ExtensionOperator", Sort::OPID));
        break;
      case UO_Coawait:
        Kast::add(Kast::KApply("CoawaitOperator", Sort::OPID));
        break;
      default:
        throw std::logic_error("unsupported unary operator");
    }
  }

  void VisitOperator(BinaryOperatorKind Kind) {
    switch (Kind) {
      #define BINARY_OP(Name, Spelling)        \
      case BO_##Name:                          \
        Kast::add(Kast::KApply("operator" Spelling "_CPP-SYNTAX", Sort::OPID)); \
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
        throw std::logic_error("unsupported binary operator");
    }
  }

  bool VisitUnaryOperator(UnaryOperator *E) {
    UnaryOperator();
    VisitOperator(E->getOpcode());
    return false;
  }


  bool VisitBinaryOperator(BinaryOperator *E) {
    BinaryOperator();
    VisitOperator(E->getOpcode());
    return false;
  }

  bool VisitConditionalOperator(ConditionalOperator *E) {
    Kast::add(Kast::KApply("ConditionalOperator", Sort::EXPR, {Sort::EXPR, Sort::EXPR, Sort::EXPR}));
    return false;
  }

  bool TraverseCXXOperatorCallExpr(CXXOperatorCallExpr *E) {
    switch (E->getOperator()) {
      case OO_Call:
        // TODO(chathhorn)
        Kast::add(Kast::KApply("OverloadedCall", Sort::EXPR));
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
          BinaryOperator();
          VisitOperator(E->getOperator());
          TRY_TO(TraverseStmt(E->getArg(0)));
          TRY_TO(TraverseStmt(E->getArg(1)));
          break;
        } else if (E->getNumArgs() == 1) {
          UnaryOperator();
          VisitOperator(E->getOperator());
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else {
          throw std::logic_error("unexpected number of arguments to operator");
        }
      case OO_PlusPlus:
        if (E->getNumArgs() == 2) {
          UnaryOperator();
          VisitOperator(UO_PostInc);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else if (E->getNumArgs() == 1) {
          UnaryOperator();
          VisitOperator(UO_PreInc);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else {
          throw std::logic_error("unexpected number of arguments to operator");
        }
      case OO_MinusMinus:
        if (E->getNumArgs() == 2) {
          UnaryOperator();
          VisitOperator(UO_PostDec);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else if (E->getNumArgs() == 1) {
          UnaryOperator();
          VisitOperator(UO_PreDec);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else {
          throw std::logic_error("unexpected number of arguments to operator");
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
          throw std::logic_error("unexpected number of arguments to operator");
        }
        BinaryOperator();
        VisitOperator(E->getOperator());
        TRY_TO(TraverseStmt(E->getArg(0)));
        TRY_TO(TraverseStmt(E->getArg(1)));
        break;
      case OO_Tilde:
      case OO_Exclaim:
      case OO_Coawait:
        if (E->getNumArgs() != 1) {
          throw std::logic_error("unexpected number of arguments to operator");
        }
        UnaryOperator();
        VisitOperator(E->getOperator());
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      default:
        throw std::logic_error("unimplemented: overloaded operator");
    }
    return true;
  }

  bool VisitCStyleCastExpr(CStyleCastExpr *E) {
    Kast::add(Kast::KApply("ParenthesizedCast", Sort::EXPR, {Sort::ATYPE, Sort::EXPR}));
    return false;
  }

  bool VisitCXXReinterpretCastExpr(CXXReinterpretCastExpr *E) {
    Kast::add(Kast::KApply("ReinterpretCast", Sort::RESOLVEDEXPR, {Sort::ATYPE, Sort::EXPR}));
    return false;
  }

  bool VisitCXXStaticCastExpr(CXXStaticCastExpr *E) {
    Kast::add(Kast::KApply("StaticCast", Sort::EXPR, {Sort::ATYPE, Sort::EXPR}));
    return false;
  }

  bool VisitCXXDynamicCastExpr(CXXDynamicCastExpr *E) {
    Kast::add(Kast::KApply("DynamicCast", Sort::EXPR, {Sort::ATYPE, Sort::EXPR}));
    return false;
  }

  bool VisitCXXConstCastExpr(CXXConstCastExpr *E) {
    Kast::add(Kast::KApply("ConstCast", Sort::RESOLVEDEXPR, {Sort::ATYPE, Sort::EXPR}));
    return false;
  }

  bool TraverseCXXConstructHelper(QualType T, Expr **begin, Expr **end) {
    TRY_TO(TraverseType(T));
    int i = 0;
    for (Expr **iter = begin; iter != end; ++iter) {
      i++;
    }
    KSeqList(i);
    for (Expr **iter = begin; iter != end; ++iter) {
      TRY_TO(TraverseStmt(*iter));
    }
    return true;
  }

  bool TraverseCXXUnresolvedConstructExpr(CXXUnresolvedConstructExpr *E) {
    Kast::add(Kast::KApply("UnresolvedConstructorCall", Sort::EXPR, {Sort::ATYPE, Sort::LIST}));
    return TraverseCXXConstructHelper(E->getTypeAsWritten(), E->arg_begin(), E->arg_end());
  }

  bool TraverseCXXFunctionalCastExpr(CXXFunctionalCastExpr *E) {
    Expr *arg = E->getSubExprAsWritten();
    Kast::add(Kast::KApply("FunctionalCast", Sort::EXPR, {Sort::ATYPE, Sort::LIST}));
    return TraverseCXXConstructHelper(E->getTypeInfoAsWritten()->getType(), &arg, &arg+1);
  }

  bool TraverseCXXScalarValueInitExpr(CXXScalarValueInitExpr *E) {
    Kast::add(Kast::KApply("FunctionalCast", Sort::EXPR, {Sort::ATYPE, Sort::LIST}));
    return TraverseCXXConstructHelper(E->getType(), 0, 0);
  }

  bool TraverseCXXConstructExpr(CXXConstructExpr *E) {
    Kast::add(Kast::KApply("ConstructorCall", Sort::INIT, {Sort::BOOL, Sort::ATYPE, Sort::LIST}));
    VisitBool(E->requiresZeroInitialization());
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool TraverseCXXTemporaryObjectExpr(CXXTemporaryObjectExpr *E) {
    Kast::add(Kast::KApply("TemporaryObjectExpr", Sort::EXPR, {Sort::ATYPE, Sort::LIST}));
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool VisitUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *E) {
    if (E->getKind() == UETT_SizeOf) {
      if (E->isArgumentType()) {
        Kast::add(Kast::KApply("SizeofType", Sort::EXPR, {Sort::ATYPE}));
      } else {
        Kast::add(Kast::KApply("SizeofExpr", Sort::EXPR, {Sort::EXPR}));
      }
    } else if (E->getKind() == UETT_AlignOf) {
      if (E->isArgumentType()) {
        Kast::add(Kast::KApply("AlignofType", Sort::EXPR, {Sort::ATYPE}));
      } else {
        Kast::add(Kast::KApply("AlignofExpr", Sort::EXPR, {Sort::EXPR}));
      }
    } else {
      throw std::logic_error("unimplemented: ??? expr or type trait");
    }
    return false;
  }

  bool VisitSizeOfPackExpr(SizeOfPackExpr *E) {
    Kast::add(Kast::KApply("SizeofPack", Sort::EXPR, {Sort::CID}));
    TRY_TO(TraverseDeclarationName(E->getPack()->getDeclName()));
    return false;
  }

  bool TraverseCXXPseudoDestructorExpr(CXXPseudoDestructorExpr *E) {
    Kast::add(Kast::KApply("PseudoDestructor", Sort::EXPR, {Sort::EXPR, Sort::BOOL, Sort::NNS, Sort::ATYPE, Sort::ATYPE}));
    TRY_TO(TraverseStmt(E->getBase()));
    VisitBool(E->isArrow());
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    if (TypeSourceInfo *ScopeInfo = E->getScopeTypeInfo()) {
      TRY_TO(TraverseTypeLoc(ScopeInfo->getTypeLoc()));
    } else {
      NoType();
    }
    if (TypeSourceInfo *DestroyedTypeInfo = E->getDestroyedTypeInfo()) {
      TRY_TO(TraverseTypeLoc(DestroyedTypeInfo->getTypeLoc()));
    } else {
      NoType();
    }
    return true;
  }

  bool VisitCXXNoexceptExpr(CXXNoexceptExpr *E) {
    Kast::add(Kast::KApply("Noexcept", Sort::EXPR, {Sort::EXPR}));
    return false;
  }

  bool TraverseCXXNewExpr(CXXNewExpr *E) {
    Kast::add(Kast::KApply("NewExpr", Sort::EXPR, {Sort::BOOL, Sort::ATYPE, Sort::AEXPR, Sort::INIT, Sort::LIST}));
    VisitBool(E->isGlobalNew());
    TRY_TO(TraverseType(E->getAllocatedType()));
    if (E->isArray()) {
      TRY_TO(TraverseStmt(E->getArraySize()));
    } else {
      NoExpression();
    }
    if (E->hasInitializer()) {
      TRY_TO(TraverseStmt(E->getInitializer()));
    } else {
      Kast::add(Kast::KApply("NoInit", Sort::INIT));
    }
    KSeqList(E->getNumPlacementArgs());
    for (unsigned i = 0; i < E->getNumPlacementArgs(); i++) {
      TRY_TO(TraverseStmt(E->getPlacementArg(i)));
    }
    return true;
  }

  bool VisitCXXDeleteExpr(CXXDeleteExpr *E) {
    Kast::add(Kast::KApply("DeleteExpr", Sort::EXPR, {Sort::BOOL, Sort::BOOL, Sort::EXPR}));
    VisitBool(E->isGlobalDelete());
    VisitBool(E->isArrayFormAsWritten());
    return false;
  }

  bool VisitCXXThisExpr(CXXThisExpr *E) {
    Kast::add(Kast::KApply("This", Sort::THIS));
    return false;
  }

  bool VisitCXXThrowExpr(CXXThrowExpr *E) {
    Kast::add(Kast::KApply("Throw", Sort::EXPR, {Sort::AEXPR}));
    if (!E->getSubExpr()) {
      NoExpression();
    }
    return false;
  }

  bool TraverseLambdaCapture(LambdaExpr *E, const LambdaCapture *C, Expr*) {
    Kast::add(Kast::KApply("LambdaCapture", Sort::CAPTURE, {Sort::CAPTUREKIND, Sort::BOOL}));
    switch (C->getCaptureKind()) {
      case LCK_This:
        Kast::add(Kast::KApply("This", Sort::THIS));
        break;
      case LCK_ByRef:
        Kast::add(Kast::KApply("RefCapture", Sort::CAPTUREKIND, {Sort::DECL}));
        // fall through
      case LCK_ByCopy:
        break;
      default:
        throw std::logic_error("unimplemented: capture kind");
    }
    if (C->capturesVariable()) {
      TRY_TO(TraverseDecl(C->getCapturedVar()));
    }
    VisitBool(C->isPackExpansion());
    return true;
  }

  bool TraverseLambdaExpr(LambdaExpr *E) {
    Kast::add(Kast::KApply("Lambda", Sort::EXPR, {Sort::CAPTUREDEFAULT, Sort::LIST, Sort::ATYPE, Sort::ASTMT}));
    switch (E->getCaptureDefault()) {
      case LCD_None:
        Kast::add(Kast::KApply("NoCaptureDefault", Sort::CAPTUREDEFAULT));
        break;
      case LCD_ByCopy:
        Kast::add(Kast::KApply("CopyCapture", Sort::CAPTUREDEFAULT));
        break;
      case LCD_ByRef:
        Kast::add(Kast::KApply("RefCapture", Sort::CAPTUREDEFAULT));
        break;
    }
    int i = 0;
    for (LambdaExpr::capture_iterator C = E->explicit_capture_begin(),
                                      CEnd = E->explicit_capture_end();
         C != CEnd; ++C) {
      if (C->isExplicit()) {
        i++;
      }
    }
    KSeqList(i);
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
    Kast::add(Kast::KApply("PackExpansionExpr", Sort::EXPR, {Sort::EXPR}));
    return false;
  }

  void VisitStringRef(StringRef str) {
    Kast::add(Kast::KToken(str.str()));
  }

  void VisitAPInt(llvm::APInt i) {
    Kast::add(Kast::KToken(i));
  }

  void VisitUnsigned(unsigned long long i) {
    Kast::add(Kast::KToken(i));
  }

  void VisitAPFloat(llvm::APFloat f) {
    if (!f.isFinite()) {
      throw std::logic_error("unimplemented: special floats");
    }
    Kast::add(Kast::KToken(f));
  }

  bool VisitStringLiteral(StringLiteral *Constant) {
    Kast::add(Kast::KApply("StringLiteral", Sort::EXPR, {Sort::CHARKIND, Sort::STRING}));
    switch (Constant->getKind()) {
      case StringLiteral::Ascii:
        Kast::add(Kast::KApply("Ascii", Sort::CHARKIND));
        break;
      case StringLiteral::Wide:
        Kast::add(Kast::KApply("Wide", Sort::CHARKIND));
        break;
      case StringLiteral::UTF8:
        Kast::add(Kast::KApply("UTF8", Sort::CHARKIND));
        break;
      case StringLiteral::UTF16:
        Kast::add(Kast::KApply("UTF16", Sort::CHARKIND));
        break;
      case StringLiteral::UTF32:
        Kast::add(Kast::KApply("UTF32", Sort::CHARKIND));
        break;
    }
    StringRef str = Constant->getBytes();
    VisitStringRef(str);
    return false;
  }

  bool VisitCharacterLiteral(CharacterLiteral *Constant) {
    Kast::add(Kast::KApply("CharacterLiteral", Sort::EXPR, {Sort::CHARKIND, Sort::INT}));
    switch (Constant->getKind()) {
      case CharacterLiteral::Ascii:
        Kast::add(Kast::KApply("Ascii", Sort::CHARKIND));
        break;
      case CharacterLiteral::Wide:
        Kast::add(Kast::KApply("Wide", Sort::CHARKIND));
        break;
      case CharacterLiteral::UTF8:
        Kast::add(Kast::KApply("UTF8", Sort::CHARKIND));
        break;
      case CharacterLiteral::UTF16:
        Kast::add(Kast::KApply("UTF16", Sort::CHARKIND));
        break;
      case CharacterLiteral::UTF32:
        Kast::add(Kast::KApply("UTF32", Sort::CHARKIND));
        break;
    }
    Kast::add(Kast::KToken(Constant->getValue()));
    return false;
  }

  bool TraverseIntegerLiteral(IntegerLiteral *Constant) {
    Kast::add(Kast::KApply("IntegerLiteral", Sort::EXPR, {Sort::INT, Sort::ATYPE}));
    VisitAPInt(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool TraverseFloatingLiteral(FloatingLiteral *Constant) {
    Kast::add(Kast::KApply("FloatingLiteral", Sort::EXPR, {Sort::FLOAT, Sort::ATYPE}));
    VisitAPFloat(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool VisitCXXNullPtrLiteralExpr(CXXNullPtrLiteralExpr *Constant) {
    Kast::add(Kast::KApply("NullPointerLiteral", Sort::EXPR));
    return false;
  }

  bool VisitCXXBoolLiteralExpr(CXXBoolLiteralExpr *Constant) {
    Kast::add(Kast::KApply("BoolLiteral", Sort::EXPR, {Sort::BOOL}));
    VisitBool(Constant->getValue());
    return false;
  }

  bool TraverseInitListExpr(InitListExpr *E) {
    InitListExpr *Syntactic = E->isSemanticForm() ? E->getSyntacticForm() ? E->getSyntacticForm() : E : E;
    Kast::add(Kast::KApply("BraceInit", Sort::BRACEINIT, {Sort::LIST}));
    KSeqList(Syntactic->getNumInits());
    for (Stmt *SubStmt : Syntactic->children()) {
      TRY_TO(TraverseStmt(SubStmt));
    }
    return true;
  }

  bool VisitImplicitValueInitExpr(ImplicitValueInitExpr *E) {
    Kast::add(Kast::KApply("ExpressionList", Sort::EXPRESSIONLIST, {Sort::LIST}));
    KSeqList(0);
    return false;
  }

  bool VisitTypeTraitExpr(TypeTraitExpr *E) {
    Kast::add(Kast::KApply("GnuTypeTrait", Sort::EXPR, {Sort::STRING, Sort::LIST}));
    switch (E->getTrait()) {
      #define TRAIT(Name, Str)                    \
        case Name:                                \
          Kast::add(Kast::KToken((std::string)Str)); \
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
      #undef TRAIT
      default:
        throw std::logic_error("unimplemented: type trait");
    }
    KSeqList(E->getNumArgs());
    return false;
  }

  bool VisitAtomicExpr(AtomicExpr *E) {
    Kast::add(Kast::KApply("GnuAtomicExpr", Sort::EXPR, {Sort::STRING, Sort::LIST}));
    switch (E->getOp()) {
      #define ATOMIC_BUILTIN(Name, Spelling)           \
        case AtomicExpr::AO##Name:                     \
          Kast::add(Kast::KToken((std::string)Spelling)); \
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
      default:
        throw std::logic_error("unimplemented: atomic builtin");
    }
    KSeqList(E->getNumSubExprs());
    return false;
  }

  bool VisitPredefinedExpr(PredefinedExpr *E) {
    return false;
  }

  // the rest of these are not part of the syntax of C but we keep them and transform them later
  // in order to avoid having to deal with messy syntax transformations within the parser
  bool VisitMaterializeTemporaryExpr(MaterializeTemporaryExpr *E) {
    Kast::add(Kast::KApply("MaterializeTemporaryExpr", Sort::EXPR, {Sort::EXPR}));
    return false;
  }

  bool VisitParenListExpr(ParenListExpr *E) {
    Kast::add(Kast::KApply("ParenList", Sort::EXPR, {Sort::LIST}));
    KSeqList(E->getNumExprs());
    return false;
  }

  bool VisitCXXDefaultArgExpr(CXXDefaultArgExpr *E) {
    Kast::add(Kast::KSequence(0));
    return false;
  }

private:
  ASTContext * Context;
  const std::string InFile;

  void NoNNS() {
    Kast::add(Kast::KApply("NoNNS", Sort::NNS));
  }

  void NoType() {
    Kast::add(Kast::KApply("NoType", Sort::ATYPERESULT));
  }

  void NoExpression() {
    Kast::add(Kast::KApply("NoExpression", Sort::AEXPR));
  }

  void NoStatement() {
    Kast::add(Kast::KApply("NoStatement", Sort::ASTMT));
  }

  void List(int n) {
    Kast::add(Kast::KApply("list", Sort::STRICTLIST, {Sort::LIST}));
    KSeqList(n);
  }

  void KSeqList(int n) {
    Kast::add(Kast::KApply("kSeqToList", Sort::LIST, {Sort::K}));
    Kast::add(Kast::KSequence(n));
  }

  void Name() {
    Kast::add(Kast::KApply("Name", Sort::NAME, {Sort::NNS, Sort::CID}));
  }

  void UnaryOperator() {
    Kast::add(Kast::KApply("UnaryOperator", Sort::EXPR, {Sort::OPID, Sort::EXPR}));
  }

  void BinaryOperator() {
    Kast::add(Kast::KApply("BinaryOperator", Sort::EXPR, {Sort::OPID, Sort::EXPR, Sort::INIT}));
  }

  void Specifier() {
    Kast::add(Kast::KApply("Specifier", Sort::DECL, {Sort::SPECIFIER, Sort::DECL}));
  }

  void Specifier(const char *str, Sort sort) {
    Specifier();
    Kast::add(Kast::KApply(str, sort));
  }

  void AlignasSpecifier(unsigned long long n) {
    Specifier();
    Kast::add(Kast::KApply("Alignas", Sort::SPECIFIER, {Sort::INT}));
    Kast::add(Kast::KToken(n));
  }

  void CabsLoc(SourceLocation loc) {
    SourceManager &mgr = Context->getSourceManager();
    PresumedLoc presumed = mgr.getPresumedLoc(loc);
    if (presumed.isValid()) {
      Kast::add(Kast::KApply("CabsLoc", Sort::CABSLOC, {Sort::STRING, Sort::STRING, Sort::INT, Sort::INT, Sort::BOOL}));
      Kast::add(Kast::KToken((std::string)presumed.getFilename()));
      StringRef filename(presumed.getFilename());
      SmallString<64> vector(filename);
      llvm::sys::fs::make_absolute(vector);
      Kast::add(Kast::KToken(vector.str().str()));
      VisitUnsigned(presumed.getLine());
      VisitUnsigned(presumed.getColumn());
      VisitBool(mgr.isInSystemHeader(loc));
    } else {
      Kast::add(Kast::KApply("UnknownCabsLoc_COMMON-SYNTAX_CabsLoc", Sort::CABSLOC));
    }
  }

  bool excludedDecl(clang::Decl const *d) const {
    return d->isImplicit() && d->isDefinedOutsideFunctionOrMethod();
  }

  void DeclContext(DeclContext *D) {
    int i = 0;
    for (const clang::Decl * d : D->decls()) {
      if (!excludedDecl(d)) i++;
    }
    KSeqList(i);
  }

  void StmtChildren(Stmt *S) {
    int i = 0;
    for (Stmt::child_iterator iter = S->child_begin(), end = S->child_end(); iter != end; ++i, ++iter);
    KSeqList(i);
  }

  void StorageClass(StorageClass sc) {
    const char *spec;
    switch (sc) {
      case StorageClass::SC_None:
        return;
      case StorageClass::SC_Extern:
        Specifier("Extern", Sort::STORAGECLASSSPECIFIER);
        break;
      case StorageClass::SC_Static:
        Specifier("Static", Sort::STORAGECLASSSPECIFIER);
        break;
      case StorageClass::SC_Register:
        Specifier("Register", Sort::STORAGECLASSSPECIFIER);
        break;
      case StorageClass::SC_Auto:
        Specifier("Auto", Sort::AUTOSPECIFIER);
        break;
      default:
        throw std::logic_error("unimplemented: storage class");
    }
  }

  void ThreadStorageClass(ThreadStorageClassSpecifier sc) {
    const char *spec;
    switch (sc) {
      case ThreadStorageClassSpecifier::TSCS_unspecified:
        return;
      case ThreadStorageClassSpecifier::TSCS_thread_local:
        Specifier("ThreadLocal", Sort::STORAGECLASSSPECIFIER);
        break;
      default:
        throw std::logic_error("unimplemented: thread storage class");
    }
  }

  void Identifier(const std::string & id) {
    Kast::add(Kast::KApply("Identifier", Sort::CID, {Sort::STRING}));
    Kast::add(Kast::KToken(id));
  }

  void Qualifier(const char * str) {
    Kast::add(Kast::KApply("Qualifier", Sort::ATYPE, {Sort::QUALIFIER, Sort::ATYPE}));
    Kast::add(Kast::KApply(str, Sort::QUALIFIER));
  }

  void Qualifiers(QualType T) {
    if (T.isLocalConstQualified()) Qualifier("Const");
    if (T.isLocalVolatileQualified()) Qualifier("Volatile");
    if (T.isLocalRestrictQualified()) Qualifier("Restrict");
  }

  void mangledIdentifier(NamedDecl * D) {
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
    Identifier(s.str());
    delete mangler;
  }
};

#endif
