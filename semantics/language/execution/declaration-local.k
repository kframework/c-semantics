module C-DECLARATION-LOCAL
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     rule <k> 
               declareOnly(X:Id, T:Type, noLinkage)
               => allocateType(Loc, T) ~> addToEnv(X, Loc) ~> giveType(X, T)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          when (notBool isIncompleteType(T))
               andBool (notBool isStaticType(T))
               andBool (notBool isExternType(T))
               // this should be here statically, but not dynamically
               andBool (notBool X in Vars)
          [structural]

     rule <k> 
               declareAndDefine(X:Id, T:Type, K:K, noLinkage)
               => defineAndInit(X, T, figureInit(X, T, K), Loc)
          ...</k>
          <nextLoc> Loc:SymLoc => linc(Loc) </nextLoc>
          <localVariables> Vars:List (. => ListItem(X)) </localVariables>
          <localAddresses>... .Set => SetItem(Loc) ...</localAddresses>
          // again, this should be needed statically, but not dynamically
          when notBool X in Vars
          [structural] 

endmodule

