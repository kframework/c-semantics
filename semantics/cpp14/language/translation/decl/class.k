module CPP-DECL-CLASS-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-SORTS
     syntax AType ::= declareClassName(Tag, CId, Bool)
     syntax KItem ::= classContext(AType, List) [strict(1)]
endmodule

module CPP-DECL-CLASS
     import CPP-DECL-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule TypeDecl(ElaboratedTypeSpecifier(T:ClassKey, X::CId, NoNNS()) => declareClassName(T, X, true))

     context TypeDecl(HOLE:AType) 
             requires notBool isClassNameElabSpecifier(HOLE) [result(CPPTypeExpr)]
     context TypeDecl(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE)
                  andBool notBool isClassNameElabSpecifier(HOLE) [resullt(CPPType)]

     syntax Bool ::= isClassNameElabSpecifier(K) [function]
     rule isClassNameElabSpecifier(ElaboratedTypeSpecifier(_:ClassKey, _, NoNNS())) => true
     rule isClassNameElabSpecifier(_) => false [owise]
     
     rule <k> declareClassName(T::Tag, X::CId, true) => t(noQuals, .Set, classType(N :: Class(T, X, .TemplateArgs))) ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>

     rule <k> TypeDecl(t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(T::Tag, X::CId, Args::TemplateArgs)))) => .K ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, T <- t(Q, Mods, classType(N :: Class(T, X, Args)))] </ntypes>

     rule <k> ClassDef(T:ClassKey, X::CId, NoNNS(), .List, Members::List) => classContext(declareClassName(T, X, true), Members) ...</k>

     rule <k> classContext(t(Q::Quals, Mods::Set, classType(N::Namespace :: Class(T::Tag, X::CId, Args::TemplateArgs))), Members::List) 
              => setScope(classScope(N :: Class(T, X, Args)))
              ~> listToK(Members)
              ~> setScope(OldScope)
          ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-scope> OldScope::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, T <- t(Q, Mods, classType(N :: Class(T, X, Args)))] </ntypes>
          (.Bag => <class>...
            <class-id> N :: Class(T, X, Args) </class-id>
            // injected class name
            <ctypes> X |-> (T |-> t(Q, Mods, classType(N :: Class(T, X, Args)))) </ctypes>
            <access> X |-> Public() </access>
          ...</class>)

endmodule
