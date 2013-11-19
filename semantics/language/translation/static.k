module C-STATIC-SYNTAX
     syntax K ::= "initBuiltins"
endmodule

module C-STATIC
     imports C-STATIC-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule Computation(_:KResult) => sequencePoint
     rule Nop => .

     syntax K ::= initBuiltins(Map)

     rule <k> initBuiltins => initBuiltins(T) ...</k>
          <types> T:Map </types>

     // TODO(chathhorn): already in dynamic. Can this be removed?
     // rule [lookup-builtin-id-notfound]:
     //      <k> (.K 
     //                => addToEnv(X, Loc)
     //                     ~> initFunction(
     //                          tv(Loc, t(.Set, pointerType(T))),
     //                          functionPrototype(X, T)
     //                     )
     //           )
     //           ~> X:Id
     //      ...</k>
     //      <env> Env:Map </env>
     //      <types>... X |-> T:Type ...</types>
     //      <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
     //      when isFunctionType(T)
     //           andBool notBool X in keys Env
     //      [large, structural]

     rule [lookup-builtin-function-notfound]:
          <k> (.K 
                    => addToEnv(X, Loc)
                         ~> initFunction(
                              tv(Loc, t(.Set, pointerType(T))),
                              functionPrototype(X, T)
                         )
               )
               ~> initBuiltins(X:Id |-> T:Type M:Map => M)
          ...</k>
          <env> Env:Map </env>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          when isFunctionType(T)
               andBool notBool X in keys Env
          [large, structural]

     rule [lookup-builtin-function-found]:
          <k> initBuiltins(X:Id |-> T:Type M:Map => M) ...</k>
          <env> Env:Map </env>
          when (notBool isFunctionType(T))
               orBool (X in keys Env)

     rule initBuiltins(.Map) => .

endmodule
