module C-DECL-TYPEDEF
     imports C-CONFIGURATION
     imports COMMON-SORTS
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> typedef(X:CId, T:Type) => giveType(typedef(X), T) ...</k>
          <elab>... .K => typedef(X, T) </elab>
endmodule
