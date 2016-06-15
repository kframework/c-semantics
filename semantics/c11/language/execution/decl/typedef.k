module C-DECL-TYPEDEF
     imports C-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX

     rule typedef(X:CId, T:Type) => giveType(typedef(X), T)
          [structural]
endmodule
