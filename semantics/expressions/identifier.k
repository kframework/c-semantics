module C-EXPRESSION-IDENTIFIER
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule [lookup]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</env>
          <types>... X:Id |-> T:Type ...</types>
          [structural]
          
     rule [lookup-builtin-function-notfound]:
          <k> (.K 
                    => addToEnv(X:Id, Loc)
                    ~> initFunction(
                         tv(Loc, t(.Set, pointerType(T:KResult))),
                         functionPrototype(X:Id, T:KResult)
                    )
               )
               ~> X:Id
          ...</k>
          <br/>
          <env> Env:Map </env>
          <types>... X:Id |-> T:KResult ...</types>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          when isFunctionType(T:KResult)
          andBool notBool X:Id in keys Env:Map
          [large, structural]
endmodule

