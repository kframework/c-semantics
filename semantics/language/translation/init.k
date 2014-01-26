module C-TRANSLATION-INIT
     imports C-DECLARATION-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-RESOLUTION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BUILTINS-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): check that main is defined.
     rule <k> Program(klist(P:KList)) 
               => klistToK(P) ~> resolveReferences
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
               ~> initBuiltins
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

     // TODO(chathhorn): this is mostly duped from execution.k
     // rule [lookup-builtin-id-notfound]:
     //      <k> (. => addToEnv(X, Loc)
     //                ~> initFunction(
     //                     tv(Loc, t(.Set, pointerType(T))), 
     //                     functionPrototype(X, T))) 
     //           ~> X:Id
     //      ...</k>
     //      <env> Env:Map </env>
     //      <types>... X |-> T:Type ...</types>
     //      <currTU> Tu:String </currTU>
     //      <tu-id> Tu </tu-id>
     //      <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
     //      when isFunctionType(T)
     //           andBool notBool X in keys Env
     //      [large, structural]

     rule <k> initBuiltins => initBuiltins(Env) ...</k>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <genv> Env:Map </genv>
          [structural]

     rule [lookup-builtin-function-notfound]:
          <k> (. => addToEnv(X, Loc')
                    ~> initFunction(
                         tv(Loc', t(.Set, pointerType(T))),
                         functionPrototype(X, T)))
               ~> initBuiltins((X:Id |-> Loc:SymLoc => .) _:Map)
          ...</k>
          // TODO(chathhorn): it'd be nice to use a correct TU.
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <gtypes>... X |-> T:Type ...</gtypes>
          <next-static-loc> Loc':SymLoc => linc(Loc') </next-static-loc>
          when isLinkerLoc(Loc) 
               andBool (idToString(X) in builtins)
          [large, structural]

     rule [lookup-builtin-function-found]:
          <k> initBuiltins(X:Id |-> Loc:SymLoc M:Map => M) ...</k>
          when notBool isLinkerLoc(Loc)
               orBool (notBool idToString(X) in builtins)
          [structural]

     rule initBuiltins(.Map) => .
          [structural]

endmodule
