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
     rule <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          [structural]

     rule instantiate(L:SymLoc, T:Type) => read(L, T)
          [structural]
endmodule

