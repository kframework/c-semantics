module CPP-DECL-CLASS-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax AType ::= declareClassName(Tag, CId, Bool)
     syntax KItem ::= classContext(AType, List) [strict(1)]
endmodule

module CPP-DECL-CLASS
     imports CPP-DECL-CLASS-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports MAP
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

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
            <class-type> ClassKey </class-type>
            // injected class name
            <ctypes> X |-> (ClassKey |-> T) </ctypes>
            <access> X |-> Public() </access>
            <access-specifier> getDefaultAccessType(ClassKey) </access-specifier>
          ...</class>)

     syntax AccessSpecifier ::= getDefaultAccessType(Tag) [function]
     rule getDefaultAccessType(Class()) => Private()
     rule getDefaultAccessType(Struct()) => Public()
     rule getDefaultAccessType(Union()) => Public()

     rule FieldDecl(NoNNS(), X::CId, T::CPPType, Init::Expr) => declareField(X, T, Init)

     syntax KItem ::= declareField(CId, CPPType, Expr) [strict(2)]

     rule <k> declareField(X::CId, T::CPPType, Init::Expr) => .K ...</k>
          <curr-scope> classScope(C::Class) </curr-scope>
          <class>...
            <class-type> Key::ClassKey </class-type>
            <class-id> C </class-id>
            <is-aggregate> B:Bool => B andBool (AS ==K Public()) </is-aggregate>
            <non-static-data-members>... .List => ListItem(X) </non-static-data-members>
            <access-specifier> AS::AccessSpecifier </access-specifier>
            <access> AE::Map => AE[X <- AS] </access>
            <cenv> CE::Map => CE[X, T <- classOffset(padOrNot(V, T, Key))] </cenv>
            <initializers> Inits::Map => Inits[X, T <- Init] </initializers>
            <max-offset> V::Int => updateMaxOffset(V, T, Key) </max-offset>
            <max-align> M::Int => maxInt(M, byteAlignofType(T)) </max-align>
          ...</class>
          requires notBool (X in_keys(CE))

     rule <k> AccessSpec(AS::AccessSpecifier) => .K ...</k>
          <curr-scope> classScope(C::Class) </curr-scope>
          <class>...
            <class-id> C </class-id>
            <access-specifier> _ => AS </access-specifier>
          ...</class>

     syntax Int ::= updateMaxOffset(Int, CPPType, ClassKey) [function]
     rule updateMaxOffset(V::Int, T::CPPType, Union()) => maxInt(V, bitSizeofType(T))
     rule updateMaxOffset(V::Int, T::CPPType, _) => pad(V,T) +Int bitSizeofType(T)  [owise]

     syntax Int ::= padOrNot(Int, CPPType, ClassKey) [function]
     rule padOrNot(_, _, Union()) => 0
     rule padOrNot(V::Int, T::CPPType, _) => pad(V, T) [owise]

     // TODO(traiansf): Handle pack directives
     // TODO(traiansf): Handle bit fields
     // taken from c-semantics/semantics/c11/language/translation/decl/tagged.k
     //
     // The padding associated with a particular field precedes it, with
     // possibly some extra padding at the end of the whole struct not
     // associated with any field. This is important for understanding the
     // effect of the gcc et al. padding attr as applied to a particular field.

     syntax Int ::= pad(Int, CPPType) [function]
     // Non-bitfields are aligned according to their type (if we note that
     // fields tagged with the Packed() attribute have an alignment of 1 byte).
     rule pad(V::Int, T::CPPType) => padTo(V, byteAlignofType(T))
          // requires notBool isBitfieldType(T)
     // Non-packed bitfields that would cross an alignment boundary and
     // zero-length bitfields have an alignment of the bitfield field type.
//     rule pad(V::Int, T:BitfieldType) => padTo(V, byteAlignofType(innerType(T)))
//          requires // notBool (Packed() in getModifiers(T)) andBool
//            (V +Int bitSizeofType(T)) >Int padTo(V, byteAlignofType(innerType(T)))
//     rule pad(V::Int, T:BitfieldType) => padTo(V, byteAlignofType(innerType(T)))
//          requires bitSizeofType(T) ==Int 0
     // Packed bitfields and non-packed bitfields that don't cross an alignment
     // boundary have 1-bit alignment (no padding).
//     rule pad(V::Int, _) => V [owise]

     // brace-or-equal initializers need to be evalauted in class scope
     rule <k> evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E ~> returnFromBraceOrEqualInitializer(Base, OldScope) ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> le(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>
     rule <k> xe(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>
     rule <k> pre(E::Expr => evalBraceOrEqualInitializer(C, Base, E), _, _)
           ~> (returnFromBraceOrEqualInitializer(Base::LVal, Scope::Scope) => .K)
          ...</k>
          <curr-scope> classScope(C::Class) => Scope </curr-scope>

     rule <k> V:Val ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
          requires notBool (isLExpr(V) orBool isPRExpr(V))

     rule <k> typeof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> typeof(V:CPPType) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
     rule <k> catof(evalBraceOrEqualInitializer(C::Class, Base::LVal, E::Expr) => E)
           ~> (.K => returnFromBraceOrEqualInitializer(Base, OldScope))
          ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
     rule <k> catof(V:ValueCategory) ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
endmodule
