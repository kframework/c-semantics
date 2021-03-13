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

     syntax KItem ::= instantiateTemplateType(TemplateInfo, Map)

     syntax TemplateSpecialization ::= templateSpecialization(CPPType, TemplateInfo, Map)

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
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX

     rule TemplateWithInstantiations(D::Decl, L::List, ExplicitInstantiations::List)
          => Template(D, L)
          ~> listToK(ExplicitInstantiations)

     rule Template(D::Decl, L::List) => declareTemplate(getTemplateName(D), D, listToK(L))

     syntax Decl ::= declareTemplate(Name, Decl, K)

     syntax Name ::= getTemplateName(Decl) [function]

     rule getTemplateName(DeclLoc(_, D::Decl) => D)

     rule getTemplateName(TypeDecl(ElaboratedTypeSpecifier(_, X::CId, N::NNS))) => Name(N, X)

     rule getTemplateName(NormalizedDecl(N::NNS, X::CId, _, _, _, _)) => Name(N, X)

     rule getTemplateName(DeclaratorAndSpecifiers(D::Declarator, _) => D)

     rule getTemplateName(ClassDef(_, X::CId, N::NNS, _, _, _)) => Name(N, X)

     rule <k> declareTemplate(Name(NoNNS(), X::CId), D::Decl, Params:K)
               => templateContext(N :: X, Params, D)
          ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>

     syntax KItem ::= restoreTemplateContext(TemplateInfo, Int)

     rule <k> templateContext(Q::QualId, Params:K, D::Decl)
               => scope(templateParameterScope, Params ~> setScope(S) ~> elaborate(D) ~> finishTemplate)
               ~> restoreTemplateContext(OldInfo, OldDepth)
          ...</k>
          <curr-template-context> OldInfo::TemplateInfo => templateInfo(Q, .List, .Map, .Map, NoType(), .K) </curr-template-context>
          <curr-template-depth> OldDepth::Int => OldDepth +Int 1 </curr-template-depth>
          <curr-tr-scope> S::Scope </curr-tr-scope>

     syntax KItem ::= "finishTemplate"

     rule <k> elaborateDone(K:K) ~> finishTemplate => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <templates>... Q |-> (stripType(T) |-> (_, templateInfo(... body: (_ => K)))) ...</templates>
          <curr-template-context> templateInfo(...id: Q::QualId, type: T::CPPType) </curr-template-context>


     rule <k> restoreTemplateContext(OldInfo::TemplateInfo, OldDepth::Int) => .K ...</k>
          <curr-template-depth> _ => OldDepth </curr-template-depth>
          <curr-template-context> _ => OldInfo </curr-template-context>

     // template parameters
     rule TypeTemplateParam(_, false, TemplateParameterType(#NoName), NoType())
          => addTemplateParam(#NoName, TypeParam, NoDefault())

     rule <k> TypeTemplateParam(_, false, TemplateParameterType(Identifier(S::String)), NoType())
               => addTemplateParam(Identifier(S), TypeParam, NoDefault())
               ~> TypedefDecl(Identifier(S), t(noQuals, .Set, dependentType(S, size(L))))
          ...</k>
          <curr-template-context> templateInfo(... decls: L::List) </curr-template-context>

     syntax KItem ::= addTemplateParam(CId, ParamType, KItem)

     syntax KItem ::= NoDefault()

     rule <k> addTemplateParam(#NoName, T::ParamType, Def:KItem) => .K ...</k>
          <curr-template-context> templateInfo(_, (L::List => L ListItem(#NoName(size(L)))), _::Map (.Map => #NoName(size(L)) |-> T), _::Map (.Map => #NoName(size(L)) |-> Def), _, _) </curr-template-context>

     rule <k> addTemplateParam(Identifier(S::String), T::ParamType, Def:KItem) => .K ...</k>
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

     rule <k> addParam(_::CId) => .K ...</k>
          <curr-function> dependent </curr-function>

     rule <k> (elaborateDone(K:K) ~> calculateGotoMap => .K) ~> _:KItem ~> setScope(_) ~> _:KItem
              ~> (declareObject(N::Namespace, LN::Namespace, X::CId, Mangled::CId, T::CPPType, _, Type::DeclarationType, L::Linkage, D::Duration, S::Set) => declareTemplate(T))
          ...</k>
          <elab>... .K => declareObject(N, LN, X, Mangled, T, TemplateDefinitionStmt(K), Type, L, D, S) </elab>


     syntax KItem ::= declareTemplate(CPPType)

     rule <k> declareTemplate(T::CPPType) => .K ...</k>
          <curr-template-context> templateInfo(X::QualId, Decls::List, Types::Map, Def::Map, (_ => T), _) </curr-template-context>
          <templates> Temp:Map => Temp X |-> (stripType(T) |-> (T, templateInfo(X, Decls, Types, Def, T, .K))) </templates>
          requires notBool X, T in_keys(Temp)

     rule <k> declareTemplate(T::CPPType) => .K ...</k>
          <curr-template-context> templateInfo(... id: X::QualId, type: _ => T) </curr-template-context>
          <templates> Temp:Map </templates>
          requires X, T in_keys(Temp)

     // template arguments
     rule TypeArg(t(_, _, _) #as T::CPPType) => T

     // template instantiation
     rule TemplateInstantiationDefinition(_, D::Declarator) => D

     rule <k> instantiateTemplateType(templateInfo(Q::QualId, Decls::List, Types::Map, Defaults::Map, T::CPPType, Body:K), Args::Map)
               => templateSpecialization(T, templateInfo(Q, Decls, Types, Defaults, T, Body), Args) ~> setTemplateArgs(Q, T, Old)
          ...</k>
          <template-arguments> Old::Map => updateMap(Old, Args) </template-arguments>

     rule <k> templateSpecialization(_:CPPType, _, _) ~> (setTemplateArgs(_, _, Old::Map) => .K) ...</k>
          <template-arguments> _ => Old </template-arguments>

     rule TemplateDefinitionStmt(K:K) => K

     syntax KItem ::= setTemplateArgs(QualId, CPPType, Map)

     rule <k> setTemplateArgs(N::Namespace :: X::CId, T::CPPType, Old::Map) => lv(lnew(getBase(Entry)), noTrace, T) ...</k>
          <template-arguments> _ => Old </template-arguments>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (_::Map stripType(T) |-> (_, Entry::EnvEntry)) ...</nenv>

endmodule
