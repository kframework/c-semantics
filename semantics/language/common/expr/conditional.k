module C-COMMON-EXPR-CONDITIONAL-SYNTAX
     // TODO(chathhorn): error check
     //TODO: might not need TypeList
     syntax KItem ::= types(TypeList) [strict]
     //TODO: might not need this list in the future. 
     syntax TypeItem ::= tItem(K) [strict]
     syntax TypeList ::= List{TypeItem,"ts::"} [strict]
     syntax TypeList ::= toTypeList(List) [function]
     syntax List ::= tListToList(TypeList) [function]

     syntax TypeResult ::= trItem(K)
     syntax TypeItem ::= TypeResult
     syntax KResult ::= TypeResult

     rule tItem(V:KResult) => trItem(V)

     rule toTypeList(.List) => .TypeList
     rule toTypeList(ListItem(K:K) L:List) => tItem(K) ts:: toTypeList(L)

     rule tListToList(.TypeList) => .List
     rule tListToList(trItem(K:K) ts:: HL:TypeList) => ListItem(K) tListToList(HL)
endmodule

module C-COMMON-EXPR-CONDITIONAL
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX

     syntax KItem ::= getTypes(List)
     //TODO: overcome the context associative matching
     //context types(_:List ListItem(HOLE) _:List)
     syntax KItem ::= convertedType(K) [strict]

     rule getTypes(L:List) => types(toTypeList(wrapWithTypeOf(L))) [structural]

     syntax List ::=  wrapWithTypeOf(List) [function]
     rule wrapWithTypeOf(ListItem(K:K) L:List)
          => ListItem(retype(typeof(K))) wrapWithTypeOf(L)
     rule wrapWithTypeOf(.List) => .List

     syntax KItem ::= retype(K) [strict]

     // fixme, not handling qualifiers correctly
     rule retype(T:Type) => t(.Set, pointerType(innerType(T)))
          requires isArrayType(T)
          [structural]
     rule retype(T:Type) => t(.Set, pointerType(T))
          requires isFunctionType(T)
          [structural]
     rule retype(T:Type) => T
          requires notBool (isArrayType(T) orBool isFunctionType(T))
          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/
     rule (. => getTypes(ListItem(E1) ListItem(E2))) ~> _ ? E1:K : E2:K 
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type))
          => convertedType(usualArithmeticConversion(T1, T2)))
               ~> _ ? _ : _
          requires T1 =/=K T2
               andBool hasArithmeticType(T1)
               andBool hasArithmeticType(T2)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{6}}}{
     \broken{If both the second and third operands are pointers or one is a
     null pointer constant and the other is a pointer, the result type is a
     pointer to a type qualified with all the type qualifiers of the types
     referenced by both operands. Furthermore, if both operands are pointers to
     compatible types or to differently qualified versions of compatible types,
     the result type is a pointer to an appropriately qualified version of the
     composite type}; if one operand is a null pointer constant, the result has
     the type of the other operand; \broken{otherwise, one operand is a pointer
     to void or a qualified version of \cinline{void}, in which case the result
     type is a pointer to an appropriately qualified version of
     \cinline{void}.}
     }*/
     // fixme, this is too relaxed; could be any integer zero.  need static
     // semantics to handle this properly
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type)) => convertedType(T2))
          ~> _ ? tv(0, T1) : _
          requires hasIntegerType(T1)
               andBool isPointerType(T2)
          [structural]
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type)) => convertedType(T1))
          ~> _? _ : tv(0, T2)
          requires hasIntegerType(T2)
               andBool isPointerType(T1)
          [structural]

     // fixme, this is wrong
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type)) => convertedType(T1))
          ~> _? _ : _
          requires isPointerType(T1)
               andBool isPointerType(T2)
          [structural]

     // this should take care of the void/struct cases
     rule (types(trItem(T:Type) ts:: trItem(T':Type)) => convertedType(T))
          ~> _ ? _ : _
          requires notBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule convertedType(T:Type) ~> E:K ? E1:K : E2:K
          => IfThenElse(E, Cast(T, E1), Cast(T, E2))
          [structural]
endmodule

