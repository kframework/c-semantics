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

  explicit GetKastVisitor(KastNodes & Kast, ASTContext *Context, const llvm::StringRef InFile)
    : Kast(Kast), Context(Context), InFile(InFile) { }

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
        Kast.KApply("ExprLoc", 2);
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

    Kast.KApply("DeclLoc", 2);
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
    for (DeclContext::decl_iterator iter = D->decls_begin(), end = D->decls_end(); iter != end; ++iter) {
      clang::Decl *d = *iter;
      if (!excludedDecl(d)) {
        TRY_TO(TraverseDecl(d));
      }
    }
    return true;
  }

  bool VisitTranslationUnitDecl(TranslationUnitDecl *D) {
    Kast.KApply("TranslationUnit", 2);
    VisitStringRef(InFile);
    DeclContext(D);
    return false;
  }

  bool VisitTypedefDecl(TypedefDecl *D) {
    Kast.KApply("TypedefDecl", 2);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }

  bool VisitTypeAliasDecl(TypeAliasDecl *D) {
    Kast.KApply("TypeAliasDecl", 2);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    return false;
  }


  bool VisitLinkageSpecDecl(LinkageSpecDecl *D) {
    Kast.KApply("LinkageSpec", 3);
    const char *s;
    if (D->getLanguage() == LinkageSpecDecl::lang_c) {
      s = "C";
    } else if (D->getLanguage() == LinkageSpecDecl::lang_cxx) {
      s = "C++";
    }
    Kast.KToken(s);
    VisitBool(D->hasBraces());
    DeclContext(D);
    return false;
  }

  void VisitBool(bool b) {
    Kast.KToken(b);
  }

  bool VisitNamespaceDecl(NamespaceDecl *D) {
    Kast.KApply("NamespaceDecl", 3);
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    VisitBool(D->isInline());
    DeclContext(D);
    return false;
  }

  bool VisitNamespaceAliasDecl(NamespaceAliasDecl *D) {
    Kast.KApply("NamespaceAliasDecl", 3);
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
      Kast.KApply("NoNNS", 0);
      return true;
    }
    if (NNS->getPrefix()) {
      Kast.KApply("NestedName", 2);
      TRY_TO(TraverseNestedNameSpecifier(NNS->getPrefix()));
    }
    switch (NNS->getKind()) {
      case NestedNameSpecifier::Identifier:
        Kast.KApply("NNS", 1);
        TRY_TO(TraverseIdentifierInfo(NNS->getAsIdentifier()));
        break;
      case NestedNameSpecifier::Namespace:
        Kast.KApply("NNS", 1);
        TRY_TO(TraverseDeclarationName(NNS->getAsNamespace()->getDeclName()));
        break;
      case NestedNameSpecifier::NamespaceAlias:
        Kast.KApply("NNS", 1);
        TRY_TO(TraverseDeclarationName(NNS->getAsNamespaceAlias()->getDeclName()));
        break;
      case NestedNameSpecifier::TypeSpec:
        Kast.KApply("NNS", 1);
        TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
        break;
      case NestedNameSpecifier::TypeSpecWithTemplate:
        Kast.KApply("TemplateNNS", 1);
        TRY_TO(TraverseType(QualType(NNS->getAsType(), 0)));
        break;
      case NestedNameSpecifier::Global:
        Kast.KApply("GlobalNamespace", 0);
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
        Kast.KApply("#NoName_COMMON-SYNTAX", 0);
      } else {
        Kast.KApply("unnamed", 2);
        VisitUnsigned((unsigned long long)decl);
        VisitStringRef(InFile);
      }
      return true;
    }
    Kast.KApply("Identifier", 1);
    Kast.KToken(info->getNameStart(), info->getLength());
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
          Kast.KApply("TypeId", 1);
          TRY_TO(TraverseType(Name.getCXXNameType()));
          return true;
        }
      case DeclarationName::CXXDestructorName:
        {
          Kast.KApply("DestructorTypeId", 1);
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
      Kast.KApply("ConstructorBase", 4);
      TRY_TO(TraverseTypeLoc(Init->getTypeSourceInfo()->getTypeLoc()));
      VisitBool(Init->isBaseVirtual());
      VisitBool(Init->isPackExpansion());
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isMemberInitializer()) {
      Kast.KApply("ConstructorMember", 2);
      TRY_TO(TraverseDeclarationName(Init->getMember()->getDeclName()));
      TRY_TO(TraverseStmt(Init->getInit()));
    } else if (Init->isDelegatingInitializer()) {
      Kast.KApply("ConstructorDelegating", 1);
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
          Kast.KApply("TemplateSpecialization", 2);
          Kast.KApply("TemplateSpecializationType", 2);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          Kast.List(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          Kast.KApply("TemplateSpecialization", 2);
          Kast.KApply("TemplateSpecializationType", 1);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      } else if (FTSI->getTemplateSpecializationKind() != TSK_Undeclared &&
          FTSI->getTemplateSpecializationKind() != TSK_ImplicitInstantiation) {
        if (const ASTTemplateArgumentListInfo *TALI =
                FTSI->TemplateArgumentsAsWritten) {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             Kast.KApply("TemplateInstantiationDefinition", 2);
          } else {
             Kast.KApply("TemplateInstantiationDeclaration", 2);
          }
          Kast.KApply("TemplateSpecializationType", 2);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
          Kast.List(TALI->NumTemplateArgs);
          TRY_TO(TraverseTemplateArgumentLocs(TALI->getTemplateArgs(),
                                                    TALI->NumTemplateArgs));
        } else {
          if (FTSI->getTemplateSpecializationKind() == TSK_ExplicitInstantiationDefinition) {
             Kast.KApply("TemplateInstantiationDefinition", 2);
          } else {
             Kast.KApply("TemplateInstantiationDeclaration", 2);
          }
          Kast.KApply("TemplateSpecializationType", 1);
          TRY_TO(TraverseDeclarationName(FTSI->getTemplate()->getDeclName()));
        }
      }
    }

    StorageClass(D->getStorageClass());
    if (D->isInlineSpecified()) {
      Specifier("Inline");
    }
    if (D->isConstexpr()) {
      Specifier("Constexpr");
    }

    if (D->isThisDeclarationADefinition() || D->isExplicitlyDefaulted()) {
      Kast.KApply("FunctionDefinition", 6);
    } else {
      Kast.KApply("FunctionDecl", 5);
    }

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(D->getNameInfo()));

    mangledIdentifier(D);

    if (TypeSourceInfo *TSI = D->getTypeSourceInfo()) {
      if (CXXMethodDecl *Method = dyn_cast<CXXMethodDecl>(D)) {
        if (Method->isInstance()) {
          switch(Method->getRefQualifier()) {
            case RQ_LValue:
              Kast.KApply("RefQualifier",2);
              Kast.KApply("RefLValue", 0);
              break;
            case RQ_RValue:
              Kast.KApply("RefQualifier",2);
              Kast.KApply("RefRValue", 0);
              break;
            case RQ_None: // do nothing
              break;
          }
          Kast.KApply("MethodPrototype", 4);
          VisitBool(Method->isUserProvided());
          VisitBool(dyn_cast<CXXConstructorDecl>(D)); // converts to true if this is a constructor
          TRY_TO(TraverseType(Method->getThisType(*Context)));
          if (Method->isVirtual()) {
            Kast.KApply("Virtual", 1);
          }
          if (Method->isPure()) {
            Kast.KApply("Pure", 1);
          }

          if (CXXConversionDecl *Conv = dyn_cast<CXXConversionDecl>(D)) {
            if (Conv->isExplicitSpecified()) {
              Kast.KApply("Explicit", 1);
            }
          }

          if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
            if (Ctor->isExplicitSpecified()) {
              Kast.KApply("Explicit", 1);
            }
          }
        } else {
          Kast.KApply("StaticMethodPrototype", 1);
        }
      }
      TRY_TO(TraverseType(D->getType()));
    } else {
      throw std::logic_error("something implicit in functions??");
    }

    Kast.List(D->parameters().size());
    for (unsigned i = 0; i < D->parameters().size(); i++) {
      TRY_TO(TraverseDecl(D->parameters()[i]));
    }

    if (D->isThisDeclarationADefinition()) {
      if (CXXConstructorDecl *Ctor = dyn_cast<CXXConstructorDecl>(D)) {
        Kast.KApply("Constructor", 2);
        int i = 0;
        for (auto *I : Ctor->inits()) {
          if(I->isWritten()) {
            i++;
          }
        }
        Kast.List(i);
        for (auto *I : Ctor->inits()) {
          if(I->isWritten()) {
            TRY_TO(TraverseConstructorInitializer(I));
          }
        }
      }
      TRY_TO(TraverseStmt(D->getBody()));
    }
    if (D->isExplicitlyDefaulted()) {
      Kast.KApply("Defaulted", 0);
    } else if (D->isDeleted()) {
      Kast.KApply("Deleted", 0);
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
      Specifier("Constexpr");
    }
    if (unsigned align = D->getMaxAlignment()) {
      Specifier("Alignas", align / 8);
    }
    Kast.KApply("VarDecl", 6);

    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));

    mangledIdentifier(D);

    TRY_TO(TraverseType(D->getType()));
    if (D->getInit()) {
      TRY_TO(TraverseStmt(D->getInit()));
    } else {
      Kast.KApply("NoInit", 0);
    }
    VisitBool(D->isDirectInit());
    return true;
  }

  bool TraverseVarDecl(VarDecl *D) {
    return TraverseVarHelper(D);
  }

  bool TraverseFieldDecl(FieldDecl *D) {
    if (D->isMutable()) {
      Specifier("Mutable");
    }
    if (D->isBitField()) {
      Kast.KApply("BitFieldDecl", 4);
    } else {
      Kast.KApply("FieldDecl", 4);
    }
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if (D->isBitField()) {
      TRY_TO(TraverseStmt(D->getBitWidth()));
    } else if (D->hasInClassInitializer()) {
      TRY_TO(TraverseStmt(D->getInClassInitializer()));
    } else {
      Kast.KApply("NoInit", 0);
    }
    return true;
  }

  bool TraverseParmVarDecl(ParmVarDecl *D) {
    //TODO(other stuff)
    return TraverseVarHelper(D);
  }

  bool VisitFriendDecl(FriendDecl *D) {
    Kast.KApply("FriendDecl", 1);
    return false;
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
    Kast.KApply(spec, 0);
  }

  #define TRAVERSE_TEMPLATE_DECL(DeclKind) \
  bool Traverse##DeclKind##TemplateDecl(DeclKind##TemplateDecl *D) { \
    Kast.KApply("TemplateWithInstantiations", 3); \
    TRY_TO(TraverseDecl(D->getTemplatedDecl())); \
    TemplateParameterList *TPL = D->getTemplateParameters(); \
    if (TPL) { \
      int i = 0; \
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++i, ++I); \
      Kast.List(i); \
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
    Kast.List(i);
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
    Kast.List(0);
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
    Kast.List(i);
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
    Kast.List(i);
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
    Kast.KApply("TypeTemplateParam", 4);
    VisitBool(D->wasDeclaredWithTypename());
    VisitBool(D->isParameterPack());
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      Kast.KApply("NoType", 0);
    }
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseType(D->getDefaultArgumentInfo()->getType()));
    } else {
      Kast.KApply("NoType", 0);
    }
    return true;
  }

  bool TraverseNonTypeTemplateParmDecl(NonTypeTemplateParmDecl *D) {
    Kast.KApply("ValueTemplateParam", 5);
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    TRY_TO(TraverseType(D->getType()));
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseStmt(D->getDefaultArgument()));
    } else {
      Kast.KApply("NoExpression", 0);
    }
    return true;
  }

  bool TraverseTemplateTemplateParmDecl(TemplateTemplateParmDecl *D) {
    Kast.KApply("TemplateTemplateParam", 4);
    VisitBool(D->isParameterPack());
    TRY_TO(TraverseDeclarationName(D->getDeclName()));
    if(D->hasDefaultArgument() && !D->defaultArgumentWasInherited()) {
      TRY_TO(TraverseTemplateArgumentLoc(D->getDefaultArgument()));
    } else {
      Kast.KApply("NoType", 0);
    }
    TemplateParameterList *TPL = D->getTemplateParameters();
    if (TPL) {
      int i = 0;
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++i, ++I);
      Kast.List(i);
      for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end(); I != E; ++I) {
        TRY_TO(TraverseDecl(*I));
      }
    }
    return true;

  }

  bool TraverseTemplateArgument(const TemplateArgument &Arg) {
    switch(Arg.getKind()) {
      case TemplateArgument::Type:
        Kast.KApply("TypeArg", 1);
        return getDerived().TraverseType(Arg.getAsType());
      case TemplateArgument::Template:
        Kast.KApply("TemplateArg", 1);
        return getDerived().TraverseTemplateName(Arg.getAsTemplate());
      case TemplateArgument::Expression:
        Kast.KApply("ExprArg", 1);
        return getDerived().TraverseStmt(Arg.getAsExpr());
      case TemplateArgument::Integral:
        Kast.KApply("ExprArg", 1);
        Kast.KApply("IntegerLiteral", 2);
        VisitAPInt(Arg.getAsIntegral());
        return getDerived().TraverseType(Arg.getIntegralType());
      case TemplateArgument::Pack:
        Kast.KApply("PackArg", 1);
        Kast.List(Arg.pack_size());
        for (const TemplateArgument arg : Arg.pack_elements()) {
          TRY_TO(TraverseTemplateArgument(arg));
        }
        return true;
      default:
        throw std::logic_error("unimplemented: template argument");
    }
  }

  bool TraverseTemplateName(TemplateName Name) {
    switch(Name.getKind()) {
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
    for (unsigned I = 0; I < Count; ++I) {
      TRY_TO(TraverseTemplateArgumentLoc(TAL[I]));
    }
    return true;
  }

  void VisitTagKind(TagTypeKind T) {
    switch (T) {
      case TTK_Struct:
        Kast.KApply("Struct", 0);
        break;
      case TTK_Union:
        Kast.KApply("Union", 0);
        break;
      case TTK_Class:
        Kast.KApply("Class", 0);
        break;
      case TTK_Enum:
        Kast.KApply("Enum", 0);
        break;
      default:
        throw std::logic_error("unimplemented: tag kind");
    }
  }

  bool TraverseCXXRecordHelper(CXXRecordDecl *D) {
    if (D->isCompleteDefinition()) {
      Kast.KApply("ClassDef", 6);
    } else {
      Kast.KApply("TypeDecl", 1);
      Kast.KApply("ElaboratedTypeSpecifier", 3);
    }
    VisitTagKind(D->getTagKind());
    TRY_TO(TraverseDeclarationAsName(D));
    TRY_TO(TraverseNestedNameSpecifierLoc(D->getQualifierLoc()));
    if (D->isCompleteDefinition()) {
      int i = 0;
      for (const auto &I : D->bases()) {
        i++;
      }
      Kast.List(i);
      for (const auto &I : D->bases()) {
        Kast.KApply("BaseClass", 4);
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
      Kast.KApply("OpaqueEnumDeclaration", 3);
      TRY_TO(TraverseDeclarationName(D->getDeclName()));
      VisitBool(D->isScoped());
      TraverseType(D->getIntegerType());
      return true;
    }

    Kast.KApply("EnumDef", 6);
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
    Kast.KApply("Enumerator", 2);
    TraverseDeclarationName(D->getDeclName());
    if (!D->getInitExpr()) {
      Kast.KApply("NoExpression", 0);
    }
    return false;
  }

  bool TraverseClassTemplateSpecializationDecl(ClassTemplateSpecializationDecl *D) {
    switch(D->getSpecializationKind()) {
      case TSK_ExplicitSpecialization:
        Kast.KApply("TemplateSpecialization", 2);
        break;
      case TSK_ExplicitInstantiationDeclaration:
        Kast.KApply("TemplateInstantiationDeclaration", 2);
        break;
      case TSK_ImplicitInstantiation:
      case TSK_ExplicitInstantiationDefinition:
        Kast.KApply("TemplateInstantiationDefinition", 2);
        break;
      default:
        throw std::logic_error("unimplemented: implicit template instantiation");
    }
    if (D->getTypeForDecl()) {
      TRY_TO(TraverseType(QualType(D->getTypeForDecl(), 0)));
    } else {
      Kast.KApply("NoType", 0);
    }
    TRY_TO(TraverseCXXRecordHelper(D));
    return true;
  }

  bool TraverseClassTemplatePartialSpecializationDecl(ClassTemplatePartialSpecializationDecl *D) {
    Kast.KApply("PartialSpecialization", 3);
    /* The partial specialization. */
    int i = 0;
    TemplateParameterList *TPL = D->getTemplateParameters();
    for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end();
         I != E; ++I) {
      i++;
    }
    Kast.List(i);
    for (TemplateParameterList::iterator I = TPL->begin(), E = TPL->end();
         I != E; ++I) {
      TRY_TO(TraverseDecl(*I));
    }
    Kast.List(D->getTemplateArgsAsWritten()->NumTemplateArgs);
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
    Kast.KApply("AccessSpec", 1);
    VisitAccessSpecifier(D->getAccess());
    return false;
  }

  bool VisitStaticAssertDecl(StaticAssertDecl *D) {
    Kast.KApply("StaticAssert", 2);
    return false;
  }

  bool VisitUsingDecl(UsingDecl *D) {
    Kast.KApply("UsingDecl", 3);
    VisitBool(D->hasTypename());
    return false;
  }

  bool VisitUnresolvedUsingValueDecl(UnresolvedUsingValueDecl *D) {
    Kast.KApply("UsingDecl", 3);
    VisitBool(false);
    return false;
  }

  bool VisitUsingDirectiveDecl(UsingDirectiveDecl *D) {
    Kast.KApply("UsingDirective", 2);
    TRY_TO(TraverseDeclarationName(D->getNominatedNamespaceAsWritten()->getDeclName()));
    return false;
  }

  bool TraverseFunctionProtoType(FunctionProtoType *T) {
    Kast.KApply("FunctionPrototype", 4);

    TRY_TO(TraverseType(T->getReturnType()));

    Kast.KApply("list", 1);
    Kast.List(T->getNumParams());
    for(unsigned i = 0; i < T->getNumParams(); i++) {
      TRY_TO(TraverseType(T->getParamType(i)));
    }

    switch(T->getExceptionSpecType()) {
      case EST_None:
        Kast.KApply("NoExceptionSpec", 0);
        break;
      case EST_BasicNoexcept:
        Kast.KApply("NoexceptSpec", 1);
        Kast.KApply("NoExpression", 0);
        break;
      case EST_ComputedNoexcept:
        Kast.KApply("NoexceptSpec", 1);
        TRY_TO(TraverseStmt(T->getNoexceptExpr()));
        break;
      case EST_DynamicNone:
        Kast.KApply("ThrowSpec", 1);
        Kast.KApply("list", 1);
        Kast.List(0);
        break;
      case EST_Dynamic:
        Kast.KApply("ThrowSpec", 1);
        Kast.KApply("list", 1);
        Kast.List(T->getNumExceptions());
        for(unsigned i = 0; i < T->getNumExceptions(); i++) {
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
    Kast.KApply("BuiltinType", 1);
    switch(T->getKind()) {
      case BuiltinType::Void:
        Kast.KApply("Void", 0);
        break;
      case BuiltinType::Char_S:
      case BuiltinType::Char_U:
        Kast.KApply("Char", 0);
        break;
      case BuiltinType::WChar_S:
      case BuiltinType::WChar_U:
        Kast.KApply("WChar", 0);
        break;
      case BuiltinType::Char16:
        Kast.KApply("Char16", 0);
        break;
      case BuiltinType::Char32:
        Kast.KApply("Char32", 0);
        break;
      case BuiltinType::Bool:
        Kast.KApply("Bool", 0);
        break;
      case BuiltinType::UChar:
        Kast.KApply("UChar", 0);
        break;
      case BuiltinType::UShort:
        Kast.KApply("UShort", 0);
        break;
      case BuiltinType::UInt:
        Kast.KApply("UInt", 0);
        break;
      case BuiltinType::ULong:
        Kast.KApply("ULong", 0);
        break;
      case BuiltinType::ULongLong:
        Kast.KApply("ULongLong", 0);
        break;
      case BuiltinType::SChar:
        Kast.KApply("SChar", 0);
        break;
      case BuiltinType::Short:
        Kast.KApply("Short", 0);
        break;
      case BuiltinType::Int:
        Kast.KApply("Int", 0);
        break;
      case BuiltinType::Long:
        Kast.KApply("Long", 0);
        break;
      case BuiltinType::LongLong:
        Kast.KApply("LongLong", 0);
        break;
      case BuiltinType::Float:
        Kast.KApply("Float", 0);
        break;
      case BuiltinType::Double:
        Kast.KApply("Double", 0);
        break;
      case BuiltinType::LongDouble:
        Kast.KApply("LongDouble", 0);
        break;
      case BuiltinType::Int128:
        Kast.KApply("OversizedInt", 0);
        break;
      case BuiltinType::UInt128:
        Kast.KApply("OversizedUInt", 0);
        break;
      case BuiltinType::Dependent:
        Kast.KApply("Dependent", 0);
        break;
      case BuiltinType::NullPtr:
        Kast.KApply("NullPtr", 0);
        break;
      default:
        throw std::logic_error("unimplemented: basic type");
    }
    return false;
  }

  bool VisitPointerType(clang::PointerType *T) {
    Kast.KApply("PointerType", 1);
    return false;
  }

  bool VisitMemberPointerType(MemberPointerType *T) {
    Kast.KApply("MemberPointerType", 2);
    return false;
  }

  bool TraverseArrayHelper(clang::ArrayType *T) {
    if (T->getSizeModifier() != clang::ArrayType::Normal) {
      throw std::logic_error("unimplemented: static/* array");
    }
    Kast.KApply("ArrayType", 2);
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
    Kast.KApply("NoExpression", 0);
    return true;
  }

  bool VisitTypedefType(TypedefType *T) {
    Kast.KApply("TypedefType", 1);
    TRY_TO(TraverseDeclarationName(T->getDecl()->getDeclName()));
    return false;
  }

  void VisitTypeKeyword(ElaboratedTypeKeyword Keyword) {
    switch(Keyword) {
      case ETK_Struct:
        Kast.KApply("Struct", 0);
        break;
      case ETK_Union:
        Kast.KApply("Union", 0);
        break;
      case ETK_Class:
        Kast.KApply("Class", 0);
        break;
      case ETK_Enum:
        Kast.KApply("Enum", 0);
        break;
      case ETK_Typename:
        Kast.KApply("Typename", 0);
        break;
      case ETK_None:
        Kast.KApply("NoTag", 0);
        break;
      default:
        throw std::logic_error("unimplemented: type keyword");
    }
  }

  bool VisitElaboratedType(ElaboratedType *T) {
    Kast.KApply("QualifiedTypeName", 3);
    VisitTypeKeyword(T->getKeyword());
    if(!T->getQualifier()) {
      Kast.KApply("NoNNS", 0);
    }
    return false;
  }

  bool VisitDecltypeType(DecltypeType *T) {
    Kast.KApply("Decltype", 1);
    return false;
  }

  bool VisitTemplateTypeParmType(TemplateTypeParmType *T) {
    Kast.KApply("TemplateParameterType", 1);
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool TraverseSubstTemplateTypeParmType(SubstTemplateTypeParmType *T) {
    TRY_TO(TraverseType(T->getReplacementType()));
    return true;
  }

  bool VisitTagType(TagType *T) {
    TagDecl *D = T->getDecl();
    Kast.KApply("Name", 2);
    Kast.KApply("NoNNS", 0);
    TRY_TO(TraverseDeclarationAsName(D));
    return false;
  }

  bool VisitLValueReferenceType(LValueReferenceType *T) {
    Kast.KApply("LValRefType", 1);
    return false;
  }

  bool VisitRValueReferenceType(RValueReferenceType *T) {
    Kast.KApply("RValRefType", 1);
    return false;
  }

  bool TraverseInjectedClassNameType(InjectedClassNameType *T) {
    TRY_TO(TraverseType(T->getInjectedSpecializationType()));
    return true;
  }

  bool TraverseDependentTemplateSpecializationType(DependentTemplateSpecializationType *T) {
    Kast.KApply("TemplateSpecializationType", 2);
    Kast.KApply("Name", 2);
    TRY_TO(TraverseNestedNameSpecifier(T->getQualifier()));
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    Kast.List(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool TraverseTemplateSpecializationType(const TemplateSpecializationType *T) {
    Kast.KApply("TemplateSpecializationType", 2);
    TRY_TO(TraverseTemplateName(T->getTemplateName()));
    Kast.List(T->getNumArgs());
    TRY_TO(TraverseTemplateArguments(T->getArgs(), T->getNumArgs()));
    return true;
  }

  bool VisitDependentNameType(DependentNameType *T) {
    Kast.KApply("ElaboratedTypeSpecifier", 3);
    VisitTypeKeyword(T->getKeyword());
    TRY_TO(TraverseIdentifierInfo(T->getIdentifier()));
    return false;
  }

  bool VisitPackExpansionType(PackExpansionType *T) {
    Kast.KApply("PackExpansionType", 1);
    return false;
  }

  bool TraverseAutoType(AutoType *T) {
    if (T->isDeduced()) {
      TRY_TO(TraverseType(T->getDeducedType()));
    } else {
      Kast.KApply("AutoType", 1);
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
    Kast.KApply("TypeofExpression", 1);
    return false;
  }

  bool VisitTypeOfType(TypeOfType *T) {
    Kast.KApply("TypeofType", 1);
    return false;
  }

  bool VisitUnaryTransformType(UnaryTransformType *T) {
    if (T->isSugared()) {
      Kast.KApply("GnuEnumUnderlyingType2", 2);
    } else {
      Kast.KApply("GnuEnumUnderlyingType1", 1);
    }
    return false;
  }

  bool TraverseType(QualType T) {
    Qualifiers(T);
    return RecursiveASTVisitor::TraverseType(T);
  }

  bool VisitDeclStmt(DeclStmt *S) {
    Kast.KApply("DeclStmt", 1);
    int i = 0;
    for (auto *I : S->decls()) {
      i++;
    }
    Kast.List(i);
    return false;
  }

  bool VisitBreakStmt(BreakStmt *S) {
    Kast.KApply("TBreakStmt", 0);
    return false;
  }

  bool VisitContinueStmt(ContinueStmt *S) {
    Kast.KApply("ContinueStmt", 0);
    return false;
  }

  bool VisitGotoStmt(GotoStmt *S) {
    Kast.KApply("GotoStmt", 1);
    TRY_TO(TraverseDeclarationName(S->getLabel()->getDeclName()));
    return false;
  }

  bool VisitReturnStmt(ReturnStmt *S) {
    Kast.KApply("ReturnStmt", 1);
    if (!S->getRetValue()) {
      Kast.KApply("NoInit", 0);
    }
    return false;
  }

  bool VisitNullStmt(NullStmt *S) {
    Kast.KApply("NullStmt", 0);
    return false;
  }

  bool VisitCompoundStmt(CompoundStmt *S) {
    Kast.KApply("CompoundAStmt", 1);
    StmtChildren(S);
    return false;
  }

  bool VisitLabelStmt(LabelStmt *S) {
    Kast.KApply("LabelAStmt", 2);
    TRY_TO(TraverseDeclarationName(S->getDecl()->getDeclName()));
    StmtChildren(S);
    return false;
  }

  bool TraverseForStmt(ForStmt *S) {
    Kast.KApply("ForAStmt", 4);
    if (S->getInit()) {
      TRY_TO(TraverseStmt(S->getInit()));
    } else {
      Kast.KApply("NoStatement", 0);
    }
    if (S->getCond()) {
      TRY_TO(TraverseStmt(S->getCond()));
    } else {
      Kast.KApply("NoExpression", 0);
    }
    if (S->getInc()) {
      TRY_TO(TraverseStmt(S->getInc()));
    } else {
      Kast.KApply("NoExpression", 0);
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseWhileStmt(WhileStmt *S) {
    Kast.KApply("WhileAStmt", 2);
    if (S->getConditionVariable()) {
      TRY_TO(TraverseDecl(S->getConditionVariable()));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool VisitDoStmt(DoStmt *S) {
    Kast.KApply("DoWhileAStmt", 2);
    return false;
  }

  bool TraverseIfStmt(IfStmt *S) {
    Kast.KApply("IfAStmt", 3);
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getThen()));
    if(Stmt *Else = S->getElse()) {
      TRY_TO(TraverseStmt(Else));
    } else {
      Kast.KApply("NoStatement", 0);
    }
    return true;
  }

  bool TraverseSwitchStmt(SwitchStmt *S) {
    Kast.KApply("SwitchAStmt", 2);
    if (VarDecl *D = S->getConditionVariable()) {
      TRY_TO(TraverseDecl(D));
    } else {
      TRY_TO(TraverseStmt(S->getCond()));
    }
    TRY_TO(TraverseStmt(S->getBody()));
    return true;
  }

  bool TraverseCaseStmt(CaseStmt *S) {
    Kast.KApply("CaseAStmt", 2);
    if (S->getRHS()) {
      throw std::logic_error("unimplemented: gnu case stmt extensions");
    }
    TRY_TO(TraverseStmt(S->getLHS()));
    TRY_TO(TraverseStmt(S->getSubStmt()));
    return true;
  }

  bool VisitDefaultStmt(DefaultStmt *S) {
    Kast.KApply("DefaultAStmt", 1);
    return false;
  }

  bool TraverseCXXTryStmt(CXXTryStmt *S) {
    Kast.KApply("TryAStmt", 2);
    TRY_TO(TraverseStmt(S->getTryBlock()));
    Kast.List(S->getNumHandlers());
    for (unsigned i = 0; i < S->getNumHandlers(); i++) {
      TRY_TO(TraverseStmt(S->getHandler(i)));
    }
    return true;
  }

  bool VisitCXXCatchStmt(CXXCatchStmt *S) {
    Kast.KApply("CatchAStmt", 2);
    if (!S->getExceptionDecl()) {
      Kast.KApply("Ellipsis", 0);
    }
    return false;
  }

  template<typename ExprType>
  bool TraverseMemberHelper(ExprType *E) {
    if (E->isImplicitAccess()) {
      Kast.KApply("Name", 2);
      TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
      TRY_TO(TraverseDeclarationNameInfo(E->getMemberNameInfo()));
    } else {
      Kast.KApply("MemberExpr", 4);
      VisitBool(E->isArrow());
      VisitBool(E->hasTemplateKeyword());
      Kast.KApply("Name", 2);
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
    Kast.KApply("Subscript", 2);
    return false;
  }

  bool TraverseCXXMemberCallExpr(CXXMemberCallExpr *E) {
    return TraverseCallExpr(E);
  }

  bool TraverseCallExpr(CallExpr *E) {
    Kast.KApply("CallExpr", 3);
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
      if (first) {
        Kast.KApply("list", 1);
        Kast.List(i-1);
      }
      first = false;
    }
    Kast.KApply("krlist", 1);
    Kast.KApply(".List", 0);
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
    Kast.KApply("Name", 2);
    return false;
  }

  bool VisitDependentScopeDeclRefExpr(DependentScopeDeclRefExpr *E) {
    Kast.KApply("Name", 2);
    return false;
  }

  bool TraverseUnresolvedLookupExpr(UnresolvedLookupExpr *E) {
    Kast.KApply("Name", 2);
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    TRY_TO(TraverseDeclarationNameInfo(E->getNameInfo()));
    return true;
  }

  void VisitOperator(OverloadedOperatorKind Kind) {
    switch(Kind) {
      #define OVERLOADED_OPERATOR(Name,Spelling,Token,Unary,Binary,MemberOnly) \
      case OO_##Name:                                                          \
        Kast.KApply("operator" Spelling "_CPP-SYNTAX", 0);                                 \
        break;
      #include "clang/Basic/OperatorKinds.def"
      default:
        throw std::logic_error("unsupported overloaded operator");
    }
  }

  void VisitOperator(UnaryOperatorKind Kind) {
    switch(Kind) {
      #define UNARY_OP(Name, Spelling)         \
      case UO_##Name:                          \
        Kast.KApply("operator" Spelling "_CPP-SYNTAX", 0); \
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
        Kast.KApply("RealOperator", 0);
        break;
      case UO_Imag:
        Kast.KApply("ImagOperator", 0);
        break;
      case UO_Extension:
        Kast.KApply("ExtensionOperator", 0);
        break;
      case UO_Coawait:
        Kast.KApply("CoawaitOperator", 0);
        break;
      default:
        throw std::logic_error("unsupported unary operator");
    }
  }

  void VisitOperator(BinaryOperatorKind Kind) {
    switch(Kind) {
      #define BINARY_OP(Name, Spelling)        \
      case BO_##Name:                          \
        Kast.KApply("operator" Spelling "_CPP-SYNTAX", 0); \
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
    Kast.KApply("UnaryOperator", 2);
    VisitOperator(E->getOpcode());
    return false;
  }


  bool VisitBinaryOperator(BinaryOperator *E) {
    Kast.KApply("BinaryOperator", 3);
    VisitOperator(E->getOpcode());
    return false;
  }

  bool VisitConditionalOperator(ConditionalOperator *E) {
    Kast.KApply("ConditionalOperator", 3);
    return false;
  }

  bool TraverseCXXOperatorCallExpr(CXXOperatorCallExpr *E) {
    switch(E->getOperator()) {
      case OO_Call:
        // TODO(chathhorn)
        Kast.KApply("OverloadedCall", 0);
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
          Kast.KApply("BinaryOperator", 3);
          VisitOperator(E->getOperator());
          TRY_TO(TraverseStmt(E->getArg(0)));
          TRY_TO(TraverseStmt(E->getArg(1)));
          break;
        } else if (E->getNumArgs() == 1) {
          Kast.KApply("UnaryOperator", 2);
          VisitOperator(E->getOperator());
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else {
          throw std::logic_error("unexpected number of arguments to operator");
        }
      case OO_PlusPlus:
        if (E->getNumArgs() == 2) {
          Kast.KApply("UnaryOperator", 2);
          VisitOperator(UO_PostInc);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else if (E->getNumArgs() == 1) {
          Kast.KApply("UnaryOperator", 2);
          VisitOperator(UO_PreInc);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else {
          throw std::logic_error("unexpected number of arguments to operator");
        }
      case OO_MinusMinus:
        if (E->getNumArgs() == 2) {
          Kast.KApply("UnaryOperator", 2);
          VisitOperator(UO_PostDec);
          TRY_TO(TraverseStmt(E->getArg(0)));
          break;
        } else if (E->getNumArgs() == 1) {
          Kast.KApply("UnaryOperator", 2);
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
        Kast.KApply("BinaryOperator", 3);
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
        Kast.KApply("UnaryOperator", 2);
        VisitOperator(E->getOperator());
        TRY_TO(TraverseStmt(E->getArg(0)));
        break;
      default:
        throw std::logic_error("unimplemented: overloaded operator");
    }
    return true;
  }

  bool VisitCStyleCastExpr(CStyleCastExpr *E) {
    Kast.KApply("ParenthesizedCast", 2);
    return false;
  }

  bool VisitCXXReinterpretCastExpr(CXXReinterpretCastExpr *E) {
    Kast.KApply("ReinterpretCast", 2);
    return false;
  }

  bool VisitCXXStaticCastExpr(CXXStaticCastExpr *E) {
    Kast.KApply("StaticCast", 2);
    return false;
  }

  bool VisitCXXDynamicCastExpr(CXXDynamicCastExpr *E) {
    Kast.KApply("DynamicCast", 2);
    return false;
  }

  bool VisitCXXConstCastExpr(CXXConstCastExpr *E) {
    Kast.KApply("ConstCast", 2);
    return false;
  }

  bool TraverseCXXConstructHelper(QualType T, Expr **begin, Expr **end) {
    TRY_TO(TraverseType(T));
    int i = 0;
    for (Expr **iter = begin; iter != end; ++iter) {
      i++;
    }
    Kast.List(i);
    for (Expr **iter = begin; iter != end; ++iter) {
      TRY_TO(TraverseStmt(*iter));
    }
    return true;
  }

  bool TraverseCXXUnresolvedConstructExpr(CXXUnresolvedConstructExpr *E) {
    Kast.KApply("UnresolvedConstructorCall", 2);
    return TraverseCXXConstructHelper(E->getTypeAsWritten(), E->arg_begin(), E->arg_end());
  }

  bool TraverseCXXFunctionalCastExpr(CXXFunctionalCastExpr *E) {
    Expr *arg = E->getSubExprAsWritten();
    Kast.KApply("FunctionalCast", 2);
    return TraverseCXXConstructHelper(E->getTypeInfoAsWritten()->getType(), &arg, &arg+1);
  }

  bool TraverseCXXScalarValueInitExpr(CXXScalarValueInitExpr *E) {
    Kast.KApply("FunctionalCast", 2);
    return TraverseCXXConstructHelper(E->getType(), 0, 0);
  }

  bool TraverseCXXConstructExpr(CXXConstructExpr *E) {
    Kast.KApply("ConstructorCall", 3);
    VisitBool(E->requiresZeroInitialization());
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool TraverseCXXTemporaryObjectExpr(CXXTemporaryObjectExpr *E) {
    Kast.KApply("TemporaryObjectExpr", 2);
    return TraverseCXXConstructHelper(E->getType(), E->getArgs(), E->getArgs() + E->getNumArgs());
  }

  bool VisitUnaryExprOrTypeTraitExpr(UnaryExprOrTypeTraitExpr *E) {
    if (E->getKind() == UETT_SizeOf) {
      if (E->isArgumentType()) {
        Kast.KApply("SizeofType", 1);
      } else {
        Kast.KApply("SizeofExpr", 1);
      }
    } else if (E->getKind() == UETT_AlignOf) {
      if (E->isArgumentType()) {
        Kast.KApply("AlignofType", 1);
      } else {
        Kast.KApply("AlignofExpr", 1);
      }
    } else {
      throw std::logic_error("unimplemented: ??? expr or type trait");
    }
    return false;
  }

  bool VisitSizeOfPackExpr(SizeOfPackExpr *E) {
    Kast.KApply("SizeofPack", 1);
    TRY_TO(TraverseDeclarationName(E->getPack()->getDeclName()));
    return false;
  }

  bool TraverseCXXPseudoDestructorExpr(CXXPseudoDestructorExpr *E) {
    Kast.KApply("PseudoDestructor", 5);
    TRY_TO(TraverseStmt(E->getBase()));
    VisitBool(E->isArrow());
    TRY_TO(TraverseNestedNameSpecifierLoc(E->getQualifierLoc()));
    if (TypeSourceInfo *ScopeInfo = E->getScopeTypeInfo()) {
      TRY_TO(TraverseTypeLoc(ScopeInfo->getTypeLoc()));
    } else {
      Kast.KApply("NoType", 0);
    }
    if (TypeSourceInfo *DestroyedTypeInfo = E->getDestroyedTypeInfo()) {
      TRY_TO(TraverseTypeLoc(DestroyedTypeInfo->getTypeLoc()));
    } else {
      Kast.KApply("NoType", 0);
    }
    return true;
  }

  bool VisitCXXNoexceptExpr(CXXNoexceptExpr *E) {
    Kast.KApply("Noexcept", 1);
    return false;
  }

  bool TraverseCXXNewExpr(CXXNewExpr *E) {
    Kast.KApply("NewExpr", 5);
    VisitBool(E->isGlobalNew());
    TRY_TO(TraverseType(E->getAllocatedType()));
    if (E->isArray()) {
      TRY_TO(TraverseStmt(E->getArraySize()));
    } else {
      Kast.KApply("NoExpression", 0);
    }
    if (E->hasInitializer()) {
      TRY_TO(TraverseStmt(E->getInitializer()));
    } else {
      Kast.KApply("NoInit", 0);
    }
    Kast.List(E->getNumPlacementArgs());
    for (unsigned i = 0; i < E->getNumPlacementArgs(); i++) {
      TRY_TO(TraverseStmt(E->getPlacementArg(i)));
    }
    return true;
  }

  bool VisitCXXDeleteExpr(CXXDeleteExpr *E) {
    Kast.KApply("DeleteExpr", 3);
    VisitBool(E->isGlobalDelete());
    VisitBool(E->isArrayFormAsWritten());
    return false;
  }

  bool VisitCXXThisExpr(CXXThisExpr *E) {
    Kast.KApply("This", 0);
    return false;
  }

  bool VisitCXXThrowExpr(CXXThrowExpr *E) {
    Kast.KApply("Throw", 1);
    if (!E->getSubExpr()) {
      Kast.KApply("NoExpression", 0);
    }
    return false;
  }

  bool TraverseLambdaCapture(LambdaExpr *E, const LambdaCapture *C, Expr*) {
    Kast.KApply("LambdaCapture", 2);
    switch(C->getCaptureKind()) {
      case LCK_This:
        Kast.KApply("This", 0);
        break;
      case LCK_ByRef:
        Kast.KApply("RefCapture", 1);
        // fall through
      case LCK_ByCopy:
        break;
      default:
        throw std::logic_error("unimplemented: capture kind");
    }
    if(C->capturesVariable()) {
      TRY_TO(TraverseDecl(C->getCapturedVar()));
    }
    VisitBool(C->isPackExpansion());
    return true;
  }

  bool TraverseLambdaExpr(LambdaExpr *E) {
    Kast.KApply("Lambda", 4);
    switch(E->getCaptureDefault()) {
      case LCD_None:
        Kast.KApply("NoCaptureDefault", 0);
        break;
      case LCD_ByCopy:
        Kast.KApply("CopyCapture", 0);
        break;
      case LCD_ByRef:
        Kast.KApply("RefCapture", 0);
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
    Kast.List(i);
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
    Kast.KApply("PackExpansionExpr", 1);
    return false;
  }

  void VisitStringRef(StringRef str) {
    Kast.KToken(str.begin(), str.end() - str.begin());
  }

  void VisitAPInt(llvm::APInt i) {
    Kast.KToken(i);
  }

  void VisitUnsigned(unsigned long long s) {
    Kast.KToken(s);
  }

  void VisitAPFloat(llvm::APFloat f) {
    if (!f.isFinite()) {
      throw std::logic_error("unimplemented: special floats");
    }
    Kast.KToken(f);
  }

  bool VisitStringLiteral(StringLiteral *Constant) {
    Kast.KApply("StringLiteral", 2);
    switch(Constant->getKind()) {
      case StringLiteral::Ascii:
        Kast.KApply("Ascii", 0);
        break;
      case StringLiteral::Wide:
        Kast.KApply("Wide", 0);
        break;
      case StringLiteral::UTF8:
        Kast.KApply("UTF8", 0);
        break;
      case StringLiteral::UTF16:
        Kast.KApply("UTF16", 0);
        break;
      case StringLiteral::UTF32:
        Kast.KApply("UTF32", 0);
        break;
    }
    StringRef str = Constant->getBytes();
    VisitStringRef(str);
    return false;
  }

  bool VisitCharacterLiteral(CharacterLiteral *Constant) {
    Kast.KApply("CharacterLiteral", 2);
    switch(Constant->getKind()) {
      case CharacterLiteral::Ascii:
        Kast.KApply("Ascii", 0);
        break;
      case CharacterLiteral::Wide:
        Kast.KApply("Wide", 0);
        break;
      case CharacterLiteral::UTF8:
        Kast.KApply("UTF8", 0);
        break;
      case CharacterLiteral::UTF16:
        Kast.KApply("UTF16", 0);
        break;
      case CharacterLiteral::UTF32:
        Kast.KApply("UTF32", 0);
        break;
    }
    Kast.KToken(Constant->getValue());
    return false;
  }

  bool TraverseIntegerLiteral(IntegerLiteral *Constant) {
    Kast.KApply("IntegerLiteral", 2);
    VisitAPInt(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool TraverseFloatingLiteral(FloatingLiteral *Constant) {
    Kast.KApply("FloatingLiteral", 2);
    VisitAPFloat(Constant->getValue());
    TRY_TO(TraverseType(Constant->getType()));
    return true;
  }

  bool VisitCXXNullPtrLiteralExpr(CXXNullPtrLiteralExpr *Constant) {
    Kast.KApply("NullPointerLiteral", 0);
    return false;
  }

  bool VisitCXXBoolLiteralExpr(CXXBoolLiteralExpr *Constant) {
    Kast.KApply("BoolLiteral", 1);
    VisitBool(Constant->getValue());
    return false;
  }

  bool TraverseInitListExpr(InitListExpr *E) {
    InitListExpr *Syntactic = E->isSemanticForm() ? E->getSyntacticForm() ? E->getSyntacticForm() : E : E;
    Kast.KApply("BraceInit", 1);
    Kast.List(Syntactic->getNumInits());
    for (Stmt *SubStmt : Syntactic->children()) {
      TRY_TO(TraverseStmt(SubStmt));
    }
    return true;
  }

  bool VisitImplicitValueInitExpr(ImplicitValueInitExpr *E) {
    Kast.KApply("ExpressionList", 1);
    Kast.List(0);
    return false;
  }

  bool VisitTypeTraitExpr(TypeTraitExpr *E) {
    Kast.KApply("GnuTypeTrait", 2);
    switch (E->getTrait()) {
      #define TRAIT(Name, Str)                    \
        case Name:                                \
          Kast.KToken(Str); \
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
    Kast.List(E->getNumArgs());
    return false;
  }

  bool VisitAtomicExpr(AtomicExpr *E) {
    Kast.KApply("GnuAtomicExpr", 2);
    switch(E->getOp()) {
      #define ATOMIC_BUILTIN(Name, Spelling)           \
        case AtomicExpr::AO##Name:                     \
          Kast.KToken(Spelling); \
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
    Kast.List(E->getNumSubExprs());
    return false;
  }

  bool VisitPredefinedExpr(PredefinedExpr *E) {
    return false;
  }

  // the rest of these are not part of the syntax of C but we keep them and transform them later
  // in order to avoid having to deal with messy syntax transformations within the parser
  bool VisitMaterializeTemporaryExpr(MaterializeTemporaryExpr *E) {
    Kast.KApply("MaterializeTemporaryExpr", 1);
    return false;
  }

  bool VisitParenListExpr(ParenListExpr *E) {
    Kast.KApply("ParenList", 1);
    Kast.List(E->getNumExprs());
    return false;
  }

  bool VisitCXXDefaultArgExpr(CXXDefaultArgExpr *E) {
    Kast.KSequence(0);
    return false;
  }

private:
  KastNodes & Kast;
  ASTContext * Context;
  llvm::StringRef InFile;

  void Specifier(const char *str) {
    Kast.KApply("Specifier", 2);
    Kast.KApply(str, 0);
  }

  void Specifier(const char *str, unsigned long long n) {
    Kast.KApply("Specifier", 2);
    Kast.KApply(str, 1);
    Kast.KToken(n);
  }

  void CabsLoc(SourceLocation loc) {
    SourceManager &mgr = Context->getSourceManager();
    PresumedLoc presumed = mgr.getPresumedLoc(loc);
    if (presumed.isValid()) {
      Kast.KApply("CabsLoc", 5);
      Kast.KToken(presumed.getFilename());
      StringRef filename(presumed.getFilename());
      SmallString<64> vector(filename);
      llvm::sys::fs::make_absolute(vector);
      const char *absolute = vector.c_str();
      Kast.KToken(absolute);
      VisitUnsigned(presumed.getLine());
      VisitUnsigned(presumed.getColumn());
      VisitBool(mgr.isInSystemHeader(loc));
    } else {
      Kast.KApply("UnknownCabsLoc_COMMON-SYNTAX", 0);
    }
  }

  bool excludedDecl(clang::Decl const *d) const {
    return d->isImplicit() && d->isDefinedOutsideFunctionOrMethod();
  }

  void DeclContext(DeclContext *D) {
    int i = 0;
    for (DeclContext::decl_iterator iter = D->decls_begin(), end = D->decls_end(); iter != end; ++iter) {
      clang::Decl const *d = *iter;
      if (!excludedDecl(d)) {
        i++;
      }
    }
    Kast.List(i);
  }

  void StmtChildren(Stmt *S) {
    int i = 0;
    for (Stmt::child_iterator iter = S->child_begin(), end = S->child_end(); iter != end; ++i, ++iter);
    Kast.List(i);
  }

  void StorageClass(StorageClass sc) {
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
        throw std::logic_error("unimplemented: storage class");
    }
    Specifier(spec);
  }

  void ThreadStorageClass(ThreadStorageClassSpecifier sc) {
    const char *spec;
    switch(sc) {
      case ThreadStorageClassSpecifier::TSCS_unspecified:
        return;
      case ThreadStorageClassSpecifier::TSCS_thread_local:
        spec = "ThreadLocal";
        break;
      default:
        throw std::logic_error("unimplemented: thread storage class");
    }
    Specifier(spec);
  }

  void Qualifiers(QualType T) {
    if (T.isLocalConstQualified()) {
      Kast.KApply("Qualifier", 2);
      Kast.KApply("Const", 0);
    }
    if (T.isLocalVolatileQualified()) {
      Kast.KApply("Qualifier", 2);
      Kast.KApply("Volatile", 0);
    }
    if (T.isLocalRestrictQualified()) {
      Kast.KApply("Qualifier", 2);
      Kast.KApply("Restrict", 0);
    }
  }

  void mangledIdentifier(NamedDecl * D) {
    Kast.KApply("Identifier", 1);
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
    Kast.KToken(s.str().c_str());
  }
};

#endif
