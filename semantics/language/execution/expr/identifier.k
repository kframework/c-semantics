module C-EXPR-IDENTIFIER
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-CONFIGURATION
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule <k> X:CId => lv(lnew(Base, getAlignas(T)), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          requires notBool isRestrictType(T)
          [structural]
     rule <k> X:CId => lv(restrictedNew(Base, getAlignas(T), getRestrictBlock(T)), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          requires isRestrictType(T)
          [structural]

     rule instantiate(Loc:SymLoc, T:Type)
          => transferProv(getBases(Loc), read(Loc, T))
          requires isRestrictType(T)
          [structural]
     rule instantiate(Loc:SymLoc, T:Type) => read(Loc, T)
          requires notBool isRestrictType(T)
          [structural]
endmodule

