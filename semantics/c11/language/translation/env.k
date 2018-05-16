module C-ENV-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX

     imports SYMLOC-SORTS
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS


     syntax KItem ::= addToEnv(CId, Type, SymBase)
     syntax KItem ::= giveType(CId, Type)
     syntax KItem ::= addEnum(CId, Int)
     syntax KItem ::= "populateFromGlobal"
     syntax KItem ::= scope(Scope, K)
     syntax KItem ::= noEval(K)
     syntax KItem ::= "skipToScopeExit"
     syntax KItem ::= "popLocals"
endmodule

module C-ENV
     imports C-ENV-SYNTAX
     imports C-CONFIGURATION
     imports STRING
     imports COMMON-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> populateFromGlobal => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv>
          <rgenv> RG:Map </rgenv>
          <gtypes> GT:Map </gtypes>
          <genums> GE:Map </genums>
          <env> _ => G </env>
          <renv> _ => RG </renv>
          <types> _ => GT </types>
          <enums> _ => GE </enums>

     rule <k> addToEnv(X:CId, T::Type, Base:SymBase) => addToGlobalEnv(X, T, Base) ...</k>
          <curr-scope> fileScope </curr-scope>
     rule <k> addToEnv(X:CId, _, Base:SymBase) => addToLocalEnv(X, Base) ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope

     syntax KItem ::= addToGlobalEnv(K, Type, SymBase)
     rule <k> addToGlobalEnv(X:CId, T::Type, Base:SymBase) => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> G:Map => G[X <- Base] </genv>
          <rgenv> RG:Map => #if isFunctionType(T) #then RG #else RG[Base <- X] #fi </rgenv>
          <env> E:Map => E[X <- Base] </env>
          <renv> RE:Map => #if isFunctionType(T) #then RE #else RE[Base <- X] #fi </renv>

     syntax KItem ::= addToLocalEnv(K, SymBase)
     rule <k> addToLocalEnv(X:CId, Base:SymBase) => .K ...</k>
          <env> E:Map => E[X <- Base] </env>
          <renv> RE:Map => RE[Base <- X] </renv>

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
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <has-restrict>... .Set => SetItem(fileScope) </has-restrict>
          requires hasRestrict(T)
     rule <k> giveType(X:CId, T:Type)
               => giveGlobalType(X, stripStorageSpecifiers(T))
          ...</k>
          <curr-scope> fileScope </curr-scope>
          requires notBool hasRestrict(T)
     rule <k> giveType(X:CId, T:Type)
               => giveLocalType(X, tagRestrict(S, stripStorageSpecifiers(T)))
          ...</k>
          <curr-scope> S::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <has-restrict>... .Set => SetItem(S) </has-restrict>
          requires S =/=K fileScope andBool hasRestrict(T)
     rule <k> giveType(X:CId, T:Type)
               => giveLocalType(X, stripStorageSpecifiers(T))
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires S =/=K fileScope andBool notBool hasRestrict(T)

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
     rule <k> noEval(K:K)
              => pushLocals ~> K ~> popLocals ~> setEval(OldEval)
          ...</k>
          <curr-eval-context> OldEval:EvalContext => noEval </curr-eval-context>

     syntax KItem ::= setScope(Scope)
     rule <k> setScope(Scope:Scope) => .K ...</k>
          <curr-scope> _ => Scope </curr-scope>
     syntax KItem ::= setEval(EvalContext)
     rule <k> setEval(Eval:EvalContext) => .K ...</k>
          <curr-eval-context> _ => Eval </curr-eval-context>

     syntax KItem ::= "pushLocals"
     rule <k> pushLocals => .K ...</k>
          <block-control> C::Bag <local-types> LocalTypes:Map => .Map </local-types> </block-control>
          <block-stack>
               .List => ListItem(<block-control> C <local-types> LocalTypes </local-types> </block-control>)
          ...</block-stack>

     rule <k> popLocals => .K ...</k>
          (_:BlockControlCell => L)
          <block-stack>
               ListItem(L:BlockControlCell) => .List
          ...</block-stack>

     rule skipToScopeExit ~> (K:KItem => .K)
          requires K =/=K popLocals
     rule (skipToScopeExit => .K) ~> popLocals

     rule <k> (.K => SE("CID1",
               "Trying to look up identifier " +String S +String
               ", but no such identifier is in scope.") )
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
               "No definition found for identifier " +String S +String ".") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <enums> Enums:Map </enums>
          <types>... Identifier(S) |-> _ ...</types>
          requires (notBool (Identifier(S) in_keys(Env)))
               andBool (notBool (Identifier(S) in_keys(Enums)))
          [structural]

endmodule
