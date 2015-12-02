module C-ENV-SYNTAX
     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= addToEnv(CId, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= addEnum(CId, Int)
     syntax KItem ::= "populateFromGlobal"
     syntax KItem ::= scope(Scope, K)
     syntax KItem ::= "recover"
endmodule

module C-ENV
     imports C-BITSIZE-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> populateFromGlobal => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <gtypes> GT:Map </gtypes>
          <genums> GE:Map </genums>
          <env> _ => G </env>
          <types> _ => GT </types>
          <enums> _ => GE </enums>

     rule <k> addToEnv(X:CId, Base:SymBase) => addToGlobalEnv(X, Base) ...</k>
          <curr-scope> fileScope </curr-scope>
     rule <k> addToEnv(X:CId, Base:SymBase) => addToLocalEnv(X, Base) ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope

     syntax KItem ::= addToGlobalEnv(K, SymBase)
     rule <k> addToGlobalEnv(X:CId, Base:SymBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map => G[X <- Base] </genv>
          <env> E:Map => E[X <- Base] </env>

     syntax KItem ::= addToLocalEnv(K, SymBase)
     rule <k> addToLocalEnv(X:CId, Base:SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>

     rule <k> addEnum(X:CId, Value:Int) => addGlobalEnum(X, Value) ...</k>
          <curr-scope> fileScope </curr-scope>
     rule <k> addEnum(X:CId, Value:Int) => addLocalEnum(X, Value) ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope

     syntax KItem ::= addGlobalEnum(K, Int)
     rule <k> addGlobalEnum(X:CId, Value:Int) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genums> G:Map => G[X <- Value] </genums>
          <enums> E:Map => E[X <- Value] </enums>

     syntax KItem ::= addLocalEnum(K, Int)
     rule <k> addLocalEnum(X:CId, Value:Int) => .K ...</k>
          <enums> E:Map => E[X <- Value] </enums>

     rule <k> giveType(X:CId, T:Type)
               => giveGlobalType(X, tagRestrict(fileScope, stripStorageSpecifiers(T)))
          ...</k>
          <curr-scope> fileScope </curr-scope>
     rule <k> giveType(X:CId, T:Type)
               => giveLocalType(X, tagRestrict(S, stripStorageSpecifiers(T)))
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope

     syntax KItem ::= giveGlobalType(K, Type)
     rule <k> giveGlobalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- T] </types>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <gtypes> G:Map => G[X <- T] </gtypes>

     syntax KItem ::= giveLocalType(K, Type)
     rule <k> giveLocalType(X:CId, T:Type) => .K ...</k>
          <types> L:Map => L[X <- T] </types>

     rule <k> scope(Scope:Scope, K:K)
              => pushLocals ~> K ~> popLocals ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope:Scope => Scope </curr-scope>

     syntax KItem ::= setScope(Scope)
     rule <k> setScope(Scope:Scope) => .K ...</k>
          <curr-scope> _ => Scope </curr-scope>

     syntax KItem ::= "pushLocals" | "popLocals"
     rule <k> pushLocals => .K ...</k>
          <local> C:Bag <local-types> LocalTypes:Map => .Map </local-types> </local>
          <block-stack>
               .List => ListItem(<local> C <local-types> LocalTypes </local-types> </local>)
          ...</block-stack>

     rule <k> popLocals => .K ...</k>
          (_:LocalCell => L)
          <block-stack>
               ListItem(L:LocalCell) => .List
          ...</block-stack>

     rule recover ~> (K:KItem => .K)
          requires K =/=K popLocals
     rule (recover => .K) ~> popLocals

     rule <k> (.K => CV("CID1",
               "Trying to look up identifier " +String S +String
               ", but no such identifier is in scope.",
               "6.5.1:2") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          <enums> Enums:Map </enums>
          requires (notBool (Identifier(S) in_keys(Env)))
               andBool (notBool (Identifier(S) in_keys(Types)))
               andBool (notBool (Identifier(S) in_keys(Enums)))
          [structural]
     rule <k> (.K => UNDEF("CID2",
               "No definition found for identifier " +String S +String ".", "6.3.2.1:1, J.2:1 item 19") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <enums> Enums:Map </enums>
          <types>... Identifier(S) |-> _ ...</types>
          requires (notBool (Identifier(S) in_keys(Env)))
               andBool (notBool (Identifier(S) in_keys(Enums)))
          [structural]

endmodule
