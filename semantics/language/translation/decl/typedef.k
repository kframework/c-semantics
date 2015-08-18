module C-DECL-TYPEDEF
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION

     rule <k> typedef(X:CId, T:Type) => giveType(typedef(X), T) ...</k>
          <elab>... .K => typedef(X, T) </elab>
endmodule
