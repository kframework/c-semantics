module CPP-DECL-ENUM-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SYNTAX
endmodule

module CPP-DECL-ENUM
     imports CPP-DECL-ENUM-SYNTAX
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-BITSIZE-SYNTAX

     syntax CPPEnumType ::= declareEnumName(ns: Namespace, id: CId, ut: CPPIntegerType, scoped: Bool) [function]
     rule declareEnumName(N::Namespace, X::CId, UT::CPPIntegerType, false) => t(noQuals, .Set, unscopedEnum(enumId(N::Namespace :: X), UT))
     rule declareEnumName(N::Namespace, X::CId, UT::CPPIntegerType, true)  => t(noQuals, .Set,   scopedEnum(enumId(N::Namespace :: X), UT))

     syntax KItem ::= addToCurrentNamespace(CId, CPPEnumType)
     rule <k> addToCurrentNamespace(X::CId, E::CPPEnumType) => . ... </k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, Enum() <- E] </ntypes>

     // second param -underlying type
     syntax KItem ::= newEnum(CPPEnumType)

     rule <k> newEnum(E:CPPEnumType) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <cppenum>...
               <enum-id> getEnumId(E) </enum-id>
               <enum-ut> underlyingType(E) </enum-ut>
               <scoped> getScoped(E) </scoped>
           ...</cppenum>)

     syntax KItem ::= enumContext(CId, CPPEnumType) [strict(2)]

     // We do not support enumerators yet
     rule <k> EnumDef(X::CId, NoNNS(), Scoped::Bool, Fixed::Bool, UT::CPPIntegerType, .List)
          => enumContext(X, declareEnumName(N, X, UT, Scoped)) ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>

     rule enumContext(X::CId, E::CPPEnumType) => newEnum(E) ~> addToCurrentNamespace(X, E)

endmodule

