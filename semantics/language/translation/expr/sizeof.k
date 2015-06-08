module C-EXPR-SIZEOF
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

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

     rule SizeofExpression(V:KResult) => sizeof(V)
          requires notBool isVariableLengthArrayType(type(V))
               andBool isCompleteType(type(V))
               andBool notBool isFunctionType(type(V))
     // Must evaluate the expression if it's a VLA (6.5.3.4p2).
     rule SizeofExpression(V:KResult) => te(sizeof(stripHold(V)), t(.Set, cfg:sizeut))
          requires isVariableLengthArrayType(type(V))
               andBool isCompleteType(type(V))
               andBool notBool isFunctionType(type(V))
     rule (.K => CV("TES1", "Trying to compute sizeof of an expression with incomplete or a function type.", "6.5.3.4:1"))
          ~> SizeofExpression(V:RValue)
          requires notBool isCompleteType(type(V))
               orBool isFunctionType(type(V))

     rule SizeofType(T:Type, K:K) => #SizeofType(DeclType(T, K))

     syntax KItem ::= #SizeofType(K) [strict]
     rule #SizeofType(T:Type) => sizeof(T)
          requires notBool isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule #SizeofType(T:Type) => te(sizeof(T), t(.Set, cfg:sizeut))
          requires isVariableLengthArrayType(T)
               andBool isCompleteType(T)
               andBool notBool isFunctionType(T)
     rule (.K => CV("TES2", "Trying to compute sizeof of an incomplete or function type.", "6.5.3.4:1"))
          ~> #SizeofType(T:Type)
          requires notBool isCompleteType(T)
               orBool isFunctionType(T)
endmodule

