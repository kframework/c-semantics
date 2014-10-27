module C-EXPR-INC-AND-DEC
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(_:SymLoc, T:Type) ++ => tv(symVal, stripQualifiers(T))
          [structural]

     rule nclv(_:SymLoc, T:Type) -- => tv(symVal, stripQualifiers(T))
          [structural]

     rule ++ nclv(_:SymLoc, T:Type) => tv(symVal, stripQualifiers(T))
          [structural]

     rule -- nclv(_:SymLoc, T:Type) => tv(symVal, stripQualifiers(T))
          [structural]

endmodule
