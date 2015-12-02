module C-EXPR-CONDITIONAL
     imports C-ERROR-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     // Same as IfThenElse (type issues already dealt with).
     context (HOLE:KItem => reval(HOLE)) ? _ : _ [result(RValue)]
     rule tv(1, t(_, int)) ? E1:K : E2:K => sequencePoint ~> E1
          requires notBool isVariablyModifiedType(type(E1))
               andBool notBool isVariablyModifiedType(type(E2))
          [structural]
     rule tv(0, t(_, int)) ? E1:K : E2:K => sequencePoint ~> E2
          requires notBool isVariablyModifiedType(type(E1))
               andBool notBool isVariablyModifiedType(type(E2))
          [structural]

     syntax KItem ::= types(K, K) [strict]
     rule (.K => types(stabilizeVLA(type(E1)), stabilizeVLA(type(E2))))
          ~> _:RValue ? E1:K : E2:K
          requires isVariablyModifiedType(type(E1))
               orBool isVariablyModifiedType(type(E1))
          [structural]

     rule (types(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type))
          ) => convertedType(t(Mods Mods', pointerType(compositeType(T, T')))))
          ~> _? _ : _
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))
          [structural]
     rule (.K => UNDEF("EEC1", "variably modified types in a conditional expression with unequal size expressions.", "6.7.6.1:6"))
          ~> types(T1:PointerType, T2:PointerType)
          requires notBool areCompatible(stripQualifiers(innerType(T1)), stripQualifiers(innerType(T2)))
          [structural]

     syntax KItem ::= convertedType(Type)
     rule convertedType(T:Type) ~> tv(1, t(_, int)) ? E1:K : _
          => sequencePoint ~> Cast(T, E1)
          [structural]
     rule convertedType(T:Type) ~> tv(0, t(_, int)) ? _ : E2:K
          => sequencePoint ~> Cast(T, E2)
          [structural]

endmodule

