module LINKING-CPP-BUILTIN-SYNTAX
     imports BASIC-K
     imports BOOL
     imports COMMON-SORTS

     syntax KItem ::= addCppBuiltins(K, Bool)
endmodule

module LINKING-CPP-BUILTIN
     imports LINKING-CPP-BUILTIN-SYNTAX
     imports STRING
     imports COMMON-BUILTIN-SYNTAX
     imports MEMORY-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX

     imports C-CONFIGURATION

     rule <k> (.K => addCppBuiltin(B, T, AddAll))
               ~> addCppBuiltins((B::QualId -> T::CPPType => .K) ~> _, AddAll::Bool) ...</k>
     rule addCppBuiltins(.K, _) => .K

     syntax KItem ::= addCppBuiltin(QualId, CPPType, Bool)
     rule <k> addCppBuiltin(Q::QualId, t(... st: functionType(...)) #as T::CPPType, AddAll:Bool)
              => declareCppBuiltinFunction(Q, T, obj(0, 0, builtinCppSymbol(showSignature(Q, T)))) ...</k>
          <odr-defs> Defs:Map </odr-defs>
          requires (notBool (Q, T in_keys(Defs))) orBool AddAll

     rule <k> addCppBuiltin(Q::QualId, T::CPPType, false) => checkReplaceable(Q, T, Defs) ...</k>
          <odr-defs> Defs:Map </odr-defs>
          requires Q, T in_keys(Defs)

     syntax K ::= checkReplaceable(QualId, CPPType, Map) [function]
     syntax Error ::= "replaceableError"
     rule checkReplaceable(GlobalNamespace() :: operatordelete, t(_, _, functionType(... returnType: t(_, _, void), paramTypes: t(_, _, pointerType(t(_, _, void))), linkage: CPPLinkage)), Defs::Map)
          => ILL("TIN1", "Declared replacement function operator delete(void *) but no operator delete(void *, std::size_t).")
          ~> replaceableError
          requires notBool(GlobalNamespace() :: operatordelete, func(type(void), ptr(type(void)), type(size_t)) in_keys(Defs))
     rule checkReplaceable(GlobalNamespace() :: operatordelete, t(_, _, functionType(... returnType: t(_, _, void), paramTypes: (t(_, _, pointerType(t(_, _, void))), t(_, _, T::CPPSimpleType)), linkage: CPPLinkage)), Defs::Map)
          => ILL("TIN2", "Declared replacement function operator delete(void *, std::size_t) but no operator delete(void *).")
          ~> replaceableError
          requires T ==K size_t andBool notBool(GlobalNamespace() :: operatordelete, func(type(void), ptr(type(void))) in_keys(Defs))
     rule checkReplaceable(_, _, _) => .K [owise]

     syntax KItem ::= declareCppBuiltinFunction(QualId, CPPType, SymBase)
     rule <k> declareCppBuiltinFunction(N::Namespace :: X::CId, T::CPPType, Base::SymBase)
               => Odr.newDef(N :: X, T, Base)
          ...</k>
          <mem> Mem::Map => Mem[Base <- object(T, 0, makeArray(0, uninit))] </mem>
          <functions> Fun::Map => Fun[Base <- functionObject(N :: X, T, getDummyParams(T), callBuiltin)] </functions>
          <odr-decls> Decls::Map => Decls[Base += odrDecl("cpp-builtin", N :: X, X, CPPLinkage, T)] </odr-decls>

     syntax List ::= getDummyParams(CPPType) [function]
     syntax List ::= #getDummyParams(CPPTypes, Int) [function]
     rule getDummyParams(t(_, _, functionType(... paramTypes: Ts::CPPTypes))) => #getDummyParams(Ts, 0)
     rule #getDummyParams(_::CPPType, Ts::CPPTypes, I::Int) => ListItem(Identifier("_" +String showInt(I))) #getDummyParams(Ts, I +Int 1)
     rule #getDummyParams(.CPPTypes, _) => .List

endmodule

