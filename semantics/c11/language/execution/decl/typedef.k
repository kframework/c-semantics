module C-DECL-TYPEDEF
     imports COMMON-SORTS
     imports C-ENV-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule typedef(X:CId, T:Type) => giveType(typedef(X), T)
          [structural]
endmodule
