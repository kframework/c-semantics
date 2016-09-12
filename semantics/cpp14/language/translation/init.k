module CPP-TRANSLATION-INIT-SYNTAX
     imports COMMON-SORTS

     syntax KItem ::= makeNs(Namespace)
endmodule

module CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-INIT-SYNTAX
     imports STRING
     imports COMMON-BUILTIN-SYNTAX
     imports MEMORY-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports C-LINKING-RESOLUTION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DECL-DECLARATOR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> TranslationUnit(TU:String, Decls:List)
               => makeTu(TU +String newUUID)
               ~> makeNs(GlobalNamespace())
               ~> implicitDecls
               ~> listToK(Decls)
               ~> removeUnusedIdentifiers
          ...</k>
          // don't delete this... we want to make sure the fresh counter starts
          // at 1 for each TU because unlike C, C++ doesn't give us unique block
          // numbers directly from the parser, so we are using the fresh counter to
          // assign block numbers. But the fresh counter starts at 0 and block 0
          // is the privileged "haven't entered the outer block of the function yet"
          // block.
          requires !Fresh:Int >=Int 0 

     syntax KItem ::= "implicitDecls"
                    | "func" "(" Namespace "," CId "," CPPType "," CPPTypes ")" [function]
     rule implicitDecls
          => func(GlobalNamespace(), operatornew, type(pointerType(type(void))), type(size_t))
          ~> func(GlobalNamespace(), operatornew[], type(pointerType(type(void))), type(size_t))
          // TODO(dwightguth): delete, delete[]

     rule func(N::Namespace, X::CId, Ret::CPPType, Args::CPPTypes) 
          => declareObject(N, X, type(functionType(Ret, Args, CPPLinkage)), NoInit(), Function(.List), ExternalLinkage, StaticStorage, .Set)

     rule <k> makeNs(N::Namespace) => .K ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <namespaces>...
               (.Bag => <ns>...
                             <ns-id> N </ns-id>
                        ...</ns>)
          ...</namespaces>

     rule addCPPBuiltins => addBuiltins(weakCppBuiltins, false)

     rule <k> builtinTu => TranslationUnit("cpp-builtin", ListItem(addBuiltins(cppBuiltins, true)))
          ...</k>
          <options>... SetItem(XBuiltins()) ...</options>

     rule <k> builtinTu => .K ...</k>
          <options> Opts:Set </options>
          requires notBool (XBuiltins() in Opts)

     rule <k> (.K => addBuiltin(B, T, AddAll))
               ~> addBuiltins((B:QualId |-> T:CPPType => .Map) _, AddAll:Bool) ...</k>

     syntax KItem ::= addBuiltin(QualId, CPPType, Bool) [klabel(addBuiltinCpp)]

     rule <k> addBuiltin(Q::QualId, T:CPPFunctionType, AddAll:Bool)
              => declareBuiltinFunction(Q, T, Base) ...</k>
          <odr-defs> Defs:Map </odr-defs>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Base::SymBase => linc(Base) </next-static-loc>
          requires (notBool (Q in_keys(Defs))) orBool AddAll

     rule <k> addBuiltin(Q::QualId, _, false) => .K ...</k>
          <odr-defs> Defs:Map </odr-defs>
          requires Q in_keys(Defs)

     syntax KItem ::= declareBuiltinFunction(QualId, CPPType, SymBase) [klabel(declareBuiltinFunctionCpp)]
     rule <k> declareBuiltinFunction(N::Namespace :: X::CId, T::CPPType, Base::SymBase) => .K ...</k>
          <mem> Mem::Map => Mem[Base <- object(T, 0, makeEmptyArray(0))] </mem>
          <functions> Fun::Map => Fun[Base <- functionObject(N :: X, T, getDummyParams(T), handleBuiltin)] </functions>
          <odr-defs> Defs::Map => Defs[N :: X, T <- Base] </odr-defs>

     syntax List ::= getDummyParams(CPPType) [function]
     syntax List ::= #getDummyParams(CPPTypes, Int) [function]
     rule getDummyParams(t(_, _, functionType(_, Ts::CPPTypes, _))) => #getDummyParams(Ts, 0)
     rule #getDummyParams(T::CPPType, Ts::CPPTypes, I::Int) => ListItem(Identifier("_" +String Int2String(I))) #getDummyParams(Ts, I +Int 1)
     rule #getDummyParams(.CPPTypes, _) => .List

     rule isCLinkage(t(_, _, functionType(_, _::CPPTypes, CLinkage))) => true
     rule isCLinkage(_) => false [owise]

     rule combine(hasTrace(E::Expr), #klabel(Lbl:KLabel)) => hasTrace(Lbl(E))
     rule combine(hasTrace(E::Expr), hasTrace(E2::Expr), #klabel(Lbl:KLabel)) => hasTrace(Lbl(E, E2))
     rule combine(_, _) => noTrace [owise]
     rule combine(_, _::Trace, _) => noTrace [owise]
endmodule
