module C-EXPR-CONDITIONAL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports COMMON-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     // Same as IfThenElse (type issues already dealt with).
     context (HOLE:KItem => reval(HOLE)) ? _ : _ [result(RValue)]
     rule tv(1, ut(_, int)) ? E1:K : E2:K => sequencePoint ~> E1
          requires notBool isVariablyModifiedType(type(E1))
               andBool notBool isVariablyModifiedType(type(E2))
          [structural]
     rule tv(0, ut(_, int)) ? E1:K : E2:K => sequencePoint ~> E2
          requires notBool isVariablyModifiedType(type(E1))
               andBool notBool isVariablyModifiedType(type(E2))
          [structural]
     rule tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)) ? _ : _

     syntax KItem ::= types(KItem, KItem) [strict]
     rule (.K => types(stabilizeVLA(type(E1)), stabilizeVLA(type(E2))))
          ~> _:RValue ? E1:K : E2:K
          requires isVariablyModifiedType(type(E1))
               orBool isVariablyModifiedType(type(E1))
          [structural]

     rule (types(
               t(_, Mods::Set, pointerType(T::Type)),
               t(_, Mods'::Set, pointerType(T'::Type))
          ) => convertedType(t(noQuals, Mods Mods', pointerType(compositeType(T, T')))))
          ~> _? _ : _
          requires stripQualifiers(T) ==Type stripQualifiers(T')
          [structural]
     rule (.K => UNDEF("EEC1", "variably modified types in a conditional expression with unequal size expressions."))
          ~> types(t(... st: pointerType(_)) #as T1::Type, t(... st: pointerType(_)) #as T2::Type)
          requires stripQualifiers(innerType(T1)) =/=Type stripQualifiers(innerType(T2))
          [structural]

     syntax KItem ::= convertedType(Type)
     rule convertedType(T::Type) ~> tv(1, ut(_, int)) ? E1:K : _
          => sequencePoint ~> Cast(T, E1)
          [structural]
     rule convertedType(T::Type) ~> tv(0, ut(_, int)) ? _ : E2:K
          => sequencePoint ~> Cast(T, E2)
          [structural]
     rule convertedType(_) ~> tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)) ? _ : _

endmodule
