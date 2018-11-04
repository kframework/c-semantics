module C-STMT-EXPR
     imports C-CONFIGURATION
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports SETTINGS-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.3}{2}}}{
     The expression in an expression statement is evaluated as a void expression
     for its side effects.
     }*/
     rule Computation(_:RValue) => sequencePoint
          [structural]

     rule Initializer(nclv(Loc:SymLoc, T'::Type) := tv(V:CValue, T::UType))
          => init(Loc, V, T')
          requires notBool isRestrictType(T')
               andBool notBool fromArrayStatic(T')
               andBool (T ==Type utype(T'))
          [structural]
     rule Initializer(nclv(Loc:SymLoc, T'::Type) := tv(V:CValue, T::UType))
          => checkArrayStaticAssign(T', V)
          ~> init(Loc, V, T')
          requires notBool isRestrictType(T')
               andBool fromArrayStatic(T')
               andBool (T ==Type utype(T'))
          [structural]
     rule Initializer(nclv(Loc:SymLoc, T'::Type) := tv(V:SymLoc, T::UType))
          => init(Loc, V, T')
          requires isRestrictType(T')
               andBool notBool fromArrayStatic(T')
               andBool (T ==Type utype(T'))
          [structural]
     rule Initializer(nclv(Loc:SymLoc, T'::Type) := tv(V:SymLoc, T::UType))
          => checkArrayStaticAssign(T', V)
          ~> init(Loc, V, T')
          requires isRestrictType(T')
               andBool fromArrayStatic(T')
               andBool (T ==Type utype(T'))
          [structural]

     syntax Bool ::= fromArrayStatic(Type) [function]
     rule fromArrayStatic(t(Qs::Quals, SetItem(K:KItem) S:Set, T::SimpleType))
          => (getKLabel(K) ==K #klabel(`arrayStatic`)) orBool fromArrayStatic(t(Qs, S, T))
     rule fromArrayStatic(_) => false [owise]

     syntax KItem ::= checkArrayStaticAssign(Type, CValue)
                    | "checkArrayStaticAssign'" "(" Type "," Modifier "," Provenance ")"

     rule checkArrayStaticAssign(t(_, Mods:Set, pointerType(T:Type)), loc(_, _, Prov:Set))
          => checkArrayStaticAssign'(T,
               {getFirstMatch(Mods, #klabel(`arrayStatic`))}:>Modifier,
               {getFirstMatch(Prov, #klabel(`fromArray`))}:>Provenance)
     rule (.K => UNDEF("EEA4",
               "Passing a pointer not to an array object as a function parameter with a static-qualified array size."))
          ~> checkArrayStaticAssign(_, Loc:SymLoc)
          requires notBool isFromArray(Loc)

     rule checkArrayStaticAssign'(T:Type,
               arrayStatic(N:Int), fromArray(Offset:Int, Sz:Int))
          => .K
          requires (Sz -Int Offset) >=Int (N *Int byteSizeofType(T))
     rule (.K => UNDEF("EEA5",
               "Passing a pointer to an array object of fewer elements than required by a function parameter with a static-qualified array size."))
          ~> checkArrayStaticAssign'(T:Type,
               arrayStatic(N:Int), fromArray(Offset:Int, Sz:Int))
          requires (Sz -Int Offset) <Int (N *Int byteSizeofType(T))

     syntax KItem ::= getFirstMatch(Set, K) [function]
                    | "getFirstMatch'" "(" K "," Set "," K ")" [function]

     rule getFirstMatch(S:Set, L:K) => getFirstMatch'(.K, S, L)

     rule getFirstMatch'((.K => K), (SetItem(K:KItem) => .Set) _, _)
     rule getFirstMatch'((K:K => .K), _, L:K)
          requires getKLabel(K) =/=K L
               andBool K =/=K .K
     rule getFirstMatch'(K:K, _, L:K) => K
          requires getKLabel(K) ==K L
     rule getFirstMatch'(.K, .Set, _) => .K

     rule Zero(nclv(Loc::SymLoc, T::Type))
          => initBytesFill(Loc, byteSizeofType(T), piece(0, cfg:bitsPerByte))

     rule InitPadding(nclv(Loc::SymLoc, T::StructOrUnionType), F::CId)
          => initPadding(Loc, T, F)

endmodule
