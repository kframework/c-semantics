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
                    | bindReference3(LVal, CPPType, Val, CPPType, ValueCategory, Duration)

     syntax Bool ::= isCPP14() [function]
     rule isCPP14() => true

     rule bindReference2(V1::LVal, V2::Val, D::Duration)
          => bindReference3(V1, type(V1), V2, type(V2), cat(V2), D)

     rule bindReference3(V1::LVal, T1::CPPType, V2::Val, T2::CPPType, C2::ValueCategory, D::Duration)
          =>
          // @ref n4296 8.5.3/5.1
          // <quote>
          // If the reference is an lvalue reference and the initializer expression is an lvalue
          // (but is not a bit-field), and "cv1 T1" is reference-compatible with "cv2 T2,"
          // </quote>
          #if
               isCPPLVRefType(T1) andBool
               C2 ==K lvalue andBool
               notBool isCPPBitfieldType(T2) andBool
               isReferenceCompatible(innerType(T1), T2)
          #then
               bindReference'(V1, V2)
          #else
          // 5.2
          // <quote>
          // Otherwise, the reference shall be an lvalue reference to a non-volatile const type
          // (i.e., cv1 shall be const), or the reference shall be an rvalue reference.
          // </quote>
          #if
               isCPPLVRefType(T1) andBool
               notBool isConstType(innerType(T1))
          #then
               ill-formed
          #else
          // 5.2.1
          // <quote>
          // If the initializer expression is an xvalue (but not a bit-field),
          // class prvalue, array prvalue or function lvalue
          // and "cv1 T1" is reference-compatible with "cv2 T2
          // </quote>
          #if
          (
               (C2 ==K xvalue andBool notBool isCPPBitfieldType(T2)) orBool
               (C2 ==K prvalue andBool isCPPClassType(T2)) orBool
               (C2 ==K prvalue andBool isCPPArrayType(T2)) orBool
               (C2 ==K lvalue andBool isCPPFunctionType(T2))
          ) andBool isReferenceCompatible(innerType(T1), T2)
          #then
               // <quote>
               // then the reference is bound to the value of the initializer expression
               // </quote>
               bindReference'(V1, V2)
          #else
          // 5.2.2.1
          // <quote>
          // If T1 or T2 is a class type and T1 is not reference-related to T2,
          // <quote>
          #if (isCPPClassType(innerType(T1)) orBool isCPPClassType(T2))
               andBool notBool isReferenceRelated(innerType(T1), T2)
          #then
               // <quote>
               // user-defined conversions are considered using the rules
               // for copy-initialization of an object of type "cv1 T1"
               // by user-defined conversion; the program is ill-formed
               // if the corresponding non-reference copy-initialization
               // would be ill-formed. The result of the call to the conversion
               // function, as described for the non-reference copy-initialization,
               // is then used to direct-initialize the reference. For this
               // direct-initialization, user-defined conversions are not considered.
               // </quote>
               not-implemented
          #else
               // 5.2.2.2
               // Otherwise, a temporary of type "cv1 T1" is created
               // and copy-initialized from the initializer expression.
               // The reference is then bound to the temporary.
               bindReferenceToTemporary(V1, innerType(T1), V2, D)
          #fi #fi #fi #fi
          requires isCPP14()


     syntax Expr ::= bindReferenceToTemporary(LVal, CPPType, Val, Duration)

     rule bindReferenceToTemporary(V1::LVal, T::CPPType, V2::Val, D::Duration)
          =>
          declareObject(NoNamespace(), NoNamespace(), #NoName(!I:Int), Identifier(""), T, V2, Var(CopyInit()), NoLinkage, D, .Set)
          ~>
          bindReference'(V1, Name(NoNNS(), #NoName(!I:Int)))

     syntax Expr ::= "bindReference'" "(" Expr "," Expr ")" [strict(2)]

     rule bindReference'(L:LVal, R:Val) => le(bindReferenceExec(L, R), trace(L), type(L))

     rule <k> le(_::Expr, _::Trace, cppRefType #as T::CPPType => innerType(T)) ...</k>
          <unreference> true </unreference>
          <compile-time-evaluation> false </compile-time-evaluation>

     rule <k> xe(_::Expr, _::Trace, cppRefType #as T::CPPType => innerType(T)) ...</k>
          <unreference> true </unreference>
          <compile-time-evaluation> false </compile-time-evaluation>

endmodule
