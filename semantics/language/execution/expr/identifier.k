module C-EXPR-IDENTIFIER
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-MEMORY-READING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          when notBool isRestrictType(T)
          [structural]
     rule <k> X:CId => lv(restrictedNew(Base, getRestrictBlock(T)), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          when isRestrictType(T)
          [structural]

     rule instantiate(Loc:SymLoc, T:Type)
          => transferProv(getBases(Loc), read(Loc, T))
          when isRestrictType(T)
          [structural]
     rule instantiate(Loc:SymLoc, T:Type) => read(Loc, T)
          when notBool isRestrictType(T)
          [structural]
endmodule

