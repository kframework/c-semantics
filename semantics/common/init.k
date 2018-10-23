module COMMON-INIT-SYNTAX
     imports BASIC-K
     imports STRING

     syntax KItem ::= loadObj(K)
     // this takes input from a file which is not split by thread, so we don't want to split this rule.
     syntax K ::= unwrapObj(K) [function, noThread]

     syntax CId ::= "mainArguments"

     syntax KItem ::= removeUnusedIdentifiers(tu: String)
endmodule

module COMMON-INIT
     imports COMMON-INIT-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports K-EQUAL
     imports OPTIONS-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

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

     rule unwrapObj(.K) => .K

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
