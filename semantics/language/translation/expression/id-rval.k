module C-EXPRESSION-ID-RVAL
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-COMMON-EXPRESSION-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECLARATION-SYNTAX

     rule <k> instantiateIdVal(_, T:Type) => tv(symVal, T) ...</k>
          <currentFunction> F:Id </currentFunction>
          when F =/=K file-scope
          
endmodule
