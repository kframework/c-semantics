module C-EXPR-MEMBERS
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule tv(symVal, _:Type) . _:Id => symVal
          [structural]

endmodule
          
