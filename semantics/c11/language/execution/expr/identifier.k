module C-EXPR-IDENTIFIER
     imports C-CONFIGURATION
     imports STRING
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule <k> X:CId => lv(lnew(Base, T), T) ...</k>
          <env>... X |-> Base::SymBase ...</env>
          <types>... X |-> T::Type ...</types>
          requires notBool isRestrictType(T)
          [structural]
     rule <k> X:CId => lv(restrictedNew(Base, T, getRestrictBlock(T)), T) ...</k>
          <env>... X |-> Base::SymBase ...</env>
          <types>... X |-> T::Type ...</types>
          requires isRestrictType(T)
          [structural]

     rule instantiate(Loc::SymLoc, T::Type)
          => transferProv(getBases(Loc), read(Loc, T))
          requires isRestrictType(T)
          [structural]
     rule instantiate(Loc::SymLoc, T::Type) => read(Loc, T)
          requires notBool isRestrictType(T)
          [structural]

     rule <k> (.K => SE("CID1",
               "Trying to look up identifier " +String S +String
               ", but no such identifier is in scope.",
               "6.5.1:2") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          requires (notBool (Identifier(S) in_keys(Env)))
               andBool (notBool (Identifier(S) in_keys(Types)))
          [structural]
     rule <k> (.K => UNDEF("CID2",
               "No definition found for identifier " +String S +String ".", "6.3.2.1:1, J.2:1 item 19") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> _ ...</types>
          requires (notBool (Identifier(S) in_keys(Env)))
          [structural]

endmodule

