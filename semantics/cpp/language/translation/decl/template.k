module CPP-TRANSLATION-DECL-TEMPLATE-SORTS
     syntax TemplateInfo
endmodule

module CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports CPP-TRANSLATION-DECL-TEMPLATE-SORTS
     imports BASIC-K
     imports LIST
     imports MAP
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax TemplateInfo ::= templateInfo(id: QualId, decls: List, paramTypes: Map, defaults: Map, type: AType, body: K)

     syntax ParamType ::= "TypeParam" | "ValueParam" | "TemplateParam"

     syntax KItem ::= templateContext(QualId, K, K)

     syntax SymBase ::= "dependent"

     syntax Decl ::= declareTemplatedType(CPPType)
                   | declareTemplatedObject(Namespace, CId, CPPType, Init, DeclarationType, Linkage, Duration, Set)

     syntax Expr ::= instantiateObjectTemplate(K) [strict]

     syntax KItem ::= instantiateTemplate(K) [strict]

     syntax KItem ::= instantiateTemplateType(TemplateInfo, Map)

     syntax TemplateSpecialization ::=templateSpecialization(CPPTypeExpr, TemplateInfo, Map)

     syntax KResult ::= TemplateSpecialization
endmodule

module CPP-TRANSLATION-DECL-TEMPLATE
     imports CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports C-CONFIGURATION
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX

     rule TemplateWithInstantiations(D::Decl, L::List, ExplicitInstantiations::List) => Template(D, L) ~> listToK(ExplicitInstantiations) [anywhere]

     rule Template(D::Decl, L::List) => declareTemplate(getTemplateName(D), D, listToK(L))

     syntax Decl ::= declareTemplate(Name, Decl, K)

     syntax Name ::= getTemplateName(Decl) [function]

     rule getTemplateName(DeclLoc(_, D::Decl) => D)

     rule getTemplateName(TypeDecl(ElaboratedTypeSpecifier(_, X::CId, N::NNS))) => Name(N, X)

     rule getTemplateName(NormalizedDecl(N::NNS, X::CId, _, _, _, _)) => Name(N, X)

     rule getTemplateName(DeclaratorAndSpecifiers(D::Declarator, _) => D)

     rule getTemplateName(ClassDef(_, X::CId, N::NNS, _, _, _)) => Name(N, X)

     rule <k> declareTemplate(Name(NoNNS(), X::CId), D::Decl, Params:K) => templateContext(N :: X, Params, D) ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>

     syntax KItem ::= restoreTemplateContext(TemplateInfo, Int)

     rule <k> templateContext(Q::QualId, Params:K, D::Decl) => scope(templateParameterScope, Params ~> setScope(S) ~> elaborate(D) ~> finishTemplate) ~> restoreTemplateContext(OldInfo, OldDepth) ...</k>
          <curr-template-context> OldInfo::TemplateInfo => templateInfo(Q, .List, .Map, .Map, NoType(), .K) </curr-template-context>
          <curr-template-depth> OldDepth::Int => OldDepth +Int 1 </curr-template-depth>
          <curr-tr-scope> S::Scope </curr-tr-scope>

     syntax KItem ::= "finishTemplate"

     rule <k> elaborateDone(K:K) ~> finishTemplate => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <templates>... Q |-> (T |-> templateInfo(... body: (_ => K))) ...</templates>
          <curr-template-context> templateInfo(...id: Q::QualId, type: T::CPPType) </curr-template-context>


     rule <k> restoreTemplateContext(OldInfo::TemplateInfo, OldDepth::Int) => .K ...</k>
          <curr-template-depth> _ => OldDepth </curr-template-depth>
          <curr-template-context> _ => OldInfo </curr-template-context>

     // template parameters
     rule TypeTemplateParam(_, false, TemplateParameterType(#NoName), NoType()) => addTemplateParam(#NoName, TypeParam, .K)

     rule <k> TypeTemplateParam(_, false, TemplateParameterType(Identifier(S::String)), NoType()) => addTemplateParam(Identifier(S), TypeParam, .K) ~> TypedefDecl(Identifier(S), t(noQuals, .Set, dependentType(S, size(L)))) ...</k>
          <curr-template-context> templateInfo(... decls: L::List) </curr-template-context>

     syntax KItem ::= addTemplateParam(CId, ParamType, K)

     rule <k> addTemplateParam(#NoName, T::ParamType, Def:K) => .K ...</k>
          <curr-template-context> templateInfo(_, (L::List => L ListItem(#NoName(size(L)))), _::Map (.Map => #NoName(size(L)) |-> T), _::Map (.Map => #NoName(size(L)) |-> Def), _, _) </curr-template-context>

     rule <k> addTemplateParam(Identifier(S::String), T::ParamType, Def:K) => .K ...</k>
          <curr-template-context> templateInfo(_, (L::List => L ListItem(Identifier(S))), _::Map (.Map => Identifier(S) |-> T), _::Map (.Map => Identifier(S) |-> Def), _, _) </curr-template-context>

     // template declarations

     // class declaration
     rule <k> TypeDecl(t(_, _, _) #as T::CPPType) => declareTemplate(T) ...</k>
          <elab>... .K => declareTemplatedType(T) </elab>
          <curr-template-context> templateInfo(...) </curr-template-context>

     // class definition
     rule <k> (.K => elaborate(listToK(Members)))
          ~> classContext(t(_, _, _), .List, Members::List) ...</k>
          <curr-template-context> templateInfo(...) </curr-template-context>

     rule <k> elaborateDone(Done:K) ~> classContext(t(_, _, _) #as T::CPPType, .List,  _)
              => declareTemplate(T)
          ...</k>
          <elab>... .K => classContext(T, .List, kSeqToList(Done)) </elab>
          <curr-template-context> templateInfo(...) </curr-template-context>

     // TODO(dwightguth): check the syntax of template definitions and generate
     // the "hypothetical instantantiation"
     // var or function declaration
     rule <k> declareObject(N::Namespace, LN::Namespace, X::CId, Mangled::CId, T::CPPType, NoInit(), Type::DeclarationType, L::Linkage, D::Duration, S::Set)
               => declareTemplate(T)
          ...</k>
          <elab>... .K => declareObject(N, LN, X, Mangled, T, NoInit(), Type, L, D, S) </elab>
          <curr-template-context> templateInfo(...) </curr-template-context>

     // function definition
     rule <k> (.K => processFunDef(dependent, N :: X, T, Params, Init))
              ~> declareObject(N::Namespace, _, X::CId, _, T::CPPType, Init::Stmt, Function(Params::List), _, _, _)
          ...</k>
          <curr-template-context> templateInfo(...) </curr-template-context>
          requires Init =/=K NoInit()

     rule <k> addParam(X::CId) => .K ...</k>
          <curr-function> dependent </curr-function>

     rule <k> (elaborateDone(K:K) ~> calculateGotoMap => .K) ~> _:KItem ~> setScope(_) ~> _:KItem
              ~> (declareObject(N::Namespace, LN::Namespace, X::CId, Mangled::CId, T::CPPType, _, Type::DeclarationType, L::Linkage, D::Duration, S::Set) => declareTemplate(T))
          ...</k>
          <elab>... .K => declareObject(N, LN, X, Mangled, T, TemplateDefinitionStmt(K), Type, L, D, S) </elab>


     syntax KItem ::= declareTemplate(CPPType)

     rule <k> declareTemplate(T::CPPType) => .K ...</k>
          <curr-template-context> templateInfo(X::QualId, Decls::List, Types::Map, Def::Map, (_ => T), _) </curr-template-context>
          <templates> Temp:Map => Temp X |-> (T |-> templateInfo(X, Decls, Types, Def, T, .K)) </templates>
          requires notBool X, T in_keys(Temp)

     rule <k> declareTemplate(T::CPPType) => .K ...</k>
          <curr-template-context> templateInfo(... id: X::QualId, type: _ => T) </curr-template-context>
          <templates> Temp:Map </templates>
          requires X, T in_keys(Temp)

     // template arguments
     rule TypeArg(t(_, _, _) #as T::CPPType) => T

     // template instantiation

     rule TemplateInstantiationDefinition(TemplateSpecializationType(X::CId), NormalizedDecl(NoNNS(), X::CId, _, A::AType, _, _))
          => instantiateTemplate(deduceTemplateFromDecl(nameLookup(X, NoTag(), defaultMask), A)) ~> finishExplicitInstantiation

     syntax KItem ::= "finishExplicitInstantiation"

     rule _:LVal ~> finishExplicitInstantiation => .K

     rule <k> instantiateTemplateType(templateInfo(Q::QualId, Decls::List, Types::Map, Defaults::Map, T::CPPTypeExpr, Body:K), Args::Map) => templateSpecialization(T, templateInfo(Q, Decls, Types, Defaults, T, Body), Args) ~> setTemplateArgs(Q, T, Old) ...</k>
          <template-arguments> Old::Map => updateMap(Old, Args) </template-arguments>

     context templateSpecialization(HOLE:CPPTypeExpr, _, _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     rule <k> templateSpecialization(T:CPPType, _, _) ~> (setTemplateArgs(_, _, Old::Map) => .K) ...</k>
          <template-arguments> _ => Old </template-arguments>

     rule instantiateTemplate(templateSpecialization(T:CPPFunctionType, I::TemplateInfo, Args::Map)) => instantiateObjectTemplate(templateSpecialization(T, I, Args))

     rule <k> instantiateObjectTemplate(templateSpecialization(T::CPPType, templateInfo(Q::QualId, Decls::List, _, _, _, Body:K), Args:Map)) => scope(templateParameterScope, declareTemplateArgs(Decls, Args, 0) ~> setScope(S) ~> Body) ~> setTemplateArgs(Q, T, Old) ...</k>
          <template-arguments> Old::Map => updateMap(Old, Args) </template-arguments>
          <curr-tr-scope> S::Scope </curr-tr-scope>

     syntax KItem ::= declareTemplateArgs(List, Map, Int)

     rule (.K => TypedefDecl(Identifier(S), T)) ~> declareTemplateArgs((ListItem(Identifier(S::String)) => .List) _, _ dependentType(S, I) |-> T:CPPType, I::Int => I +Int 1)

     rule declareTemplateArgs(.List, _, _) => .K

     rule TemplateDefinitionStmt(K:K) => K

     syntax KItem ::= setTemplateArgs(QualId, CPPTypeExpr, Map)

     rule <k> setTemplateArgs(N::Namespace :: X::CId, T::CPPType, Old::Map) => lv(lnew(getBase(Entry)), noTrace, T) ...</k>
          <template-arguments> _ => Old </template-arguments>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_::TypeMap T |-> Entry::EnvEntry) ...</nenv>

     // template parameter substitution
     context t(_, _, arrayType(HOLE:CPPTypeExpr, _))
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context t(_, _, pointerType(HOLE:CPPTypeExpr))
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context t(_, _, lvRefType(HOLE:CPPTypeExpr))
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context t(_, _, rvRefType(HOLE:CPPTypeExpr))
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context t(_, _, functionType(... returnType: HOLE:CPPTypeExpr))
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context t(_, _, functionType(... paramTypes: HOLE:CPPTypeExprs))
             requires notBool areDependentInScope(HOLE) [result(CPPTypes)]

     context t(_, _, classType(_ :: Class(_, _, HOLE:TemplateParams)))
             requires notBool areDependentInScope(HOLE) [result(TemplateArgs)]

     context HOLE:CPPTypeExpr, _::CPPTypeExprs
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context HOLE:CPPTypeExpr, _::TemplateParams
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     rule <k> t(Q::Quals, Mods::Set, dependentType(S::String, I::Int)) => t(Q +Quals Q', Mods Mods', T) ...</k>
          <template-arguments>... dependentType(S, I) |-> t(Q'::Quals, Mods'::Set, T::CPPSimpleTypeExpr) ...</template-arguments>

     rule <k> t(Q::Quals, Mods::Set, auto) => t(Q +Quals Q', Mods Mods', T) ...</k>
          <template-arguments>... auto |-> t(Q'::Quals, Mods'::Set, T::CPPSimpleTypeExpr) ...</template-arguments>
endmodule
