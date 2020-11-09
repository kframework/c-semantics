module COMMON-INIT-SYNTAX
     imports BASIC-K
     imports STRING
     imports SET

     syntax KItem ::= loadObj(K)
     // this takes input from a file which is not split by thread, so we don't want to split this rule.
     syntax KItem ::= unwrapObj(GeneratedTopCell) [function, noThread, symbol]
     syntax KItem ::= objsWrapper(K) [symbol]

     syntax CId ::= "mainArguments"

     syntax KItem ::= removeUnusedIdentifiers(tu: String)

     syntax String ::= getEntryPoint(Set) [function]
endmodule

module COMMON-INIT
     imports COMMON-INIT-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports K-EQUAL
     imports K-REFLECTION
     imports OPTIONS-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     rule getEntryPoint(Cfg:Set) => #getEntryPoint(Cfg, #getenv("KCC_ENTRY_FUNCTION"))

     syntax String ::= #getEntryPoint(Set, K) [function]
     rule #getEntryPoint(_, EP:String) => EP
     rule #getEntryPoint(_ SetItem(EntryPoint(EP::String)), .K) => EP
     rule #getEntryPoint(_, _) => "main" [owise]

     rule <k> loadObj(G:GlobalCell) => .K ...</k>
          (<global> _ </global> => G)
          requires (G =/=K .K)
          [structural]

     rule loadObj(.K) => .K
          [structural]

     rule unwrapObj(<generatedTop>...
               <global> G::Bag </global>
          ...</generatedTop>)
          => <global> G </global>

     rule <k> removeUnusedIdentifiers(Tu::String) => removeFromExternalDecls(Set2List(keys(Env) -Set Uses), Tu) ...</k>
          <tu-id> Tu </tu-id>
          <genv> Env:Map => removeAll(Env, (keys(Env) -Set Uses)) </genv>
          <gtypes> Types:Map => removeAll(Types, (keys(Types) -Set Uses)) </gtypes>
          (<tu-linking-state>...
               <uses> Uses:Set </uses>
          ...</tu-linking-state> => .Bag)

     syntax KItem ::= removeFromExternalDecls(List, tu: String)
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _, Tu::String) ...</k>
          <tu-id> Tu </tu-id>
          <external-decls>... X |-> (SetItem(Tu) S::Set => S) ...</external-decls>
          requires S =/=K .Set
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _, Tu::String) ...</k>
          <tu-id> Tu </tu-id>
          <external-decls>... X |-> SetItem(Tu) => .Map ...</external-decls>
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _, Tu::String) ...</k>
          <tu-id> Tu </tu-id>
          <external-decls> Decls:Map </external-decls>
          requires notBool (X in_keys(Decls))
     rule removeFromExternalDecls(.List, _) => .K

     rule <k> reportSuccess => .K ...</k>
          <result-value> _ => 0 </result-value>

endmodule
