module CPP-TRANSLATION-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports BOOL
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX

     context bindReference(HOLE:Expr, _) [result(LVal)]

     rule bindReference(L:LVal, R:Val) => bindReference2(L, R)

     syntax KItem ::= bindReference2(LVal, Val)

     // @ref n4296 8.5.3:5.1.1
     // @ref n4800 9.3.3:5.1
     rule bindReference2(V1::LVal, V2::Val)
          => bindReferenceExec(V1, V2)
          requires isCPPLVRefType(type(V1))
          andBool notBool isCPPBitfieldType(type(V2))
          andBool isReferenceCompatible(innerType(type(V1)), type(V2))
          andBool cat(V2) ==K lvalue

     // @ref n4800 9.3.3:5.3 - converted initializer is NOT a prvalue
     rule bindReference2(V1::LVal, V2::Val)
          => bindReferenceExec(V1, V2)
          requires notBool isCPPBitfieldType(type(V2))
          andBool isReferenceCompatible(innerType(type(V1)), type(V2))
          andBool isValidReferenceType(type(V1))
          andBool cat(V2) ==K xvalue

     // @ref n4800 9.3.3:5.3 - converted initializer IS a prvalue
     rule bindReference2(V1::LVal, V2::Val)
          =>
          bindReferenceToTemporary(
               V1,
               temp(!I:Int, innerType(type(V1))),
               innerType(type(V1)),
               V2
          )
          requires cat(V2) ==K prvalue
          andBool notBool isCPPArrayType(type(V2))


     syntax KItem ::= bindReferenceToTemporary(LVal, Expr, CPPType, Val)

     rule bindReferenceToTemporary(V1::LVal, Temp::Expr, T::CPPType, V2::Val)
          =>
          TExpressionStmt(figureInit(le(Temp, noTrace, T), T, V2, CopyInit())) // TODO copy or direct?
          ~>
          bindReferenceExec(V1, le(Temp, noTrace, T))

     rule bindReferenceExec(L:LVal, R:Val) => le(bindReferenceExec(L, R), trace(L), type(L))
          requires Translation()

endmodule
