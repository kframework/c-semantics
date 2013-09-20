module C-EXPRESSION-IDENTIFIER
     imports C-EXPRESSION-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule [lookup]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          [structural]
          
     rule [lookup-builtin-function-notfound]:
          <k> (.K 
                    => addToEnv(X, Loc)
                         ~> initFunction(
                              tv(Loc, t(.Set, pointerType(T))),
                              functionPrototype(X, T)
                         )
               )
               ~> X:Id
          ...</k>
          <env> Env:Map </env>
          <types>... X |-> T:Type ...</types>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          when isFunctionType(T)
               andBool notBool X in keys Env
          [large, structural]
endmodule

