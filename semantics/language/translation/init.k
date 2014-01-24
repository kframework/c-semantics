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
               => klistToK(P) ~> resolveReferences ~> initBuiltins 
          </k>
          <control>...
               <currentFunction> 
                    _ => file-scope
               </currentFunction>
               <currentProgramLoc>
                    _ => UnknownCabsLoc
               </currentProgramLoc>
          ...</control>
          [structural, large]

     // TODO(chathhorn): prevent duplicate TUs or TU name clashes.
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(Tu:String, Strings:K, K:K) 
               => preDeclareStrings(Strings)
               ~> klistToK(eraseKLabel('StmtCons, K))
               ~> allocateIncompleteInternals
          ...</k>
          <currTU> _ => Tu </currTU>
          <translation-units>...
               (. => <tu>...
                    <tu-id> Tu </tu-id>
                    <next-link-loc> firstLoc(link(Tu)) </next-link-loc>
                    <next-static-loc> firstLoc(static(Tu)) </next-static-loc>
               ...</tu>)
          ...</translation-units>
          [structural, large]
          
     syntax K ::= preDeclareStrings(K)
     
     rule preDeclareStrings(klist((K:K,, L:KList)))
          => K ~> discard ~> preDeclareStrings(klist(L))
          [structural]
     rule preDeclareStrings(klist(.KList)) => .
          [structural]
     
     syntax SemMode ::= "InterpMode" | "DebugMode"
     rule <T>... <mode> InterpMode </mode> <k> .K </k> ...</T> => .Bag
          [structural]
          
     syntax K ::= "initBuiltins"
     syntax K ::= initBuiltins(Map)

     rule <k> initBuiltins => initBuiltins(T) ...</k>
          <types> T:Map </types>
          [structural]

     // TODO(chathhorn): this is mostly duped from execution.k
     rule [lookup-builtin-id-notfound]:
          <k> (. => addToEnv(X, Loc)
                    ~> initFunction(
                         tv(Loc, t(.Set, pointerType(T))), 
                         functionPrototype(X, T))) 
               ~> X:Id
          ...</k>
          <env> Env:Map </env>
          <types>... X |-> T:Type ...</types>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when isFunctionType(T)
               andBool notBool X in keys Env
          [large, structural]

     rule [lookup-builtin-function-notfound]:
          <k> (. => addToEnv(X, Loc)
                    ~> initFunction(
                         tv(Loc, t(.Set, pointerType(T))),
                         functionPrototype(X, T)))
               ~> initBuiltins((X:Id |-> T:Type => .) _:Map)
          ...</k>
          <env> Env:Map </env>
          // TODO(chathhorn): need to get correct TU!
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when isFunctionType(T)
               andBool notBool X in keys Env
          [large, structural]

     rule [lookup-builtin-function-found]:
          <k> initBuiltins(X:Id |-> T:Type M:Map => M) ...</k>
          <env> Env:Map </env>
          when (notBool isFunctionType(T))
               orBool (X in keys Env)
          [structural]

     rule initBuiltins(.Map) => .
          [structural]

endmodule
