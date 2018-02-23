module C-STMT-EXPR
     imports C-CONFIGURATION
     imports C-ABSTRACT-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     rule Computation(.K) => .K
     rule <k> Computation(V:RValue) => .K ...</k>
          <elab>... .K => Computation(V) </elab>
          requires isHold(V)
     // Totally elide pure expressions from the translated program.
     rule Computation(V:RValue) => .K
          requires notBool isHold(V)

     rule (.K => CV("TSE1", "Incompatible types in initializer or function call arguments."))
          ~> Initializer(L:Nclv := R:RValue)
          requires utype(L) =/=Type utype(R)
               andBool notBool isAutoType(type(L))
               andBool (
                    (isPointerType(type(L)) andBool notBool isPointerType(type(R))
                         andBool notBool isNullPointerConstant(R))
                    orBool (isArithmeticType(type(L)) andBool notBool isBoolType(type(L))
                         andBool notBool isArithmeticType(type(R)))
                    orBool (isStructOrUnionType(type(L))
                         andBool type(L) =/=Type type(R))
                    orBool (isBoolType(type(L)) andBool notBool isPointerType(type(R))
                         andBool notBool isArithmeticType(type(R)))
                    orBool notBool (isPointerType(type(L))
                         orBool isArithmeticType(type(L))
                         orBool isStructOrUnionType(type(L))
                         orBool isBoolType(type(L)))
               ) andBool R =/=K voidVal

     rule (.K => CV("TSE2", "Incompatible pointer types in initializer or function call arguments."))
          ~> Initializer(L:Nclv := R:RValue)
          requires (isPointerType(type(L)) andBool isPointerType(type(R)))
               andBool notBool isNullPointerConstant(R)
               andBool utype(L) =/=Type utype(R)
               andBool notBool isAutoType(type(L))
               andBool notBool (
                    (stripQualifiers(innerType(type(L))) =/=Type stripQualifiers(innerType(type(R)))
                              impliesBool (isVoidType(innerType(type(L))) orBool isVoidType(innerType(type(R)))))
                    andBool (getQualifiers(innerType(type(R)))
                         <=Quals getQualifiers(innerType(type(L))))
               )

     rule Initializer(nclv(Loc:SymLoc, T::Type) := tv(V:CValue, T'::UType))
          => init(Loc, V, T)
          requires notBool isLinkerLoc(Loc)
               andBool (utype(T) ==Type T')
     rule <k> Initializer(nclv(Loc:SymLoc, T::Type) := tv(V:CValue, T'::UType)) => .K ...</k>
          <elab>... .K => Initializer(lv(Loc, T) := checkUse(tv(V, T'))) </elab>
          requires isLinkerLoc(Loc)
               andBool (utype(T) ==Type T')
     rule <k> Initializer(ncle(L:K, T::Type) := R:RValue) => .K ...</k>
          <elab>... .K => Initializer(L := stripHold(R)) </elab>
          requires utype(T) ==Type utype(R)

     rule (.K => CV("TSE3", "Non-constant static initializer."))
          ~> Initializer(nclv(_, _) := te(_, _))

     rule Initializer(ncle(_, (t(_, _, auto-type) => type(V))) := V:RValue)

endmodule
