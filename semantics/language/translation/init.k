module C-TRANSLATION-INIT
     imports C-DECLARATION-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-RESOLUTION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> Program(klist(P:KList)) 
          => klistToK(P) ~> resolveReferences ~> initBuiltins </k>
          <threadLocal>...
               <control>...
                    <currentFunction> 
                         _ => file-scope
                    </currentFunction>
                    <currentProgramLoc>
                         _ => UnknownCabsLoc
                    </currentProgramLoc>
               ...</control>
          ...</threadLocal>
          <nextSharedLoc> _ => firstLoc(0) </nextSharedLoc>
          [structural, large]

     syntax SemMode ::= "InterpMode" | "DebugMode"
     rule <T>... <mode> InterpMode </mode> <k> .K </k> ...</T> => .Bag
          
     // TODO(chathhorn): It'd be nice to remove sequence points altogether from
     // this part of the semantics.
     rule [sequencePoint]:
          sequencePoint => .
          [structural]

     syntax K ::= "initBuiltins"
     syntax K ::= initBuiltins(Map)

     rule <k> initBuiltins => initBuiltins(T) ...</k>
          <types> T:Map </types>

     // TODO(chathhorn): this is mostly duped from execution.k
     rule [lookup-builtin-id-notfound]:
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
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          when isFunctionType(T)
               andBool notBool X in keys Env
          [large, structural]

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
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
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
