module C-BUILTIN-SYNTAX
     syntax K ::= handleBuiltin(Id, Type)
endmodule

module C-BUILTIN
     imports C-BUILTIN-SYNTAX

     imports C-EXPR-FUNCTION-CALL-SYNTAX
     imports C-DECL-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     
     rule [builtin-application]:
          application'(Tu:String, functionPrototype(X:Id, T:Type), L:KList)
          => application'(Tu, functionObject(X, T, handleBuiltin(X, T)), L)
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
