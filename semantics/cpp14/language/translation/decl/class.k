module CPP-DECL-CLASS-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-SORTS
     syntax AType ::= declareClassName(Tag, CId, Bool)
     syntax KItem ::= classContext(AType, List) [strict(1)]
endmodule

module CPP-DECL-CLASS
     imports CPP-DECL-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
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

     rule <k> TypeDecl(t(_, _, classType(N::Namespace :: Class(ClassKey::Tag, X::CId, _))) #as T::CPPType) => .K ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, ClassKey <- T] </ntypes>

     rule <k> ClassDef(T:ClassKey, X::CId, NoNNS(), .List, Members::List) => classContext(declareClassName(T, X, true), Members) ...</k>

     rule <k> classContext(t(_, _, classType((N::Namespace :: Class(ClassKey::Tag, X::CId, _)) #as C::Class)) #as T::CPPType, Members::List) 
              => setScope(classScope(C))
              ~> listToK(Members)
              ~> setScope(OldScope)
          ...</k>
          <curr-template-context> noTemplate </curr-template-context>
          <curr-scope> OldScope::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, ClassKey <- T] </ntypes>
          (.Bag => <class>...
            <class-id> C </class-id>
            // injected class name
            <ctypes> X |-> (ClassKey |-> T) </ctypes>
            <access> X |-> Public() </access>
          ...</class>)

endmodule
