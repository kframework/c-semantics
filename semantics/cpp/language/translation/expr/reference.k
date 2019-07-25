module CPP-TRANSLATION-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports BOOL
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX

     context bindReference(HOLE:Expr, _, _) [result(LVal)]

     rule bindReference(L:LVal, R:Val, D::Duration) => bindReference2(L, R, D)
     requires isCPPRefType(type(L))

     syntax KItem ::= bindReference2(LVal, Val, Duration)

     // @ref n4296 8.5.3:5.1.1
     // @ref n4800 9.3.3:5.1
     rule bindReference2(V1::LVal, V2::Val, _)
          => bindReference'(V1, V2)
          requires isCPPLVRefType(type(V1))
          andBool notBool isCPPBitfieldType(type(V2))
          andBool isReferenceCompatible(innerType(type(V1)), type(V2))
          andBool cat(V2) ==K lvalue

     // @ref n4800 9.3.3:5.3 - converted initializer is NOT a prvalue
     rule bindReference2(V1::LVal, V2::Val, _)
          => bindReference'(V1, V2)
          requires notBool isCPPBitfieldType(type(V2))
          andBool isReferenceCompatible(innerType(type(V1)), type(V2))
          andBool isValidReferenceType(type(V1))
          andBool cat(V2) ==K xvalue

     // @ref n4800 9.3.3:5.3 - converted initializer IS a prvalue
     rule bindReference2(V1::LVal, V2::Val, D::Duration)
          =>
          bindReferenceToTemporary(
               V1,
               innerType(type(V1)),
               V2,
               D
          )
          requires cat(V2) ==K prvalue
          andBool notBool isCPPArrayType(type(V2))


     syntax KItem ::= bindReferenceToTemporary(LVal, CPPType, Val, Duration)

     rule bindReferenceToTemporary(V1::LVal, T::CPPType, V2::Val, D::Duration)
          =>
          declareObject(NoNamespace(), NoNamespace(), #NoName(!I:Int), Identifier(""), T, V2, Var(CopyInit()), NoLinkage, D, .Set)
          ~>
          bindReference'(V1, Name(NoNNS(), #NoName(!I:Int)))

     syntax Expr ::= "bindReference'" "(" Expr "," Expr ")" [strict(c; 2)]

     rule bindReference'(L:LVal, R:Val) => le(bindReferenceExec(L, R), trace(L), type(L))

     rule <k> le(E::Expr, Tr::Trace, cppRefType #as T::CPPType => innerType(T)) ...</k>
          <unreference> true </unreference>
          <compile-time-evaluation> false </compile-time-evaluation>

     rule <k> xe(E::Expr, Tr::Trace, cppRefType #as T::CPPType => innerType(T)) ...</k>
          <unreference> true </unreference>
          <compile-time-evaluation> false </compile-time-evaluation>

endmodule
