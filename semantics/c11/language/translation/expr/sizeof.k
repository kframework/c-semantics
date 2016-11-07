module C-EXPR-SIZEOF-SYNTAX
     imports BASIC-K

     syntax KItem ::= #SizeofType(K) [strict]
endmodule

module C-EXPR-SIZEOF
     imports C-EXPR-SIZEOF-SYNTAX
     imports BOOL
     imports C-ABSTRACT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{2}}}{
     The \cinline{sizeof} operator yields the size (in bytes) of its operand,
     which may be an expression or the parenthesized name of a type. The size
     is determined from the type of the operand. The result is an integer. If
     the type of the operand is a variable length array type, the operand is
     evaluated; otherwise, the operand is not evaluated and the result is an
     integer constant.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.4}{5}}}{
     The value of the result of both operators is implementation-defined, and
     its type (an unsigned integer type) is \cinline{size_t}, defined in
     \header{<stddef.h>} (and other headers).
     }*/

     rule (.K => typeof(V)) ~> SizeofExpression(V:KItem)
     rule typeof(T:Type) ~> SizeofExpression(V:KItem) => sizeof(T)
          requires notBool isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     // Must evaluate the expression if it's a VLA (6.5.3.4p2).
     context typeof(T:Type) ~> SizeofExpression(HOLE:KItem)
          requires isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule typeof(T:Type) ~> SizeofExpression(V:KResult) => te(sizeof(stripHold(V)), utype(cfg:sizeut))
          requires isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule (.K => CV("TES1", "Trying to compute sizeof of an expression with incomplete or a function type."))
          ~> typeof(T:Type) ~> SizeofExpression(_)
          requires notBool isCompleteType(T)
               orBool isFunctionType(T)


     rule SizeofType(T:Type, K:K) => #SizeofType(DeclType(T, K))

     rule #SizeofType(T:Type) => sizeof(T)
          requires notBool isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule #SizeofType(T:Type) => te(sizeof(T), utype(cfg:sizeut))
          requires isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule (.K => CV("TES2", "Trying to compute sizeof of an incomplete or function type."))
          ~> #SizeofType(T:Type)
          requires notBool isCompleteType(T)
               orBool isFunctionType(T)
endmodule

